const express = require('express');
const router  = express.Router();

router.use('/auth',      require('./auth.route'));
router.use('/home',  require('./home.routes'));
// router.use('/shops', require('./shop.routes'));
// router.use('/wishlist', require('./wishlist.routes'));
router.use('/products', require('./product.routes'));

module.exports = router;