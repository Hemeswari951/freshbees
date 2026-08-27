const express = require('express');
const router  = express.Router();

router.use('/auth',      require('./auth.routes'));
router.use('/home',  require('./home.routes'));
router.use('/search', require('./search.routes'));

router.use('/products', require('./product.routes'));
router.use('/wishlist', require('./wishlist.routes'));

// Trial on
router.use('/style-profile', require('./style_profile.routes'));
router.use('/tryon-profiles', require('./tryonProfile.routes'));

router.use('/products/:productId/reviews', require('./review.routes')); // NEW — ratings & reviews

router.use('/orders', require('./order.routes')); // NEW
router.use('/cart', require('./cart.routes'));     // NEW — bag / add-to-cart
router.use('/addresses', require('./address.routes')); // NEW — address book for checkout
router.use('/settings', require('./settings.routes'));

module.exports = router;