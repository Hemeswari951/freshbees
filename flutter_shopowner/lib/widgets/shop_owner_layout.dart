import 'package:flutter/material.dart';

import './app_colors.dart';
import './shop_owner_footer.dart';
import './shop_owner_header.dart';
import './shop_owner_sidebar.dart';

class ShopOwnerLayout extends StatelessWidget {
  final String currentPath;
  final Widget child;

  const ShopOwnerLayout({
    super.key,
    required this.currentPath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

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
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  const ShopOwnerHeader(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: child,
                    ),
                  ),
                ],
              ),
      ),

      bottomNavigationBar: isDesktop
          ? null
          : ShopOwnerFooter(currentPath: currentPath),
    );
  }
}
