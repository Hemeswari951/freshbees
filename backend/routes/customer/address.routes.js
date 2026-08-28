
const express = require("express");
const router = express.Router();

const addressController = require("../../controllers/customer/address.controller");
const customerAuth = require("../../middleware/customerAuth");

// Every address route needs a logged-in customer.
router.use(customerAuth);

// GET    /api/customer/addresses           → saved address book
router.get("/", addressController.getAddresses);

// POST   /api/customer/addresses           { full_name, phone, address_line1, ... } → add new
router.post("/", addressController.addAddress);

// PUT    /api/customer/addresses/:id/default → make this the default address
router.put("/:id/default", addressController.setDefault);

// DELETE /api/customer/addresses/:id       → remove an address
router.delete("/:id", addressController.deleteAddress);

module.exports = router;
