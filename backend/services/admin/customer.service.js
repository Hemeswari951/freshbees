/*--- Heart of the backend - Service combines everything ---*/
const customerModel = require("../../models/admin/customer.model");

/*
=========================================
Admin's Customer Dashboard Service
=========================================
*/
const getDashboard = async () => {

    const totalCustomers =
        await customerModel.countCustomers();

    const todayCustomers =
        await customerModel.countTodayCustomers();

    const blockedCustomers =
        await customerModel.countBlockedCustomers();

    return {

        totalCustomers:
            Number(totalCustomers.total),

        newCustomersToday:
            Number(todayCustomers.total),

        blockedCustomers:
            Number(blockedCustomers.total)

    };

};

/*
=========================================
    Customer List
=========================================
*/
const getCustomers = async (filters) => {

    return await customerModel.getCustomers(filters);

};

/*
=========================================
    Customer Details
=========================================
*/
const getCustomer = async (customerId) => {

    return await customerModel.getCustomerById(customerId);

};

/*
=========================================
    Customer Details - Update Status
=========================================
*/
const updateCustomerStatus = async (

    customerId,

    status

) => {

    return await customerModel.updateCustomerStatus(

        customerId,

        status

    );

};

/*--- EXPORT ---*/
module.exports = {
    getDashboard,
    getCustomers,
    getCustomer,
    updateCustomerStatus
};