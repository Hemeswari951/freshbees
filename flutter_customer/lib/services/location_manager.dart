import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api_service.dart';
import 'address_service.dart';
import 'location_permission_service.dart';
import 'location_service.dart';

/// Single source of truth for delivery location across the app.
///
/// Handles:
/// - Current GPS location
/// - Saved addresses
/// - Default address
/// - User latitude / longitude
/// - Login/logout location refresh
/// - LocationBar synchronization
/// - Location change notifications
///
/// Selected location is represented by:
///
///   location   -> human-readable display text
///   latitude   -> selected latitude
///   longitude  -> selected longitude
///
/// Coordinates are later sent to the backend to find nearest shops/products.
class LocationManager extends ChangeNotifier {
  // ===========================================================================
  // SINGLETON
  // ===========================================================================

  LocationManager._internal();

  static final LocationManager _instance =
      LocationManager._internal();

  factory LocationManager() => _instance;

  // ===========================================================================
  // STATE
  // ===========================================================================

  /// Display text shown in LocationBar.
  ///
  /// Examples:
  ///
  /// Pochampalli, Krishnagiri, Tamil Nadu
  /// Chennai, Tamil Nadu
  /// Bengaluru, Karnataka
  String? location;

  /// Currently selected delivery latitude.
  double? latitude;

  /// Currently selected delivery longitude.
  double? longitude;

  /// Loading state.
  bool isLoading = true;

  /// Currently selected/default saved address.
  AddressModel? defaultAddress;

  /// All saved addresses for logged-in user.
  List<AddressModel> savedAddresses = [];

  /// Prevents unnecessary loading on every screen.
  bool _hasLoadedOnce = false;

  /// Login state from the last successful location load.
  ///
  /// Used to detect:
  ///
  /// logged out -> logged in
  /// logged in  -> logged out
  bool? _lastLoginState;

  /// Increments ONLY when the actual selected location changes.
  ///
  /// Screens can use this to determine whether they need to reload their
  /// location-dependent data.
  int _locationVersion = 0;

  /// Public read-only location version.
  int get locationVersion => _locationVersion;

  // ===========================================================================
  // LOGIN STATE
  // ===========================================================================

  bool get isLoggedIn {
    final token = ApiService.getToken();

    return token != null && token.isNotEmpty;
  }

  // ===========================================================================
  // SPLASH INITIALIZATION
  // ===========================================================================

  /// Initializes location during splash.
  ///
  /// Flow:
  ///
  /// 1. Check location permission.
  /// 2. Request permission if required.
  /// 3. Try saved default address when logged in.
  /// 4. Otherwise try GPS.
  /// 5. If permission is denied, app continues without location.
  ///
  /// IMPORTANT:
  ///
  /// If the user denies location permission during splash,
  /// LocationBar can call useCurrentLocation() later and request permission
  /// again.
  Future<void> initializeAtSplash() async {
    try {
      debugPrint(
        'LocationManager: Initializing location at splash...',
      );

      final granted =
          await LocationPermissionService.isLocationGranted();

      if (!granted) {
        debugPrint(
          'LocationManager: Location permission not granted at splash.',
        );

        // Try requesting once.
        //
        // If user denies it, we DO NOT block the app.
        await LocationPermissionService.requestLocation();
      }

      await loadHomeLocation();
    } catch (e) {
      debugPrint(
        'LocationManager.initializeAtSplash error: $e',
      );

      isLoading = false;

      _hasLoadedOnce = true;

      _lastLoginState = isLoggedIn;

      notifyListeners();
    }
  }

  // ===========================================================================
  // MAIN LOCATION LOADER
  // ===========================================================================

  /// Loads the best available delivery location.
  ///
  /// Priority:
  ///
  /// 1. Logged-in user's default saved address
  /// 2. Current GPS location
  /// 3. No location
  ///
  /// [silent] = true means no loading state notification before loading.
  Future<void> loadHomeLocation({
    bool silent = false,
  }) async {
    if (!silent) {
      isLoading = true;
      notifyListeners();
    }

    try {
      final currentlyLoggedIn = isLoggedIn;

      debugPrint(
        'LocationManager: isLoggedIn = $currentlyLoggedIn',
      );

      // =======================================================================
      // LOGGED-IN USER
      // =======================================================================

      if (currentlyLoggedIn) {
        try {
          debugPrint(
            'LocationManager: Loading saved addresses...',
          );

          final addresses =
              await AddressService.getAddresses();

          debugPrint(
            'LocationManager: Loaded '
            '${addresses.length} addresses',
          );

          savedAddresses = addresses;

          // -------------------------------------------------------------------
          // Find default address
          // -------------------------------------------------------------------

          AddressModel? found;

          for (final address in addresses) {
            if (address.isDefault) {
              found = address;
              break;
            }
          }

          // -------------------------------------------------------------------
          // Default address found
          // -------------------------------------------------------------------

          if (found != null) {
            debugPrint(
              'LocationManager: Default saved address found.',
            );

            _setSelectedLocation(
              location: _displayFor(found),
              latitude: found.latitude,
              longitude: found.longitude,
              address: found,
            );

            return;
          }

          // -------------------------------------------------------------------
          // Logged in but no default address
          // -------------------------------------------------------------------

          defaultAddress = null;

          debugPrint(
            'LocationManager: No default address found.',
          );
        } catch (e) {
          debugPrint(
            'LocationManager: Address API failed: $e',
          );

          // Do NOT clear previously loaded addresses/location.
          //
          // Continue and try GPS.
        }
      } else {
        // =====================================================================
        // LOGGED OUT
        // =====================================================================

        debugPrint(
          'LocationManager: User is logged out.',
        );

        // Account-specific data must be cleared.
        savedAddresses = [];
        defaultAddress = null;
      }

      // =========================================================================
      // CURRENT GPS LOCATION
      // =========================================================================

      bool permissionGranted = false;

      try {
        permissionGranted =
            await LocationPermissionService.isLocationGranted();
      } catch (e) {
        debugPrint(
          'LocationManager: Permission check failed: $e',
        );

        permissionGranted = false;
      }

      if (permissionGranted) {
        try {
          debugPrint(
            'LocationManager: Getting current GPS location...',
          );

          final current =
              await LocationService.getCurrentLocation();

          if (current != null) {
            _setSelectedLocation(
              location: current.displayName,
              latitude: current.latitude,
              longitude: current.longitude,
              address: null,
            );

            return;
          }
        } catch (e) {
          debugPrint(
            'LocationManager: GPS location failed: $e',
          );
        }
      } else {
        debugPrint(
          'LocationManager: Location permission is not granted.',
        );
      }

      // =========================================================================
      // NO LOCATION AVAILABLE
      // =========================================================================
      //
      // IMPORTANT:
      //
      // Do NOT put a fallback such as:
      //
      // Chennai, Tamil Nadu
      //
      // here.
      //
      // The application should simply have no selected GPS location.
      //

      _clearLocation();
    } catch (e) {
      debugPrint(
        'LocationManager.loadHomeLocation error: $e',
      );

      _clearLocation();
    } finally {
      isLoading = false;

      _hasLoadedOnce = true;

      _lastLoginState = isLoggedIn;

      notifyListeners();
    }
  }

  // ===========================================================================
  // ENSURE LOADED
  // ===========================================================================

  /// Ensures the latest location/address state is available.
  ///
  /// Detects:
  ///
  /// - First application load
  /// - Logged out -> logged in
  /// - Logged in -> logged out
  Future<void> ensureLoaded() async {
    final currentLoginState = isLoggedIn;

    debugPrint(
      'LocationManager.ensureLoaded: '
      'currentLoginState=$currentLoginState, '
      'lastLoginState=$_lastLoginState, '
      'hasLoaded=$_hasLoadedOnce',
    );

    // -------------------------------------------------------------------------
    // First load
    // -------------------------------------------------------------------------

    if (!_hasLoadedOnce) {
      await loadHomeLocation();
      return;
    }

    // -------------------------------------------------------------------------
    // Login/logout state changed
    // -------------------------------------------------------------------------

    if (_lastLoginState != currentLoginState) {
      debugPrint(
        'LocationManager: Authentication state changed. '
        'Reloading location/address...',
      );

      await loadHomeLocation(
        silent: true,
      );

      return;
    }
  }

  // ===========================================================================
  // FORCE REFRESH AFTER LOGIN
  // ===========================================================================

  /// Call this after successful login.
  ///
  /// IMPORTANT:
  ///
  /// Token must already be stored in ApiService before calling this.
  Future<void> refreshAfterLogin() async {
    if (!isLoggedIn) {
      debugPrint(
        'LocationManager.refreshAfterLogin: '
        'User is not logged in.',
      );

      return;
    }

    debugPrint(
      'LocationManager: Refreshing after login...',
    );

    await loadHomeLocation(
      silent: true,
    );
  }

  // ===========================================================================
  // FORCE ADDRESS REFRESH
  // ===========================================================================

  /// Call this after:
  ///
  /// - Add address
  /// - Edit address
  /// - Delete address
  /// - Change default address
  Future<void> refreshAddresses() async {
    if (!isLoggedIn) {
      debugPrint(
        'LocationManager.refreshAddresses: '
        'User is not logged in.',
      );

      return;
    }

    debugPrint(
      'LocationManager: Refreshing saved addresses...',
    );

    await loadHomeLocation(
      silent: true,
    );
  }

  // ===========================================================================
  // USE CURRENT LOCATION
  // ===========================================================================

  /// Explicitly selects the user's current GPS location.
  ///
  /// This is the method LocationBar should call when the user taps
  /// "Use current location".
  ///
  /// IMPORTANT:
  ///
  /// Permission is checked HERE again.
  ///
  /// Therefore:
  ///
  /// First visit:
  ///     User -> Never Allow
  ///
  /// Later:
  ///     User taps LocationBar
  ///         -> permission checked/requested again
  ///         -> GPS fetched if allowed
  Future<void> useCurrentLocation() async {
    debugPrint(
      'LocationManager: User requested current location.',
    );

    isLoading = true;

    notifyListeners();

    try {
      // =========================================================================
      // CHECK CURRENT PERMISSION
      // =========================================================================

      final alreadyGranted =
          await LocationPermissionService.isLocationGranted();

      // =========================================================================
      // REQUEST AGAIN IF NOT GRANTED
      // =========================================================================

      if (!alreadyGranted) {
        debugPrint(
          'LocationManager: Requesting location permission again...',
        );

        final status =
            await LocationPermissionService.requestLocation();

        if (!status.isGranted) {
          debugPrint(
            'LocationManager: Location permission denied.',
          );

          return;
        }
      }

      // =========================================================================
      // FETCH CURRENT GPS LOCATION
      // =========================================================================

      debugPrint(
        'LocationManager: Fetching current GPS location...',
      );

      final current =
          await LocationService.getCurrentLocation();

      if (current == null) {
        debugPrint(
          'LocationManager: Could not determine current location.',
        );

        return;
      }

      // =========================================================================
      // UPDATE LOCATION
      // =========================================================================

      _setSelectedLocation(
        location: current.displayName,
        latitude: current.latitude,
        longitude: current.longitude,
        address: null,
      );

      debugPrint(
        'LocationManager: Current location selected = '
        '$location',
      );

      debugPrint(
        'LocationManager: Latitude = '
        '$latitude',
      );

      debugPrint(
        'LocationManager: Longitude = '
        '$longitude',
      );
    } catch (e) {
      debugPrint(
        'LocationManager.useCurrentLocation error: $e',
      );

      // Keep previous location if GPS fails.
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  // ===========================================================================
  // USE SAVED ADDRESS
  // ===========================================================================

  /// Selects a saved address as the current delivery location.
  ///
  /// The selected address's latitude/longitude are used for nearest-shop
  /// calculations.
  void useAddress(
    AddressModel address,
  ) {
    debugPrint(
      'LocationManager: Selecting saved address...',
    );

    _setSelectedLocation(
      location: _displayFor(address),
      latitude: address.latitude,
      longitude: address.longitude,
      address: address,
    );

    debugPrint(
      'LocationManager: Address selected = '
      '$location',
    );

    debugPrint(
      'LocationManager: Address latitude = '
      '$latitude',
    );

    debugPrint(
      'LocationManager: Address longitude = '
      '$longitude',
    );

    notifyListeners();
  }

  // ===========================================================================
  // SET SELECTED LOCATION
  // ===========================================================================

  /// Updates the selected location.
  ///
  /// [location] can be null if reverse geocoding fails.
  ///
  /// Even when displayName is null, latitude/longitude are still preserved.
  ///
  /// This is important because backend distance calculations should still
  /// work even if a human-readable address cannot be generated.
  void _setSelectedLocation({
    required String? location,
    required double? latitude,
    required double? longitude,
    required AddressModel? address,
  }) {
    final locationChanged =
        this.location != location ||
        this.latitude != latitude ||
        this.longitude != longitude ||
        defaultAddress != address;

    this.location = location;

    this.latitude = latitude;

    this.longitude = longitude;

    defaultAddress = address;

    // Only increment when actual selected location changes.
    if (locationChanged) {
      _locationVersion++;

      debugPrint(
        'LocationManager: LOCATION CHANGED '
        '(version=$_locationVersion)',
      );
    }
  }

  // ===========================================================================
  // CLEAR LOCATION
  // ===========================================================================

  void _clearLocation() {
    final hadLocation =
        location != null ||
        latitude != null ||
        longitude != null ||
        defaultAddress != null;

    defaultAddress = null;

    location = null;

    latitude = null;

    longitude = null;

    if (hadLocation) {
      _locationVersion++;

      debugPrint(
        'LocationManager: Location cleared '
        '(version=$_locationVersion)',
      );
    }
  }

  // ===========================================================================
  // DISPLAY ADDRESS
  // ===========================================================================

  /// Converts a saved address into a readable LocationBar string.
  ///
  /// Priority:
  ///
  /// City + State
  /// City
  /// State
  /// Address Line 1
  /// Delivery location
  String _displayFor(
    AddressModel address,
  ) {
    final city = address.city.trim();
    final state = address.state.trim();
    final addressLine1 =
        address.addressLine1.trim();

    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city, $state';
    }

    if (city.isNotEmpty) {
      return city;
    }

    if (state.isNotEmpty) {
      return state;
    }

    if (addressLine1.isNotEmpty) {
      return addressLine1;
    }

    return 'Delivery location';
  }
}