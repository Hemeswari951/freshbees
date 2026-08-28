/*--- Controller contains - Try, Catch, HTTP Status, JSON---*/
const customerService = require("../../services/admin/customer.service");

/*
=========================================
Admin's Customer Dashboard Controller
=========================================
*/
const getDashboard = async (req, res) => {

    try {

        const dashboard =
            await customerService.getDashboard();

        return res.status(200).json({

            success: true,

            data: dashboard

        });

    }

    catch (error) {

        console.error(error);

        return res.status(500).json({

            success: false,

            message: "Internal Server Error"

        });

    }

};

/*
=========================================
    Customer List
=========================================
*/
const getCustomers = async (req, res) => {

    try {

        // Read all query parameters
        const filters = req.query;

        const customers =
            await customerService.getCustomers(filters);

        return res.status(200).json({

            success: true,

            data: customers

        });

    }

    catch (error) {

        console.error(error);

        return res.status(500).json({

            success: false,

            message: "Internal Server Error"

        });

    }

};

/*
=========================================
    Customer Details
=========================================
*/
const getCustomer = async (req, res) => {

    try {

        const { customer_id } = req.params;

        const customer =
            await customerService.getCustomer(customer_id);

        if (!customer) {

            return res.status(404).json({

                success: false,

                message: "Customer not found"

            });

        }

        return res.status(200).json({

            success: true,

            data: customer

        });

    }

    catch (error) {

        console.error(error);

        return res.status(500).json({

            success: false,

            message: "Internal Server Error"

        });

    }

};

/*
=========================================
    Customer Details - Update Status
=========================================
*/
const updateCustomerStatus = async (

    req,

    res

) => {

    try {

        const { customer_id } = req.params;

        const { is_blocked } = req.body;

        const customer =
            await customerService.updateCustomerStatus(

                customer_id,

                is_blocked

            );

        return res.status(200).json({

            success: true,

            message: "Customer status updated successfully",

            data: customer

        });

    }

    catch (error) {

        console.error(error);

        return res.status(500).json({

            success: false,

            message: "Internal Server Error"

        });

    }

};

/*--- EXPORT ---*/
module.exports = {
    getDashboard,
    getCustomers,
    getCustomer,
    updateCustomerStatus
};