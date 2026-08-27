const express = require('express');
const router  = express.Router();

router.use('/auth',      require('./auth.route'));
router.use('/home',      require('./home.route'));
router.use('/products',  require('./products.route'));
router.use('/profile',   require('./profile.route'));
router.use('/orders',    require('./order.route'));

module.exports = router;