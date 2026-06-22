#!/usr/bin/env node
/**
 * Import parsed Facebook Irshadat into Firestore + Storage using a service account.
 *
 * Usage:
 *   node tool/import_irshadat_to_firebase.cjs [parsed.json] [--limit N] [--dry-run]
 */

const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');

const PROJECT_ID = 'al-nisar-app';
const STORAGE_BUCKET = 'al-nisar-app.firebasestorage.app';
const DEFAULT_KEY = path.join(
  __dirname,
  '../al-nisar-app-firebase-adminsdk-fbsvc-b42e71516e.json',
);

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const limitIdx = args.indexOf('--limit');
const limit = limitIdx >= 0 ? Number(args[limitIdx + 1]) : null;
const keyIdx = args.indexOf('--key');
const keyPath = keyIdx >= 0 ? args[keyIdx + 1] : DEFAULT_KEY;
const jsonPath =
  args.find((a) => a.endsWith('.json') && a !== keyPath) ??
  path.join(__dirname, '_fb_export/irshadat_parsed.json');
const zipPath = path.join(
  __dirname,
  '../assets/facebook-SaeedMurrad-2026-06-22-7Oz8IpKd.zip',
);

function docIdFor(urdu) {
  return crypto.createHash('sha1').update(urdu).digest('hex').slice(0, 20);
}

function readImageFromZip(relPath) {
  if (!relPath || !fs.existsSync(zipPath)) return null;
  const proc = spawnSync('unzip', ['-p', zipPath, relPath], {
    encoding: 'buffer',
    maxBuffer: 20 * 1024 * 1024,
  });
  if (proc.status !== 0 || !proc.stdout?.length) return null;
  return proc.stdout;
}

function initAdmin() {
  if (!fs.existsSync(keyPath)) {
    throw new Error(`Service account key not found: ${keyPath}`);
  }
  if (!getApps().length) {
    const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
    initializeApp({
      credential: cert(serviceAccount),
      projectId: PROJECT_ID,
      storageBucket: STORAGE_BUCKET,
    });
  }
  return {
    db: getFirestore(),
    bucket: getStorage().bucket(),
  };
}

async function uploadImage(bucket, docId, relPath) {
  const bytes = readImageFromZip(relPath);
  if (!bytes) return '';

  const ext = path.extname(relPath).toLowerCase().replace('.', '') || 'jpg';
  const contentType =
    ext === 'png' ? 'image/png' : ext === 'webp' ? 'image/webp' : 'image/jpeg';
  const objectPath = `irshadat_images/ur/${docId}.${ext}`;
  const file = bucket.file(objectPath);
  await file.save(bytes, {
    metadata: { contentType },
    resumable: false,
  });
  await file.makePublic().catch(() => {});
  return `https://storage.googleapis.com/${STORAGE_BUCKET}/${objectPath}`;
}

async function upsertDoc(db, collection, docId, data) {
  await db.collection(collection).doc(docId).set(data, { merge: true });
}

async function main() {
  const items = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  const slice = limit && limit > 0 ? items.slice(0, limit) : items;
  console.log(`Importing ${slice.length} Irshadat entries${dryRun ? ' (dry run)' : ''}…`);

  if (dryRun) {
    for (const item of slice.slice(0, 5)) {
      console.log(`- ${item.dateLabel}: ${item.urdu.slice(0, 40)}…`);
    }
    console.log(`… and ${Math.max(0, slice.length - 5)} more`);
    return;
  }

  const { db, bucket } = initAdmin();
  let ok = 0;
  let fail = 0;

  for (let i = 0; i < slice.length; i++) {
    const item = slice[i];
    const id = docIdFor(item.urdu);
    process.stdout.write(`[${i + 1}/${slice.length}] ${item.dateLabel}… `);
    try {
      let imageUrl = '';
      if (item.imageRelPath) {
        imageUrl = await uploadImage(bucket, id, item.imageRelPath);
      }

      const createdAt = Timestamp.fromDate(new Date(item.createdAt));
      const base = {
        dateLabel: item.dateLabel,
        imageUrl,
        createdAt,
        isActive: true,
      };

      await upsertDoc(db, 'irshadat_ur', id, { ...base, text: item.urdu });
      await upsertDoc(db, 'irshadat_en', id, { ...base, text: item.english });
      ok++;
      console.log('ok');
    } catch (e) {
      fail++;
      console.log(`FAILED: ${e.message ?? e}`);
    }
  }

  console.log(`Done. ${ok} ok, ${fail} failed.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
