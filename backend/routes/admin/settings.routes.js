// ============================================================================
//  routes/admin/settings.routes.js
//  adminAuth is already applied in routes/admin/index.js
//  so every route here is automatically protected
// ============================================================================
 
const router    = require('express').Router();
const ctrl      = require('../../controllers/admin/settings.controller');
const { upload } = require('../../middleware/upload');  // multer — memory storage
const { body, validationResult } = require('express-validator');
const adminAuth = require('../../middleware/adminauth'); // ⚠ adjust this path/filename to match your project
 
// Applied directly here so these routes work regardless of whether it's
// also applied globally in server.js / routes/admin/index.js. If your
// middleware sets req.user instead of req.admin, either rename it here to
// `(req,res,next)=>{req.admin=req.user;next();}` or update the controller
// to read req.user.id instead of req.admin.id.
router.use(adminAuth);
 
// ── Validation helper ────────────────────────────────────────────────────────
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  next();
};
 
// ── Validators per section ───────────────────────────────────────────────────
// NOTE: `.optional({ checkFalsy: true })` treats '', null, and undefined all
// as "not provided" and skips the rest of the chain. Without checkFalsy,
// .optional() only skips validation when the field is missing entirely —
// an empty string still gets validated and fails isURL()/isEmail().
 
const validateAppInfo = [
  body('app_name')
    .optional({ checkFalsy: true })
    .trim()
    .notEmpty().withMessage('App name cannot be empty')
    .isLength({ max: 100 }).withMessage('Max 100 characters'),
  validate,
];
 
const validateContact = [
  body('support_email')
    .optional({ checkFalsy: true })
    .trim()
    .isEmail().withMessage('Invalid support email'),
  body('website_url')
    .optional({ checkFalsy: true })
    .trim()
    .isURL().withMessage('Invalid website URL'),
  body('support_phone')
    .optional({ checkFalsy: true })
    .trim()
    .isLength({ max: 20 }).withMessage('Max 20 characters'),
  body('whatsapp_number')
    .optional({ checkFalsy: true })
    .trim()
    .isLength({ max: 20 }).withMessage('Max 20 characters'),
  validate,
];
 
const validateSocial = [
  body('facebook_url').optional({ checkFalsy: true }).trim().isURL().withMessage('Invalid Facebook URL'),
  body('instagram_url').optional({ checkFalsy: true }).trim().isURL().withMessage('Invalid Instagram URL'),
  body('twitter_url').optional({ checkFalsy: true }).trim().isURL().withMessage('Invalid X/Twitter URL'),
  body('youtube_url').optional({ checkFalsy: true }).trim().isURL().withMessage('Invalid YouTube URL'),
  body('linkedin_url').optional({ checkFalsy: true }).trim().isURL().withMessage('Invalid LinkedIn URL'),
  validate,
];
 
const validateFooter = [
  body('company_name')
    .optional({ checkFalsy: true })
    .trim()
    .notEmpty().withMessage('Company name cannot be empty')
    .isLength({ max: 150 }),
  body('copyright_text')
    .optional({ checkFalsy: true })
    .trim()
    .notEmpty().withMessage('Copyright text cannot be empty'),
  body('privacy_policy_link')
    .optional({ checkFalsy: true })
    .trim()
    .isURL().withMessage('Invalid privacy policy URL'),
  body('terms_link')
    .optional({ checkFalsy: true })
    .trim()
    .isURL().withMessage('Invalid terms URL'),
  validate,
];
 
const validateContactUs = [
  body('contact_email')
    .optional({ checkFalsy: true })
    .trim()
    .isEmail().withMessage('Invalid contact email'),
  body('contact_phone')
    .optional({ checkFalsy: true })
    .trim()
    .isLength({ max: 20 }),
  body('working_hours')
    .optional({ checkFalsy: true })
    .trim()
    .isLength({ max: 255 }),
  validate,
];
 
// ── Routes ───────────────────────────────────────────────────────────────────
 
// Load all settings — called once when the settings page opens
router.get('/', ctrl.getSettings);
 
// 1.1 Application Information
router.put('/app-info',  validateAppInfo,  ctrl.updateAppInfo);
router.post('/app-logo', upload.single('logo'),    ctrl.uploadLogo);
router.post('/favicon',  upload.single('favicon'), ctrl.uploadFavicon);
 
// 1.2 Contact Information
router.put('/contact', validateContact, ctrl.updateContact);
 
// 1.3 Social Media Links
router.put('/social', validateSocial, ctrl.updateSocial);
 
// 1.4 Footer Information
router.put('/footer', validateFooter, ctrl.updateFooter);
 
// 1.5 Contact Us Details
router.put('/contact-us', validateContactUs, ctrl.updateContactUs);
 
module.exports = router;
 
// ── Add this ONE line to routes/admin/index.js ───────────────────────────────
//
//   router.use('/settings', require('./settings.routes'));
//
// ── Final API endpoint map ───────────────────────────────────────────────────
//
//   GET  /api/admin/settings              → load full settings page
//   PUT  /api/admin/settings/app-info     → 1.1 update name
//   POST /api/admin/settings/app-logo     → 1.1 upload logo  (multipart)
//   POST /api/admin/settings/favicon      → 1.1 upload favicon (multipart)
//   PUT  /api/admin/settings/contact      → 1.2 contact info
//   PUT  /api/admin/settings/social       → 1.3 social links
//   PUT  /api/admin/settings/footer       → 1.4 footer info
//   PUT  /api/admin/settings/contact-us   → 1.5 contact us details