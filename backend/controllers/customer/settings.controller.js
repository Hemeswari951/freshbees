// ============================================================================
//  controllers/admin/settings.controller.js  (UPDATED)
//  uploadLogo and uploadFavicon now save locally to uploads/ folder
//  and return the accessible URL — stored in app_settings.app_logo / favicon_url
// ============================================================================
 
const fs   = require('fs');
const path = require('path');
const settingsService = require('../../services/admin/settings.service');
 
// ── Local file save helper ───────────────────────────────────────────────────
// Saves req.file.buffer to ./uploads/<folder>/ and returns the full URL.
// server.js already serves:  app.use('/uploads', express.static('./uploads'))
// So the file at  ./uploads/logo/logo_1234.png
// is reachable at http://localhost:3000/uploads/logo/logo_1234.png
 
const saveLocally = (buffer, originalName, folder) => {
  const dir = path.join(__dirname, '../../uploads', folder);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
 
  const ext      = path.extname(originalName) || '.png';
  const filename = `${folder}_${Date.now()}${ext}`;
  const filepath = path.join(dir, filename);
 
  fs.writeFileSync(filepath, buffer);
 
  const serverUrl = process.env.SERVER_URL || 'http://localhost:3000';
  return `${serverUrl}/uploads/${folder}/${filename}`;
};
 
// ── GET /api/admin/settings ──────────────────────────────────────────────────
exports.getSettings = async (req, res) => {
  try {
    const data = await settingsService.getAll();
    if (!data) return res.status(404).json({ success: false, error: 'Settings not initialised' });
    res.json({ success: true, data });
  } catch (err) {
    console.error('[getSettings]', err.message);
    res.status(500).json({ success: false, error: 'Failed to load settings' });
  }
};
 
// ── PUT /api/admin/settings/app-info ────────────────────────────────────────
exports.updateAppInfo = async (req, res) => {
  try {
    const updated = await settingsService.updateAppInfo(req.admin.id, req.body);
    res.json({ success: true, data: updated, message: 'Application info updated' });
  } catch (err) {
    console.error('[updateAppInfo]', err.message);
    res.status(500).json({ success: false, error: 'Failed to update application info' });
  }
};
 
// ── POST /api/admin/settings/app-logo ───────────────────────────────────────
// multer memory storage → req.file.buffer available
// Saves to ./uploads/logo/  and stores URL in DB
exports.uploadLogo = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, error: 'No file uploaded' });
    }
 
    // Save file locally and get accessible URL
    const logoUrl = saveLocally(req.file.buffer, req.file.originalname, 'logo');
 
    // Store URL in app_settings.app_logo
    const updated = await settingsService.updateAppInfo(req.admin.id, { app_logo: logoUrl });
 
    res.json({ success: true, data: updated, message: 'Logo uploaded' });
  } catch (err) {
    console.error('[uploadLogo]', err.message);
    res.status(500).json({ success: false, error: 'Logo upload failed' });
  }
};
 
// ── POST /api/admin/settings/favicon ────────────────────────────────────────
// Saves to ./uploads/favicon/ and stores URL in DB
exports.uploadFavicon = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, error: 'No file uploaded' });
    }
 
    const faviconUrl = saveLocally(req.file.buffer, req.file.originalname, 'favicon');
 
    const updated = await settingsService.updateAppInfo(req.admin.id, { favicon_url: faviconUrl });
 
    res.json({ success: true, data: updated, message: 'Favicon uploaded' });
  } catch (err) {
    console.error('[uploadFavicon]', err.message);
    res.status(500).json({ success: false, error: 'Favicon upload failed' });
  }
};
 
// ── PUT /api/admin/settings/contact ─────────────────────────────────────────
exports.updateContact = async (req, res) => {
  try {
    const updated = await settingsService.updateContact(req.admin.id, req.body);
    res.json({ success: true, data: updated, message: 'Contact info updated' });
  } catch (err) {
    console.error('[updateContact]', err.message);
    res.status(500).json({ success: false, error: 'Failed to update contact info' });
  }
};
 
// ── PUT /api/admin/settings/social ──────────────────────────────────────────
exports.updateSocial = async (req, res) => {
  try {
    const updated = await settingsService.updateSocial(req.admin.id, req.body);
    res.json({ success: true, data: updated, message: 'Social links updated' });
  } catch (err) {
    console.error('[updateSocial]', err.message);
    res.status(500).json({ success: false, error: 'Failed to update social links' });
  }
};
 
// ── PUT /api/admin/settings/footer ──────────────────────────────────────────
exports.updateFooter = async (req, res) => {
  try {
    const updated = await settingsService.updateFooter(req.admin.id, req.body);
    res.json({ success: true, data: updated, message: 'Footer info updated' });
  } catch (err) {
    console.error('[updateFooter]', err.message);
    res.status(500).json({ success: false, error: 'Failed to update footer info' });
  }
};
 
// ── PUT /api/admin/settings/contact-us ──────────────────────────────────────
exports.updateContactUs = async (req, res) => {
  try {
    const updated = await settingsService.updateContactUs(req.admin.id, req.body);
    res.json({ success: true, data: updated, message: 'Contact Us details updated' });
  } catch (err) {
    console.error('[updateContactUs]', err.message);
    res.status(500).json({ success: false, error: 'Failed to update Contact Us details' });
  }
};
 