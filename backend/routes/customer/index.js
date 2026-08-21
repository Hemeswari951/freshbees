const express = require('express');
const router  = express.Router();

router.use('/auth',      require('./auth.route'));
router.use('/home',  require('./home.routes'));
// router.use('/shops', require('./shop.routes'));
router.use('/wishlist', require('./wishlist.routes'));
router.use('/products', require('./product.routes'));
router.use('/products/:productId/reviews', require('./review.routes')); // NEW — ratings & reviews
router.use('/style-profile', require('./style_profile.routes'));
router.use('/tryon-profiles', require('./tryonProfile.routes'));
router.use('/orders', require('./order.routes')); // NEW
router.use('/cart', require('./cart.routes'));     // NEW — bag / add-to-cart
router.use('/addresses', require('./address.routes')); // NEW — address book for checkout

module.exports = router;