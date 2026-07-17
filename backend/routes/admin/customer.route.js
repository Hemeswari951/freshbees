const express = require("express");

const router = express.Router();

const customersController =
    require("../../controllers/admin/customer.controller");

router.get(

    "/dashboard",

    customersController.getDashboard

);

router.get(
    "/",
    customersController.getCustomers
);
/*
This route will be used in many areas - 
        These are all different ways of viewing the same customer list
            For example:
                Total Customers → show all customers
                New Customers Today → show only today's customers
                Blocked Customers → show only blocked customers
                Search → show matching customers
                City Filter → show customers from a city
                Status Filter → show blocked/unblocked customers

    (Production approach) - Extra conditions are sent in the URL.
        GET /api/admin/customers?type=blocked
        GET /api/admin/customers?type=today
        GET /api/admin/customers?search=ayesha
        GET /api/admin/customers?city=Mumbai
        GET /api/admin/customers?status=blocked
*/


router.get(

    "/:customer_id",

    customersController.getCustomer

);

router.patch(

    "/:customer_id/status",

    customersController.updateCustomerStatus

);

module.exports = router;