import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final int? ownerId;
  final String? email;

  const ResetPasswordScreen({
    super.key,
    this.ownerId,
    this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await AuthService().resetPassword(
        ownerId: widget.ownerId,
        email: widget.email,
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password changed successfully"),
        ),
      );

      context.go("/login");
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

    return Scaffold(
      body: Stack(
        children: [
          /// Background
          Positioned.fill(
            child: Image.asset(
              "assets/images/forgot.jpeg",
              fit: BoxFit.cover,
            ),
          ),

          /// Light Overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(.18),
            ),
          ),

          /// Main Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: isMobile ? double.infinity : 560,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 45,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.97),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.12),
                      blurRadius: 35,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// Logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xffB85A2E),
                                  Color(0xffD68447),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                "T",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          const Text(
                            "THIRAA",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 42),

                      const Text(
                        "Reset Your Password",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "Your identity has been verified.\nPlease set your new password below.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 19,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 35),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "New Password",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 21,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        controller: passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Enter Password";
                          }
                          if (value.length < 8) {
                            return "Minimum 8 characters";
                          }
                          return null;
                        },
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          hintText: "New Password",
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xffB85A2E),
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Confirm Password",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 21,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        controller: confirmController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Confirm Password";
                          }
                          if (value != passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                        obscureText: hideConfirmPassword,
                        decoration: InputDecoration(
                          hintText: "Confirm Password",
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              hideConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                hideConfirmPassword = !hideConfirmPassword;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xffB85A2E),
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1E1A18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isLoading ? null : _resetPassword,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Reset Password",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}