// ============================================================================
//  models/settings.model.js
//  Raw PostgreSQL queries for app_settings table
//  This is the ONLY file that talks directly to the DB for settings
//  Called by: services/settings.service.js
// ============================================================================
 
const db = require('../../config/db');   // your pg Pool
 
const SettingsModel = {
 
  // ── Find the singleton settings row ──────────────────────────────────────
  findOne: async () => {
    const result = await db.query(
      `SELECT
         app_name,
         app_logo,
         favicon_url,
         app_version,
         support_email,
         support_phone,
         whatsapp_number,
         website_url,
         facebook_url,
         instagram_url,
         twitter_url,
         youtube_url,
         linkedin_url,
         company_name,
         copyright_text,
         privacy_policy_link,
         terms_link,
         office_address,
         contact_email,
         contact_phone,
         working_hours,
         updated_at
       FROM app_settings
       WHERE setting_id = 1`
    );
    return result.rows[0] || null;
  },
 
  // ── 1.1 Update app info fields ────────────────────────────────────────────
  updateAppInfo: async (adminId, { app_name, app_logo, favicon_url }) => {
    const result = await db.query(
      `UPDATE app_settings
       SET
         app_name    = COALESCE($1, app_name),
         app_logo    = COALESCE($2, app_logo),
         favicon_url = COALESCE($3, favicon_url),
         updated_by  = $4,
         updated_at  = NOW()
       WHERE setting_id = 1
       RETURNING app_name, app_logo, favicon_url, app_version`,
      [app_name, app_logo, favicon_url, adminId]
    );
    return result.rows[0];
  },
 
  // ── 1.2 Update contact info fields ────────────────────────────────────────
  updateContact: async (adminId, { support_email, support_phone, whatsapp_number, website_url }) => {
    const result = await db.query(
      `UPDATE app_settings
       SET
         support_email   = COALESCE($1, support_email),
         support_phone   = COALESCE($2, support_phone),
         whatsapp_number = COALESCE($3, whatsapp_number),
         website_url     = COALESCE($4, website_url),
         updated_by      = $5,
         updated_at      = NOW()
       WHERE setting_id = 1
       RETURNING support_email, support_phone, whatsapp_number, website_url`,
      [support_email, support_phone, whatsapp_number, website_url, adminId]
    );
    return result.rows[0];
  },
 
  // ── 1.3 Update social media fields ───────────────────────────────────────
  updateSocial: async (adminId, { facebook_url, instagram_url, twitter_url, youtube_url, linkedin_url }) => {
    const result = await db.query(
      `UPDATE app_settings
       SET
         facebook_url  = COALESCE($1, facebook_url),
         instagram_url = COALESCE($2, instagram_url),
         twitter_url   = COALESCE($3, twitter_url),
         youtube_url   = COALESCE($4, youtube_url),
         linkedin_url  = COALESCE($5, linkedin_url),
         updated_by    = $6,
         updated_at    = NOW()
       WHERE setting_id = 1
       RETURNING facebook_url, instagram_url, twitter_url, youtube_url, linkedin_url`,
      [facebook_url, instagram_url, twitter_url, youtube_url, linkedin_url, adminId]
    );
    return result.rows[0];
  },
 
  // ── 1.4 Update footer info fields ─────────────────────────────────────────
  updateFooter: async (adminId, { company_name, copyright_text, privacy_policy_link, terms_link }) => {
    const result = await db.query(
      `UPDATE app_settings
       SET
         company_name        = COALESCE($1, company_name),
         copyright_text      = COALESCE($2, copyright_text),
         privacy_policy_link = COALESCE($3, privacy_policy_link),
         terms_link          = COALESCE($4, terms_link),
         updated_by          = $5,
         updated_at          = NOW()
       WHERE setting_id = 1
       RETURNING company_name, copyright_text, privacy_policy_link, terms_link`,
      [company_name, copyright_text, privacy_policy_link, terms_link, adminId]
    );
    return result.rows[0];
  },
 
  // ── 1.5 Update contact us fields ─────────────────────────────────────────
  updateContactUs: async (adminId, { office_address, contact_email, contact_phone, working_hours }) => {
    const result = await db.query(
      `UPDATE app_settings
       SET
         office_address = COALESCE($1, office_address),
         contact_email  = COALESCE($2, contact_email),
         contact_phone  = COALESCE($3, contact_phone),
         working_hours  = COALESCE($4, working_hours),
         updated_by     = $5,
         updated_at     = NOW()
       WHERE setting_id = 1
       RETURNING office_address, contact_email, contact_phone, working_hours`,
      [office_address, contact_email, contact_phone, working_hours, adminId]
    );
    return result.rows[0];
  },
 
};
 
module.exports = SettingsModel;
 
 