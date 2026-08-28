import '../models/create_admin.dart';
import 'api_service.dart';

class DashboardService {

  Future<Map<String, dynamic>> getDashboardData() async {
    return await ApiService.get('/dashboard');
  }
  
  Future<Map<String, dynamic>> createAdmin(CreateAdmin admin) async {
    return await ApiService.post('/dashboard/create-admin', admin.toJson());
  }
}
