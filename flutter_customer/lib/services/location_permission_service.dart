import 'package:permission_handler/permission_handler.dart';
 
class LocationPermissionService {
  static Future<bool> isLocationGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }
 
  static Future<PermissionStatus> requestLocation() async {
    return await Permission.location.request();
  }
}