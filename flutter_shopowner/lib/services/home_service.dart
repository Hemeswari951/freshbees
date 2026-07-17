import '../models/home_data.dart';
import 'api_service.dart';

class HomeService {
  Future<HomeData> getHome() async {
    final data = await ApiService.get('/home');
    return HomeData.fromJson(data['data']);
  }
}