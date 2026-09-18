import 'package:flutter/material.dart';

import './app_colors.dart';
import './customer_footer.dart';
import './customer_header.dart';

class CustomerLayout extends StatelessWidget {
  final String currentPath;
  final Widget child;
  final bool showFooterOnMobile;

  /// Forwarded to CustomerHeader — controls the mic/camera icons in the
  /// desktop search bar. Defaults to true; app_router.dart sets this to
  /// false for Profile/Wishlist/Cart.
  final bool showVoiceAndCameraSearch;

  const CustomerLayout({
    super.key,
    required this.currentPath,
    required this.child,
    this.showFooterOnMobile = true,
    this.showVoiceAndCameraSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final showFooter = isDesktop || showFooterOnMobile;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.cream,

      body: SafeArea(
        child: isDesktop
            ? Column(
                children: [
                  CustomerHeader(
                    showVoiceAndCameraSearch: showVoiceAndCameraSearch,
                  ),

                  Expanded(child: child),
                ],
              )
            : Column(children: [Expanded(child: child)]),
      ),

      bottomNavigationBar: isDesktop
          ? null
          : (showFooter ? CustomerFooter(currentPath: currentPath) : null),
    );
  }
}