#!/usr/bin/env node
/**
 * Remove duplicate/stub Irshadat — keeps the 142 Facebook-import canonical entries.
 *
 * Usage:
 *   node tool/dedupe_irshadat.cjs [--dry-run]
 */

const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');

const PROJECT_ID = 'al-nisar-app';
const DEFAULT_KEY = path.join(
  __dirname,
  '../al-nisar-app-firebase-adminsdk-fbsvc-b42e71516e.json',
);
const PARSED_JSON = path.join(__dirname, '_fb_export/irshadat_parsed.json');
const dryRun = process.argv.includes('--dry-run');

function initAdmin() {
  if (!getApps().length) {
    const serviceAccount = JSON.parse(fs.readFileSync(DEFAULT_KEY, 'utf8'));
    initializeApp({
      credential: cert(serviceAccount),
      projectId: PROJECT_ID,
      storageBucket: 'al-nisar-app.firebasestorage.app',
    });
  }
  return { db: getFirestore(), bucket: getStorage().bucket() };
}

function canonicalIds() {
  const parsed = JSON.parse(fs.readFileSync(PARSED_JSON, 'utf8'));
  return new Set(
    parsed.map((p) =>
      crypto.createHash('sha1').update(p.urdu).digest('hex').slice(0, 20),
    ),
  );
}

async function deleteStorageImage(bucket, imageUrl) {
  if (!imageUrl?.trim()) return;
  try {
    const prefix = `https://storage.googleapis.com/${bucket.name}/`;
    const firebasePrefix = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/`;
    let objectPath = '';
    if (imageUrl.startsWith(prefix)) {
      objectPath = decodeURIComponent(imageUrl.slice(prefix.length));
    } else if (imageUrl.includes(firebasePrefix)) {
      const m = imageUrl.match(/\/o\/([^?]+)/);
      if (m) objectPath = decodeURIComponent(m[1]);
    }
    if (objectPath) await bucket.file(objectPath).delete({ ignoreNotFound: true });
  } catch (_) {
    /* best effort */
  }
}

async function main() {
  const keep = canonicalIds();
  const { db, bucket } = initAdmin();

  const [urSnap, enSnap] = await Promise.all([
    db.collection('irshadat_ur').get(),
    db.collection('irshadat_en').get(),
  ]);

  const toDelete = new Map();

  for (const doc of urSnap.docs) {
    if (keep.has(doc.id)) continue;
    toDelete.set(doc.id, {
      id: doc.id,
      dateLabel: doc.data().dateLabel ?? '',
      reason: 'non-canonical ur stub',
    });
  }

  for (const doc of enSnap.docs) {
    if (keep.has(doc.id)) continue;
    if (!toDelete.has(doc.id)) {
      toDelete.set(doc.id, {
        id: doc.id,
        dateLabel: doc.data().dateLabel ?? '',
        reason: 'non-canonical en stub',
      });
    }
  }

  console.log(`Canonical entries to keep: ${keep.size}`);
  console.log(`Current: ur=${urSnap.size}, en=${enSnap.size}`);
  console.log(`To delete: ${toDelete.size} stub/duplicate id(s)`);

  for (const item of [...toDelete.values()].slice(0, 20)) {
    console.log(`  - ${item.id} (${item.dateLabel}) ${item.reason}`);
  }
  if (toDelete.size > 20) console.log(`  … and ${toDelete.size - 20} more`);

  if (dryRun) {
    console.log('\nDry run — no changes made.');
    return;
  }

  let deleted = 0;
  for (const id of toDelete.keys()) {
    const [urDoc, enDoc] = await Promise.all([
      db.collection('irshadat_ur').doc(id).get(),
      db.collection('irshadat_en').doc(id).get(),
    ]);
    const imageUrl = urDoc.data()?.imageUrl || enDoc.data()?.imageUrl || '';
    await deleteStorageImage(bucket, imageUrl);
    if (urDoc.exists) await db.collection('irshadat_ur').doc(id).delete();
    if (enDoc.exists) await db.collection('irshadat_en').doc(id).delete();
    deleted++;
  }

  const [urCount, enCount] = await Promise.all([
    db.collection('irshadat_ur').where('isActive', '==', true).count().get(),
    db.collection('irshadat_en').where('isActive', '==', true).count().get(),
  ]);

  console.log(`\nDone. Removed ${deleted} stub/duplicate id(s).`);
  console.log(
    `Remaining active: irshadat_ur=${urCount.data().count}, irshadat_en=${enCount.data().count}`,
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
