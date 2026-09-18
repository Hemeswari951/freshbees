import 'package:flutter/material.dart'; 
import 'widgets/app_colors.dart';
import './services/api_service.dart';
import 'routing/app_router.dart';
 
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  await ApiService.loadToken();
 
  runApp(const ThiraaCustomer());
}
 
class ThiraaCustomer extends StatelessWidget {
  const ThiraaCustomer({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'THIRAA Customer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        fontFamily: 'Inter',
      ),
      routerConfig: appRouter,
    );
  }
}