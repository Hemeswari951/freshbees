import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../widgets/t_colors.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "User";
  String _identifier = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final name1 = prefs.getString('userName');
    final name2 = prefs.getString('user_name');
    final resolvedName = (name1 != null && name1.isNotEmpty)
        ? name1
        : ((name2 != null && name2.isNotEmpty) ? name2 : 'User');

    setState(() {
      _userName = resolvedName;
      _identifier = prefs.getString('loginIdentifier') ?? '';
    });
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);

    await AuthService.logout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.cream,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: TColors.brown,
        foregroundColor: TColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: TColors.gold,
              child: Icon(Icons.person, size: 60, color: TColors.white),
            ),
            const SizedBox(height: 15),
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: TColors.textDark,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _identifier,
              style: const TextStyle(fontSize: 14, color: TColors.textGrey),
            ),
            const SizedBox(height: 40),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.shopping_bag_outlined,
                      color: TColors.brown,
                    ),
                    title: const Text('My Orders'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: TColors.brown,
                    ),
                    title: const Text('Saved Addresses'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.settings_outlined,
                      color: TColors.brown,
                    ),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.red,
                  foregroundColor: TColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.logout),
                label: _isLoading
                    ? const CircularProgressIndicator(color: TColors.white)
                    : const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
