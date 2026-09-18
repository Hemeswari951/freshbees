/// Fixed platform fee shown on every order, same as Flipkart's ₹9 fee.
/// Kept as a simple constant (not a DB-driven config) since there's no
/// admin-configurable fee table in the schema yet.
const double kPlatformFee = 9.0;

/// Fixed COD handling fee, same idea as Flipkart's ₹7 "pay online to
/// avoid this fee" nudge. Only added to the total when COD is selected.
const double kCodHandlingFee = 7.0;
