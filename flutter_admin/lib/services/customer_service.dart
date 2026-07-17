import '../models/customer_model.dart';
import 'api_service.dart';

class CustomerService {
  /// ============================================================
  /// Dashboard
  /// GET /customers/dashboard
  /// ============================================================
  static Future<DashboardStats> getDashboard() async {
    final data = await ApiService.get('/customers/dashboard');

    if (data['success'] == true) {
      return DashboardStats.fromJson(data['data']);
    }

    throw Exception(data['message'] ?? 'Failed to load dashboard');
  }

  /// ============================================================
  /// Customer List
  /// GET /customers
  /// ============================================================
  static Future<List<Customer>> getCustomers({
    String? type,
    String? search,
    String? city,
    String? status,
  }) async {
    final query = <String, String>{};

    if (type != null && type.isNotEmpty) {
      query['type'] = type;
    }

    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    if (city != null && city.isNotEmpty) {
      query['city'] = city;
    }

    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }

    String endpoint = '/customers';

    if (query.isNotEmpty) {
      endpoint += '?${Uri(queryParameters: query).query}';
    }

    final data = await ApiService.get(endpoint);

    if (data['success'] == true) {
      final List list = data['data'];

      return list
          .map((e) => Customer.fromJson(e))
          .toList();
    }

    throw Exception(data['message'] ?? 'Failed to load customers');
  }

  /// ============================================================
  /// Customer Details
  /// GET /customers/:id
  /// ============================================================
  static Future<Customer> getCustomerById(int customerId) async {
    final data = await ApiService.get('/customers/$customerId');

    if (data['success'] == true) {
      return Customer.fromJson(data['data']);
    }

    throw Exception(data['message'] ?? 'Customer not found');
  }

  /// ============================================================
  /// Block / Unblock Customer
  /// PATCH /customers/:id/status
  /// ============================================================
  static Future<Customer> updateCustomerStatus(
    int customerId,
    bool isBlocked,
  ) async {
    final data = await ApiService.patch(
      '/customers/$customerId/status',
      {
        'is_blocked': isBlocked,
      },
    );

    if (data['success'] == true) {
      return Customer.fromJson(data['data']);
    }

    throw Exception(data['message'] ?? 'Failed to update customer status');
  }
}