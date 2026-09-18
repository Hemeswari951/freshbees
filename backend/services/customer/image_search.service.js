const fs = require('fs');
const path = require('path');
const { Jimp } = require('jimp');
const pool = require('../../config/db');

// -----------------------------------------------------------------------------
// IMAGE (VISUAL) SEARCH
// -----------------------------------------------------------------------------
// How it works:
//   1. The photo the customer took/picked is decoded and reduced to a small
//      color-histogram "fingerprint" (a fixed-length vector of numbers that
//      describes which colors appear in the image and how much of the image
//      they cover).
//   2. Every catalog product's thumbnail image already has (or gets) the
//      same kind of fingerprint computed once and cached in memory.
//   3. We compare the query fingerprint against every candidate product's
//      fingerprint with histogram intersection (a standard, cheap image-
//      similarity measure) and return the closest matches, most-similar
//      first — reusing the exact same product JSON shape the normal
//      text search already returns, so the Flutter app needs no special
//      handling for image results.
//
// This needs no paid computer-vision API and no native image libraries
// (Jimp is pure JavaScript), so it runs anywhere Node runs. It is a
// lightweight visual-similarity search (color + coarse layout), not full
// object recognition — it's intentionally built so the matching step
// (extractFeatureVector + similarity) can be swapped later for a real
// ML embedding model (e.g. CLIP) without touching the rest of the app.
// -----------------------------------------------------------------------------

const UPLOAD_ROOT = path.join(__dirname, '..', '..', 'uploads');

// Fingerprint size: BINS_PER_CHANNEL^3 buckets (quantized RGB histogram).
const BINS_PER_CHANNEL = 6;
const FEATURE_SIZE = BINS_PER_CHANNEL * BINS_PER_CHANNEL * BINS_PER_CHANNEL;

// Everything is resized down to this before histogramming — keeps
// extraction fast and focuses the fingerprint on overall color/composition
// rather than pixel-level noise.
const THUMB_SIZE = 32;

// Cap how many catalog products get compared per request, most-recent
// first — keeps a single image search fast even as the catalog grows.
// (Raise this, or move the cache to a persistent store, for larger
// catalogs.)
const MAX_CANDIDATES = 500;

// Minimum similarity (0-1, histogram intersection) before a product is
// considered a real match at all, so a totally unrelated photo doesn't
// still return a wall of "closest but irrelevant" products.
const MIN_SIMILARITY = 0.15;

// -----------------------------------------------------------------------------
// In-memory fingerprint cache, keyed by absolute file path on disk.
// Invalidated automatically if the file's mtime changes (e.g. a shop
// owner replaces the photo).
// -----------------------------------------------------------------------------
const fingerprintCache = new Map(); // absPath -> { mtimeMs, vector }

/**
 * Turns a decoded image into a normalized RGB color-histogram vector
 * (values sum to 1, so it can be compared across different image sizes).
 */
function histogramFromImage(image) {
  image.cover({ w: THUMB_SIZE, h: THUMB_SIZE });

  const vector = new Float64Array(FEATURE_SIZE);
  const { data } = image.bitmap;
  let pixelCount = 0;

  for (let i = 0; i < data.length; i += 4) {
    const alpha = data[i + 3];
    if (alpha < 16) continue; // skip fully/mostly transparent pixels

    const r = data[i];
    const g = data[i + 1];
    const b = data[i + 2];

    const rBin = Math.min(BINS_PER_CHANNEL - 1, Math.floor((r / 256) * BINS_PER_CHANNEL));
    const gBin = Math.min(BINS_PER_CHANNEL - 1, Math.floor((g / 256) * BINS_PER_CHANNEL));
    const bBin = Math.min(BINS_PER_CHANNEL - 1, Math.floor((b / 256) * BINS_PER_CHANNEL));

    const bucket = rBin * BINS_PER_CHANNEL * BINS_PER_CHANNEL + gBin * BINS_PER_CHANNEL + bBin;
    vector[bucket] += 1;
    pixelCount += 1;
  }

  if (pixelCount === 0) return vector; // fully transparent image, edge case

  for (let i = 0; i < vector.length; i++) {
    vector[i] /= pixelCount;
  }

  return vector;
}

/**
 * Extracts a color-histogram fingerprint straight from an image buffer
 * (used for the customer's uploaded photo, which never touches disk).
 */
async function extractFeatureVector(buffer) {
  const image = await Jimp.read(buffer);
  return histogramFromImage(image);
}

/**
 * Same extraction, but for a product image already saved on disk —
 * cached by path + last-modified time so repeat searches don't re-decode
 * every product photo every time.
 */
async function extractFeatureVectorFromDisk(absPath) {
  let stat;
  try {
    stat = fs.statSync(absPath);
  } catch (err) {
    return null; // file missing on disk — skip this product silently
  }

  const cached = fingerprintCache.get(absPath);
  if (cached && cached.mtimeMs === stat.mtimeMs) {
    return cached.vector;
  }

  try {
    const image = await Jimp.read(absPath);
    const vector = histogramFromImage(image);
    fingerprintCache.set(absPath, { mtimeMs: stat.mtimeMs, vector });
    return vector;
  } catch (err) {
    console.error('[imageSearch] failed to decode', absPath, err.message);
    return null;
  }
}

/** Histogram intersection similarity — both vectors sum to 1, so the
 * result is naturally in [0, 1], where 1 means identical color makeup. */
function histogramIntersection(a, b) {
  let sum = 0;
  for (let i = 0; i < a.length; i++) {
    sum += Math.min(a[i], b[i]);
  }
  return sum;
}

/** Resolves a stored "/uploads/..." image_url back to an absolute path
 * on disk. Returns null for anything that isn't a local upload (e.g. a
 * future CDN/absolute URL) since those can't be read off this server's
 * filesystem. */
function resolveLocalImagePath(imageUrl) {
  if (!imageUrl || typeof imageUrl !== 'string') return null;
  if (!imageUrl.startsWith('/uploads/')) return null;

  const relative = imageUrl.replace(/^\/uploads\//, '');
  return path.join(UPLOAD_ROOT, relative);
}

/**
 * Pulls the most recent, publicly-visible products (active product,
 * non-blocked shop) along with their thumbnail image — the same
 * "first photo" every other product-list endpoint uses — capped at
 * MAX_CANDIDATES for performance.
 */
async function getCandidateProducts() {
  const { rows } = await pool.query(
    `
    SELECT
      p.product_id,
      img.image_url AS thumbnail
    FROM products p
    JOIN shops s
      ON s.shop_id = p.shop_id
    JOIN LATERAL (
      SELECT pi.image_url
      FROM product_images pi
      JOIN product_colors pc
        ON pc.product_color_id = pi.product_color_id
      WHERE pc.product_id = p.product_id
      ORDER BY
        pc.created_at ASC,
        CASE pi.image_type WHEN 'front' THEN 0 ELSE 1 END,
        pi.display_order ASC
      LIMIT 1
    ) img ON true
    WHERE p.is_active = true
      AND s.is_blocked = false
    ORDER BY p.created_at DESC
    LIMIT $1
    `,
    [MAX_CANDIDATES]
  );

  return rows;
}

/**
 * Main entry point: given the raw bytes of the customer's photo, returns
 * the matching product IDs ordered by visual similarity (best first),
 * along with each product's similarity score.
 */
async function rankProductsByImage(imageBuffer, { limit = 24 } = {}) {
  const queryVector = await extractFeatureVector(imageBuffer);
  const candidates = await getCandidateProducts();

  const scored = [];

  for (const candidate of candidates) {
    const absPath = resolveLocalImagePath(candidate.thumbnail);
    if (!absPath) continue;

    const vector = await extractFeatureVectorFromDisk(absPath);
    if (!vector) continue;

    const similarity = histogramIntersection(queryVector, vector);
    if (similarity >= MIN_SIMILARITY) {
      scored.push({ productId: candidate.product_id, similarity });
    }
  }

  scored.sort((a, b) => b.similarity - a.similarity);

  return scored.slice(0, limit);
}

module.exports = {
  rankProductsByImage,
  extractFeatureVector, // exported for tests/tuning
  MIN_SIMILARITY,
};
