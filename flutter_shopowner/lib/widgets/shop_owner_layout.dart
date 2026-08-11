import 'package:flutter/material.dart';

import './app_colors.dart';
import './shop_owner_footer.dart';
import './shop_owner_header.dart';
import './shop_owner_sidebar.dart';

class ShopOwnerLayout extends StatelessWidget {
  final String currentPath;
  final Widget child;
  final bool showFooterOnMobile;

  const ShopOwnerLayout({
    super.key,
    required this.currentPath,
    required this.child,
    this.showFooterOnMobile = true,
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
                  const ShopOwnerHeader(),
                  Expanded(
                    child: Row(
                      children: [
                        ShopOwnerSidebar(currentPath: currentPath),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(child: child),
                ],
              ),
      ),

      bottomNavigationBar: isDesktop
          ? null
          : (showFooter ? ShopOwnerFooter(currentPath: currentPath) : null),
    );
  }
}