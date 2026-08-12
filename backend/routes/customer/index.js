const express = require('express');
const router  = express.Router();

router.use('/auth', require('./auth.routes'));
router.use('/shops', require('./shop.routes'));
router.use('/products', require('./product.routes'));
router.use('/orders', require('./order.routes')); // NEW
router.use('/cart', require('./cart.routes'));     // NEW — bag / add-to-cart
router.use('/addresses', require('./address.routes')); // NEW — address book for checkout
router.use('/wishlist', require('./wishlist.routes'));


module.exports = router;