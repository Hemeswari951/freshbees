import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionService {
  // ===========================================================================
  // CHECK LOCATION PERMISSION
  // ===========================================================================

  static Future<bool> isLocationGranted() async {
    // -------------------------------------------------------------------------
    // WEB
    // -------------------------------------------------------------------------
    //
    // Browser location permission must be handled by Geolocator.
    //
    // permission_handler does not reliably represent Chrome/Edge browser
    // geolocation permission.
    //
    if (kIsWeb) {
      try {
        final permission = await Geolocator.checkPermission();

        return permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
      } catch (e) {
        debugPrint('LocationPermissionService web check error: $e');

        return false;
      }
    }

    // -------------------------------------------------------------------------
    // MOBILE / DESKTOP
    // -------------------------------------------------------------------------

    try {
      final status = await Permission.location.status;

      return status.isGranted;
    } catch (e) {
      debugPrint('LocationPermissionService native check error: $e');

      return false;
    }
  }

  // ===========================================================================
  // REQUEST LOCATION PERMISSION
  // ===========================================================================

  static Future<PermissionStatus> requestLocation() async {
    // -------------------------------------------------------------------------
    // WEB
    // -------------------------------------------------------------------------
    //
    // Geolocator triggers the browser's location permission flow.
    //
    if (kIsWeb) {
      try {
        final permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          return PermissionStatus.granted;
        }

        if (permission == LocationPermission.deniedForever) {
          return PermissionStatus.permanentlyDenied;
        }

        return PermissionStatus.denied;
      } catch (e) {
        debugPrint('LocationPermissionService web request error: $e');

        return PermissionStatus.denied;
      }
    }

    // -------------------------------------------------------------------------
    // MOBILE / DESKTOP
    // -------------------------------------------------------------------------

    try {
      return await Permission.location.request();
    } catch (e) {
      debugPrint('LocationPermissionService native request error: $e');

      return PermissionStatus.denied;
    }
  }
}
