
// address.controller.js

const addressModel = require("../../models/customer/address.model");

// Row → JSON matching the Flutter AddressModel.fromJson().
function mapAddress(row) {
    return {
        addressId: row.address_id,
        fullName: row.full_name,
        phone: row.phone,
        addressLine1: row.address_line1,
        addressLine2: row.address_line2 || "",
        city: row.city || "",
        state: row.state || "",
        country: row.country || "India",
        pincode: row.pincode || "",
        addressType: row.address_type || "Home",
        isDefault: !!row.is_default,
    };
}

// GET /api/customer/addresses
exports.getAddresses = async (req, res) => {
    try {
        const rows = await addressModel.getAddressesByCustomer(req.customer.customerId);
        res.json({ success: true, data: rows.map(mapAddress) });
    } catch (err) {
        console.log("Get Addresses Error:", err);
        res.status(500).json({ success: false, message: "Failed to fetch addresses" });
    }
};

// POST /api/customer/addresses
// { full_name, phone, address_line1, address_line2?, city?, state?, country?, pincode, address_type?, is_default? }
exports.addAddress = async (req, res) => {
    try {
        const {
            full_name, phone, address_line1, address_line2,
            city, state, country, pincode, address_type, is_default
        } = req.body;

        if (!full_name || !phone || !address_line1 || !pincode) {
            return res.status(400).json({
                success: false,
                message: "full_name, phone, address_line1 and pincode are required",
            });
        }

        const addressId = await addressModel.addAddress(req.customer.customerId, {
            full_name, phone, address_line1, address_line2,
            city, state, country, pincode, address_type, is_default,
        });

        res.status(201).json({ success: true, message: "Address added", address_id: addressId });
    } catch (err) {
        console.log("Add Address Error:", err);
        res.status(500).json({ success: false, message: "Failed to add address" });
    }
};

// PUT /api/customer/addresses/:id/default
exports.setDefault = async (req, res) => {
    try {
        const addressId = Number(req.params.id);
        const updated = await addressModel.setDefaultAddress(req.customer.customerId, addressId);
        if (!updated) {
            return res.status(404).json({ success: false, message: "Address not found" });
        }
        res.json({ success: true, message: "Default address updated" });
    } catch (err) {
        console.log("Set Default Address Error:", err);
        res.status(500).json({ success: false, message: "Failed to update default address" });
    }
};

// DELETE /api/customer/addresses/:id
exports.deleteAddress = async (req, res) => {
    try {
        const addressId = Number(req.params.id);
        const removed = await addressModel.deleteAddress(req.customer.customerId, addressId);
        if (!removed) {
            return res.status(404).json({ success: false, message: "Address not found" });
        }
        res.json({ success: true, message: "Address removed" });
    } catch (err) {
        console.log("Delete Address Error:", err);
        res.status(500).json({ success: false, message: "Failed to remove address" });
    }
};
