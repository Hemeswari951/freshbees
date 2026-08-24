const express = require('express');
const router  = express.Router();

router.use('/auth',      require('./auth.routes'));
router.use('/home',  require('./home.routes'));
// router.use('/shops', require('./shop.routes'));
// router.use('/wishlist', require('./wishlist.routes'));
router.use('/products', require('./product.routes'));

router.use('/search', require('./search.routes'));

module.exports = router;