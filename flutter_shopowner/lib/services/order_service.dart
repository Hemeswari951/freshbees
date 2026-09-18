import 'api_service.dart';

/// Order APIs for the shop owner app.
/// Mirrors ProductService's style: plain Map<String,dynamic> rows (no
/// model classes) since that's the convention this app already uses.
class OrderService {
  OrderService._();

  /// GET /api/shop-owner/orders?status=Pending
  /// [status] omitted -> every status ("All" tab isn't used today, but the
  /// option is there). Pass one of: Pending, Processing, Packed, Shipped,
  /// Delivered, Cancelled.
  static Future<List<Map<String, dynamic>>> getOrders({String? status}) async {
    final query = (status != null && status.isNotEmpty) ? '?status=$status' : '';
    final response = await ApiService.get('/orders$query');

    final List list = response['data'] as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// GET /api/shop-owner/orders/:orderId
  /// Returns THIS shop's item(s) within that order — a multi-vendor order
  /// may have other shops' items too, those are simply not included.
  static Future<List<Map<String, dynamic>>> getOrderById(int orderId) async {
    final response = await ApiService.get('/orders/$orderId');

    final List list = response['data'] as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// PATCH /api/shop-owner/orders/:orderItemId/confirm  — Pending -> Processing
  static Future<void> confirmOrder(int orderItemId) async {
    await ApiService.patch('/orders/$orderItemId/confirm', {});
  }

  /// PATCH /api/shop-owner/orders/:orderItemId/cancel  — Pending -> Cancelled
  /// [reason] is one of the fixed dropdown reasons, or 'Other' with
  /// [customReason] filled in from the text field.
  static Future<void> cancelOrder(
    int orderItemId, {
    required String reason,
    String? customReason,
  }) async {
    await ApiService.patch('/orders/$orderItemId/cancel', {
      'reason': reason,
      if (customReason != null) 'customReason': customReason,
    });
  }

  /// PATCH /api/shop-owner/orders/:orderItemId/packed
  static Future<void> markPacked(int orderItemId) async {
    await ApiService.patch('/orders/$orderItemId/packed', {});
  }

  /// PATCH /api/shop-owner/orders/:orderItemId/shipped
  static Future<void> markShipped(int orderItemId) async {
    await ApiService.patch('/orders/$orderItemId/shipped', {});
  }

  /// PATCH /api/shop-owner/orders/:orderItemId/delivered
  static Future<void> markDelivered(int orderItemId) async {
    await ApiService.patch('/orders/$orderItemId/delivered', {});
  }
}

/// The 7 fixed cancellation reasons from the spec — "Other" reveals a free
/// text field in the UI.
const List<String> cancellationReasons = [
  'Out of Stock',
  'Product Unavailable',
  'Unable to Fulfill Order',
  'Product Quality Issue',
  'Incorrect Product Information',
  'Shop Unavailable',
  'Other',
];
