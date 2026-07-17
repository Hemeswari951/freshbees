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

module.exports = { uploadFile };