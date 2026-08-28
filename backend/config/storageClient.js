const fs   = require('fs');
const path = require('path');

// Files will be saved to: backend/uploads/shops/logos/  etc.
const UPLOAD_ROOT = path.join(__dirname, '..', 'uploads');

async function uploadFile(file, folder, filename) {
  const dir = path.join(UPLOAD_ROOT, folder);

  // Create folder if it doesn't exist
  fs.mkdirSync(dir, { recursive: true });

  const ext      = path.extname(file.originalname);
  const fullFilename = `${filename}${ext}`;
  const fullPath = path.join(dir, fullFilename);

  fs.writeFileSync(fullPath, file.buffer);

  // Return a URL path Flutter can use to load the image
  return `/uploads/${folder}/${fullFilename}`;
}

// url looks like "/uploads/products/3/1784803014006_0_front.jpeg" — this
// is exactly what uploadFile() returns above, so deleteFile() just
// reverses that same path-building logic to find the file on disk again.
//
// Swapping to Cloudflare R2/S3 later: keep this same function signature
// (deleteFile(url) -> Promise<void>), just swap the body for
// s3.deleteObject({ Key: ... }) — nothing that calls deleteFile needs to
// change.
async function deleteFile(url) {
  if (!url) return;

  try {
    // Strip the leading "/uploads/" so we're left with the same
    // "folder/filename.ext" shape uploadFile() was given.
    const relative = url.replace(/^\/?uploads\//, '');
    const fullPath = path.join(UPLOAD_ROOT, relative);

    if (fs.existsSync(fullPath)) {
      fs.unlinkSync(fullPath);
    }
    // If it doesn't exist, silently move on — the file's already gone
    // (double-delete, manual cleanup, whatever), so this shouldn't fail
    // the whole update just because of that.
  } catch (err) {
    // Don't let a storage cleanup failure block the DB update — log it
    // and move on. Worst case: one orphaned file on disk, which is a lot
    // less bad than a failed product update.
    console.error('Failed to delete file:', url, err);
  }
}

module.exports = { uploadFile, deleteFile };