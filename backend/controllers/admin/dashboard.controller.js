const bcrypt = require("bcrypt");
const createAdminModel = require("../../models/admin/create_admin.model");
const dashboardService = require("../../services/admin/dashboard.service");

// Get dashboard data
async function getDashboardData(req, res) {
    try {
        const dashboardData = await dashboardService.getDashboardData();
        res.status(200).json({
            success: true,
            data: dashboardData,
        });
    }

    catch (err) {
        console.error("[getDashboardData]", err);
        res.status(500).json({
            success: false,
            message: "Failed to fetch dashboard data",
        });
    }
}

// Create a new admin user
async function createAdmin(req, res) {
    try {
        const { full_name, username, email, password, role="Admin", is_active=true } = req.body;

        // Validate required fields
        if (!full_name || !username || !email || !password) {
            return res.status(400).json({
                success: false,
                message: "Full name, username, email, and password are required",
            });
        }

        // Check if username or email already exists
        const existingUsername = await createAdminModel.findByUsername(username);
        if (existingUsername) {
            return res.status(400).json({
                success: false,
                message: "Username already exists",
            });
        }
        // Check if email already exists
        const existingEmail = await createAdminModel.findByEmail(email);
        if (existingEmail) {
            return res.status(400).json({
                success: false,
                message: "Email already exists",
            });
        }

        // Hash the password
        const password_hash = await bcrypt.hash(password, 10);

        // Create the new admin
        const newAdmin = await createAdminModel.createAdmin({
            full_name,
            username,
            email,
            password_hash,
            role,
            is_active,
        });

        res.status(201).json({
            success: true,
            message: "Admin created successfully",
            data: newAdmin,
        });
    }

    catch (error) {
        console.error("Error creating admin:", error);
        res.status(500).json({
            success: false,
            message: "Internal server error",
        });
    }
}

module.exports = {
    getDashboardData,
    createAdmin,
};
