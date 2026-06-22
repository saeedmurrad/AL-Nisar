#!/usr/bin/env node
/**
 * Copy Irshadat images (Firebase Storage) into gallery_images + Firestore.
 *
 * Usage:
 *   node tool/copy_irshadat_images_to_gallery.cjs [--dry-run] [--key path/to/key.json]
 *
 * Idempotent: gallery doc ids are `irshad_<irshadDocId>` — safe to re-run.
 */

const fs = require('node:fs');
const path = require('node:path');
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
const keyIdx = args.indexOf('--key');
const keyPath = keyIdx >= 0 ? args[keyIdx + 1] : DEFAULT_KEY;

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

function storagePathFromUrl(imageUrl) {
  const url = (imageUrl || '').trim();
  if (!url) return '';
  try {
    const u = new URL(url);
    const marker = '/o/';
    const idx = u.pathname.indexOf(marker);
    if (idx >= 0) {
      const encoded = u.pathname.slice(idx + marker.length);
      return decodeURIComponent(encoded.split('?')[0]);
    }
    const prefix = `/${STORAGE_BUCKET}/`;
    if (u.pathname.startsWith(prefix)) {
      return u.pathname.slice(prefix.length);
    }
    const gcs = 'storage.googleapis.com';
    if (u.hostname === gcs && u.pathname.startsWith(`/${STORAGE_BUCKET}/`)) {
      return u.pathname.slice(`/${STORAGE_BUCKET}/`.length);
    }
  } catch (_) {
    // fall through
  }
  return '';
}

function extFromPath(storagePath) {
  const ext = path.extname(storagePath).toLowerCase().replace('.', '');
  if (ext === 'png' || ext === 'webp' || ext === 'jpeg') return ext === 'jpeg' ? 'jpg' : ext;
  return 'jpg';
}

function contentTypeForExt(ext) {
  if (ext === 'png') return 'image/png';
  if (ext === 'webp') return 'image/webp';
  return 'image/jpeg';
}

function publicUrl(objectPath) {
  return `https://storage.googleapis.com/${STORAGE_BUCKET}/${objectPath}`;
}

async function main() {
  const { db, bucket } = initAdmin();

  const irshadSnap = await db.collection('irshadat_ur').get();
  const irshads = irshadSnap.docs
    .map((d) => ({ id: d.id, ...d.data() }))
    .filter((e) => e.isActive !== false && (e.imageUrl || '').trim());

  // Dedupe by image URL (Urdu + English share the same file).
  const byUrl = new Map();
  for (const row of irshads) {
    const url = row.imageUrl.trim();
    if (!byUrl.has(url)) byUrl.set(url, row);
  }
  const unique = [...byUrl.values()];
  unique.sort((a, b) => {
    const ta = a.createdAt?.toDate?.() ?? new Date(0);
    const tb = b.createdAt?.toDate?.() ?? new Date(0);
    return tb - ta;
  });

  console.log(
    `Found ${unique.length} unique Irshadat images${dryRun ? ' (dry run)' : ''}…`,
  );

  let copied = 0;
  let skipped = 0;
  let failed = 0;

  for (let i = 0; i < unique.length; i++) {
    const row = unique[i];
    const galleryId = `irshad_${row.id}`;
    const srcPath = storagePathFromUrl(row.imageUrl);
    if (!srcPath) {
      failed++;
      console.log(`[${i + 1}/${unique.length}] ${row.id}: bad imageUrl`);
      continue;
    }

    const existing = await db.collection('gallery_images').doc(galleryId).get();
    if (existing.exists && (existing.data()?.downloadUrl || '').trim()) {
      skipped++;
      continue;
    }

    const ext = extFromPath(srcPath);
    const destPath = `gallery_images/${galleryId}.${ext}`;

    if (dryRun) {
      console.log(`[${i + 1}] ${galleryId} <= ${srcPath}`);
      copied++;
      continue;
    }

    process.stdout.write(`[${i + 1}/${unique.length}] ${galleryId}… `);
    try {
      const srcFile = bucket.file(srcPath);
      const [exists] = await srcFile.exists();
      if (!exists) {
        failed++;
        console.log(`FAILED: missing ${srcPath}`);
        continue;
      }

      const destFile = bucket.file(destPath);
      await srcFile.copy(destFile);
      await destFile.setMetadata({ contentType: contentTypeForExt(ext) });
      await destFile.makePublic().catch(() => {});

      const createdAt = row.createdAt?.toDate?.() ?? new Date();
      await db.collection('gallery_images').doc(galleryId).set(
        {
          storagePath: destPath,
          downloadUrl: publicUrl(destPath),
          uploadedAt: Timestamp.fromDate(createdAt),
          isActive: true,
          source: 'irshadat',
          sourceIrshadId: row.id,
        },
        { merge: true },
      );

      copied++;
      console.log('ok');
    } catch (e) {
      failed++;
      console.log(`FAILED: ${e.message ?? e}`);
    }
  }

  const galleryCount = await db
    .collection('gallery_images')
    .where('isActive', '==', true)
    .count()
    .get();
  console.log(
    `Done. copied=${copied}, skipped=${skipped}, failed=${failed}, active gallery=${galleryCount.data().count}`,
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
