import 'dart:async';
 
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
 
import '../services/location_permission_service.dart';
 
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
 
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
 
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
 
  @override
  void initState() {
    super.initState();
 
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
 
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.15,
        ).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
        weight: 30,
      ),
    ]).animate(_controller);
 
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
 
    _controller.forward();
 
    _navigate();
  }
 
  Future<void> _navigate() async {
  await Future.delayed(const Duration(seconds: 3));
 
  if (!mounted) return;
 
  final status =
      await LocationPermissionService.requestLocation();
 
  if (status.isGranted) {
    context.go('/home');
    return;
  }
 
  final enableLocation = await _showPermissionDialog();
 
  if (!mounted) return;
 
  if (enableLocation) {
    final retryStatus =
        await LocationPermissionService.requestLocation();
 
    if (retryStatus.isPermanentlyDenied) {
      await _showSettingsDialog();
    }
  }
 
  if (!mounted) return;
 
  // User can continue even without location
  context.go('/home');
}
 
  Future<bool> _showPermissionDialog() async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            title: const Text('Location Access'),
            content: const Text(
              'Enable location to discover fashion stores near you.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Allow Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Enable Location'),
              ),
            ],
          );
        },
      ) ??
      false;
}
 
  Future<void> _showSettingsDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission has been permanently denied. Please enable it from App Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
 
    // Give user time to return from settings
    await Future.delayed(const Duration(seconds: 1));
  }
 
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F5F1),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 220,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Discover Fashion Near You",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 