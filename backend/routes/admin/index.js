const express = require('express');
const router  = express.Router();

router.use('/auth',      require('./auth.routes'));
router.use('/dashboard', require('./dashboard.routes'));
router.use('/shops',     require('./shops.routes'));
// router.use('/products',  require('./products.routes'));
router.use('/customers',     require('./customer.route'));
// router.use('/orders',    require('./orders.routes'));

module.exports = router;