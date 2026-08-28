import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_colors.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService();

  bool isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscure = true;
  bool rememberMe = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),

            child: Form(
              key: _formKey,

              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),

                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [
                        //-----------------------------------
                        // LOGO
                        //-----------------------------------
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(24),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .05),

                                  blurRadius: 20,

                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),

                            child: Padding(
                              padding: const EdgeInsets.all(12),

                              child: Image.asset("assets/images/logo.jpeg"),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        //-----------------------------------
                        // TITLE
                        //-----------------------------------
                      
                        const Center(
                          child: Text(
                            "Sign in to Manage your Shop",

                            style: TextStyle(color: AppColors.brown),
                          ),
                        ),

                        const SizedBox(height: 35),

                        //-----------------------------------
                        // USERNAME
                        //-----------------------------------
                        TextFormField(
                          controller: emailController,

                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Enter Email";
                            }

                            return null;
                          },

                          decoration: const InputDecoration(
                            labelText: "Email",

                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),

                        const SizedBox(height: 20),

                        //-----------------------------------
                        // PASSWORD
                        //-----------------------------------
                        TextFormField(
                          controller: passwordController,

                          obscureText: obscure,

                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter password";
                            }

                            return null;
                          },

                          decoration: InputDecoration(
                            labelText: "Password",

                            prefixIcon: const Icon(Icons.lock_outline),

                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscure = !obscure;
                                });
                              },

                              icon: Icon(
                                obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        //-----------------------------------
                        // REMEMBER
                        //-----------------------------------
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,

                              activeColor: AppColors.brown,

                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value!;
                                });
                              },
                            ),

                            const Text("Remember Me"),

                            const Spacer(),

                            TextButton(
                              onPressed: () {
                                context.go('/forgot-password');
                              },
                              child: const Text("Forgot Password?"),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        //-----------------------------------
                        // LOGIN
                        //-----------------------------------
                        SizedBox(
                          height: 56,

                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }

                                    setState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      final response = await _authService.login(
                                        email: emailController.text.trim(),
                                        password: passwordController.text,
                                      );

                                      if (!mounted) return;
                                      if (response.firstLogin) {
                                        print("OwnerId = ${response.ownerId}");
                                        context.go(
                                          '/reset-password',
                                          extra: response.ownerId,
                                        );
                                      } else {
                                        context.go('/home');
                                      }
                                    } catch (e) {
                                      if (!mounted) return;

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    }
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "LOGIN",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 30),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
