import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/location_manager.dart';
import '../services/location_permission_service.dart';

class LocationBar extends StatefulWidget {
  const LocationBar({super.key});

  @override
  State<LocationBar> createState() => _LocationBarState();
}

class _LocationBarState extends State<LocationBar> {
  final LocationManager _manager = LocationManager();

  @override
  void initState() {
    super.initState();

    // Initial load.
    _manager.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        return InkWell(
          // ===================================================================
          // IMPORTANT FIX
          // ===================================================================
          //
          // LocationBar may already exist when the user logs in.
          //
          // Therefore initState() will NOT run again.
          //
          // Before opening the selector, check login state and refresh
          // saved addresses if authentication changed.
          //
          // ALSO: check location permission status.
          //
          // If permission is already granted -> just continue (refresh
          // silently), no need to interrupt the user with the selector
          // popup.
          //
          // If permission is NOT granted -> show the selector popup again
          // so the user can pick manually or trigger "Use current
          // location" (which will re-request permission).
          //
          onTap: () async {
            final permissionGranted =
                await LocationPermissionService.isLocationGranted();

            await _manager.ensureLoaded();

            if (!context.mounted) return;

            // -----------------------------------------------------------
            // PERMISSION ALREADY GRANTED
            // -----------------------------------------------------------

            if (permissionGranted) {
              // Edge case: permission granted but no location yet
              // (e.g. GPS fetch failed earlier). Fall back to showing
              // the selector so the user isn't stuck with nothing.
              if (_manager.location == null && !_manager.isLoading) {
                _showLocationSelector(context, _manager);
              }

            
            }

            // -----------------------------------------------------------
            // PERMISSION NOT GRANTED
            // -----------------------------------------------------------

            _showLocationSelector(context, _manager);
          },

          borderRadius: BorderRadius.circular(6),

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // =============================================================
                // LOCATION ICON
                // =============================================================

                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Color(0xFF8B7355),
                ),

                const SizedBox(width: 4),

                // =============================================================
                // LOCATION TEXT
                // =============================================================
                Flexible(
                  child: Text(
                    _manager.isLoading
                        ? 'Getting location...'
                        : (_manager.location ?? 'Add delivery location'),

                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _manager.location == null
                          ? Colors.black54
                          : Colors.black87,
                    ),

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 2),

                // =============================================================
                // DROPDOWN ICON
                // =============================================================
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // LOCATION SELECTOR
  // ===========================================================================

  void _showLocationSelector(BuildContext context, LocationManager manager) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      // =======================================================================
      // DESKTOP DIALOG
      // =======================================================================

      showDialog(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),

            backgroundColor: Colors.white,

            surfaceTintColor: Colors.transparent,

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),

              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildLocationContent(context, dialogContext, manager),
              ),
            ),
          );
        },
      );
    } else {
      // =======================================================================
      // MOBILE BOTTOM SHEET
      // =======================================================================

      showModalBottomSheet(
        context: context,

        backgroundColor: Colors.transparent,

        isScrollControlled: true,

        builder: (sheetContext) {
          return SafeArea(
            child: Material(
              color: Colors.white,

              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),

              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),

                child: _buildLocationContent(context, sheetContext, manager),
              ),
            ),
          );
        },
      );
    }
  }

  // ===========================================================================
  // LOCATION CONTENT
  // ===========================================================================

  Widget _buildLocationContent(
    BuildContext rootContext,
    BuildContext modalContext,
    LocationManager manager,
  ) {
    return ListenableBuilder(
      listenable: manager,

      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // =================================================================
            // HEADER
            // =================================================================

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Select delivery address',

                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),

                MouseRegion(
                  cursor: SystemMouseCursors.click,

                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(modalContext);
                    },

                    child: Container(
                      width: 32,
                      height: 32,

                      decoration: BoxDecoration(
                        color: const Color(0xFFF2ECE4),

                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // =================================================================
            // USE CURRENT LOCATION
            // =================================================================
            _tile(
              icon: Icons.my_location,
              title: 'Use current location',
              subtitle: 'Use your device location',

              onTap: () {
                Navigator.pop(modalContext);

                manager.useCurrentLocation();
              },
            ),

            const SizedBox(height: 12),

            // =================================================================
            // LOGGED OUT
            // =================================================================
            if (!manager.isLoggedIn) _loggedOutCard(rootContext, modalContext),

            // =================================================================
            // SAVED ADDRESSES
            // =================================================================
            if (manager.isLoggedIn && manager.savedAddresses.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    'Saved addresses',

                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),

                  TextButton.icon(
                    onPressed: () {
                      _goToAddAddress(rootContext, modalContext);
                    },

                    icon: const Icon(Icons.add, size: 16),

                    label: const Text('Add new'),

                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8B7355),

                      padding: EdgeInsets.zero,

                      minimumSize: const Size(0, 0),

                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ---------------------------------------------------------------
              // ADDRESS LIST
              // ---------------------------------------------------------------
              ...manager.savedAddresses.map((address) {
                final isDefault =
                    manager.defaultAddress?.addressId == address.addressId;

                return _tile(
                  icon: Icons.home_outlined,

                  title: address.addressType.trim().isNotEmpty
                      ? address.addressType
                      : 'Address',

                  subtitle: address.oneLine,

                  trailing: isDefault
                      ? const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Color(0xFF8B7355),
                        )
                      : null,

                  onTap: () {
                    Navigator.pop(modalContext);

                    manager.useAddress(address);
                  },
                );
              }),
            ],

            // =================================================================
            // LOGGED IN BUT NO SAVED ADDRESS
            // =================================================================
            if (manager.isLoggedIn && manager.savedAddresses.isEmpty) ...[
              const SizedBox(height: 8),

              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),

                  child: OutlinedButton.icon(
                    onPressed: () {
                      _goToAddAddress(rootContext, modalContext);
                    },

                    icon: const Icon(Icons.add, size: 18),

                    label: const Text('Add new address'),

                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B7355),

                      side: const BorderSide(color: Color(0xFF8B7355)),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ===========================================================================
  // LOGGED OUT CARD
  // ===========================================================================

  Widget _loggedOutCard(BuildContext rootContext, BuildContext modalContext) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xFFF2ECE4),

        borderRadius: BorderRadius.circular(14),
      ),

      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF8B7355), size: 22),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Seems you are logged out',

                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),

                const SizedBox(height: 6),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: () {
                      // Close location modal.
                      Navigator.pop(modalContext);

                      // Preserve current route.
                      final currentRoute = GoRouterState.of(
                        rootContext,
                      ).uri.toString();

                      rootContext.push(
                        Uri(
                          path: '/login',
                          queryParameters: {'redirect': currentRoute},
                        ).toString(),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B7355),

                      foregroundColor: Colors.white,

                      padding: const EdgeInsets.symmetric(vertical: 10),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    child: const Text('Login to get your delivery address'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ADD ADDRESS
  // ===========================================================================

  void _goToAddAddress(BuildContext rootContext, BuildContext modalContext) {
    Navigator.pop(modalContext);

    rootContext.push('/add-address');
  }

  // ===========================================================================
  // COMMON TILE
  // ===========================================================================

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,

      leading: Container(
        width: 42,
        height: 42,

        decoration: BoxDecoration(
          color: const Color(0xFFF2ECE4),

          borderRadius: BorderRadius.circular(12),
        ),

        child: Icon(icon, color: const Color(0xFF8B7355)),
      ),

      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),

      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),

      trailing: trailing,

      onTap: onTap,
    );
  }
}
