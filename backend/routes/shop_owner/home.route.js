const express = require("express");
const router = express.Router();

const homeController = require("../../controllers/shop_owner/home.controller");
const shopOwnerAuth = require("../../middleware/shopownerauth");

router.get('/', shopOwnerAuth, homeController.getHome);

module.exports = router;
