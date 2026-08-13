import 'package:flutter/material.dart';
 
import 'widgets/t_colors.dart';
import './services/api_service.dart';
import 'routing/app_router.dart';
 
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  await ApiService.loadToken();
 
  runApp(const ThiraaAdmin());
}
 
class ThiraaAdmin extends StatelessWidget {
  const ThiraaAdmin({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'THIRAA Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: TColors.cream,
        fontFamily: 'Inter',
      ),
      routerConfig: appRouter,
    );
  }
}