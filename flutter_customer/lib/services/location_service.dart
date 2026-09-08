import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart' as geocoding;

/// Result of a GPS lookup.
class LocationResult {
  final double latitude;
  final double longitude;
  final String? displayName;

  LocationResult({
    required this.latitude,
    required this.longitude,
    this.displayName,
  });
}

class LocationService {
  // ===========================================================================
  // GET CURRENT LOCATION
  // ===========================================================================

  static Future<LocationResult?> getCurrentLocation() async {
    try {
      // -----------------------------------------------------------------------
      // Check location service on native platforms.
      // -----------------------------------------------------------------------

      if (!kIsWeb) {
        final serviceEnabled =
            await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          debugPrint(
            'LocationService: Location service disabled.',
          );

          return null;
        }
      }

      // -----------------------------------------------------------------------
      // Get current GPS position.
      //
      // On Web, this is where Chrome / Edge browser geolocation is actually
      // used.
      // -----------------------------------------------------------------------

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final latitude = position.latitude;
      final longitude = position.longitude;

      debugPrint(
        'LocationService: GPS latitude = $latitude',
      );

      debugPrint(
        'LocationService: GPS longitude = $longitude',
      );

      // -----------------------------------------------------------------------
      // Reverse geocoding
      // -----------------------------------------------------------------------

      String? displayName;

      if (kIsWeb) {
        displayName =
            await _reverseGeocodeWeb(
          latitude,
          longitude,
        );
      } else {
        displayName =
            await _reverseGeocodeNative(
          latitude,
          longitude,
        );
      }

      debugPrint(
        'LocationService: displayName = $displayName',
      );

      return LocationResult(
        latitude: latitude,
        longitude: longitude,
        displayName: displayName,
      );
    } catch (e) {
      debugPrint(
        'LocationService.getCurrentLocation error: $e',
      );

      return null;
    }
  }

  // ===========================================================================
  // NATIVE REVERSE GEOCODING
  // ===========================================================================

  static Future<String?> _reverseGeocodeNative(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks =
          await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return null;
      }

      final place = placemarks.first;

      final parts = <String>[];

      void addPart(String? value) {
        if (value == null) return;

        final cleaned = value.trim();

        if (cleaned.isEmpty) return;

        if (!parts.contains(cleaned)) {
          parts.add(cleaned);
        }
      }

      // -----------------------------------------------------------------------
      // Detailed location hierarchy
      // -----------------------------------------------------------------------

      addPart(place.name);
      addPart(place.street);
      addPart(place.subLocality);
      addPart(place.locality);
      addPart(place.subAdministrativeArea);
      addPart(place.administrativeArea);
      addPart(place.postalCode);

      if (parts.isEmpty) {
        return null;
      }

      return parts.join(', ');
    } catch (e) {
      debugPrint(
        'LocationService native reverse geocode error: $e',
      );

      return null;
    }
  }

  // ===========================================================================
  // WEB REVERSE GEOCODING
  // ===========================================================================

  static Future<String?> _reverseGeocodeWeb(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'format': 'json',
          'lat': latitude.toString(),
          'lon': longitude.toString(),

          // Higher zoom gives more detailed address information.
          'zoom': '18',

          'addressdetails': '1',

          'accept-language': 'en',
        },
      );

      final response = await http.get(
        uri,
        headers: const {
          'User-Agent':
              'THIRAA Customer App/1.0',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'LocationService: Nominatim status '
          '${response.statusCode}',
        );

        return null;
      }

      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final address =
          data['address']
              as Map<String, dynamic>?;

      if (address == null) {
        return null;
      }

      final parts = <String>[];

      void addPart(dynamic value) {
        if (value == null) return;

        final cleaned =
            value.toString().trim();

        if (cleaned.isEmpty) return;

        if (!parts.contains(cleaned)) {
          parts.add(cleaned);
        }
      }

      // -----------------------------------------------------------------------
      // Detailed address
      // -----------------------------------------------------------------------

      // House / building
      addPart(address['house_number']);

      // Street / road
      addPart(address['road']);

      // Local area
      addPart(
        address['neighbourhood'] ??
            address['suburb'] ??
            address['quarter'],
      );

      // Village / town / city
      addPart(
        address['village'] ??
            address['town'] ??
            address['city'] ??
            address['municipality'],
      );

      // District
      addPart(
        address['county'] ??
            address['district'],
      );

      // State
      addPart(address['state']);

      // PIN
      addPart(address['postcode']);

      // Country
      addPart(address['country']);

      if (parts.isEmpty) {
        return null;
      }

      return parts.join(', ');
    } catch (e) {
      debugPrint(
        'LocationService web reverse geocode error: $e',
      );

      return null;
    }
  }
}