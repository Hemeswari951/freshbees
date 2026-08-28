import 'package:flutter/material.dart';

import './app_colors.dart';
import './customer_footer.dart';
import './customer_header.dart';

class CustomerLayout extends StatelessWidget {
  final String currentPath;
  final Widget child;
  final bool showFooterOnMobile;

  const CustomerLayout({
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
                  const CustomerHeader(),

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