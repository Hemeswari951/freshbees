// ============================================================================
//  services/settings.service.js  (UPDATED)
//  Business logic only — DB queries moved to models/settings.model.js
//  This layer is where you'd add things like:
//    - cache invalidation after save
//    - sending notification emails after certain changes
//    - formatting/transforming data before returning
// ============================================================================
 
const SettingsModel = require('../../models/admin/settings.model');
 
const settingsService = {
 
  // ── GET all settings ──────────────────────────────────────────────────────
  // Overrides app_version from .env so it's never editable via the UI
  async getAll() {
    const data = await SettingsModel.findOne();
    if (!data) return null;
 
    return {
      ...data,
      app_version: process.env.APP_VERSION || '1.0.0',  // read-only from .env
    };
  },
 
  // ── 1.1 Application Information ───────────────────────────────────────────
  // app_logo and favicon_url come in only after S3 upload succeeds in controller
  async updateAppInfo(adminId, fields) {
    return await SettingsModel.updateAppInfo(adminId, fields);
  },
 
  // ── 1.2 Contact Information ───────────────────────────────────────────────
  async updateContact(adminId, fields) {
    return await SettingsModel.updateContact(adminId, fields);
  },
 
  // ── 1.3 Social Media Links ────────────────────────────────────────────────
  async updateSocial(adminId, fields) {
    return await SettingsModel.updateSocial(adminId, fields);
  },
 
  // ── 1.4 Footer Information ────────────────────────────────────────────────
  async updateFooter(adminId, fields) {
    return await SettingsModel.updateFooter(adminId, fields);
  },
 
  // ── 1.5 Contact Us Details ────────────────────────────────────────────────
  async updateContactUs(adminId, fields) {
    return await SettingsModel.updateContactUs(adminId, fields);
  },
 
};
 
module.exports = settingsService;
 
 