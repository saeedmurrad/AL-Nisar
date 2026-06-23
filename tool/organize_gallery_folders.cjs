#!/usr/bin/env node
/**
 * Assign gallery_images folder field in Firestore.
 *
 * Usage:
 *   node tool/organize_gallery_folders.cjs [--dry-run] [--key path/to/key.json]
 *
 * Rules:
 *   - irshad_*  -> irshadat (Irshad Pak album in Gallery)
 *   - others    -> general (move via Admin → Gallery → folder icon)
 */

const fs = require('node:fs');
const path = require('node:path');
const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const DEFAULT_KEY = path.join(
  __dirname,
  '../al-nisar-app-firebase-adminsdk-fbsvc-b42e71516e.json',
);

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const keyIdx = args.indexOf('--key');
const keyPath = keyIdx >= 0 ? args[keyIdx + 1] : DEFAULT_KEY;

function folderForId(id) {
  if (id.startsWith('irshad_')) return 'irshadat';
  return 'general';
}

function initAdmin() {
  if (!fs.existsSync(keyPath)) {
    throw new Error(`Service account key not found: ${keyPath}`);
  }
  if (!getApps().length) {
    const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
    initializeApp({
      credential: cert(serviceAccount),
      projectId: 'al-nisar-app',
    });
  }
  return getFirestore();
}

async function main() {
  const db = initAdmin();
  const snap = await db.collection('gallery_images').get();
  let updated = 0;
  let skipped = 0;

  for (const doc of snap.docs) {
    const current = (doc.data().folder || '').trim();
    const next = folderForId(doc.id);
    if (current === next) {
      skipped++;
      continue;
    }
    if (dryRun) {
      console.log(`[dry-run] ${doc.id}: ${current || '(none)'} -> ${next}`);
    } else {
      await doc.ref.set({ folder: next }, { merge: true });
    }
    updated++;
  }

  console.log(
    `Done. updated=${updated}, skipped=${skipped}, total=${snap.size}${dryRun ? ' (dry-run)' : ''}`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
