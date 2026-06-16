import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController identifierController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController otpController =
      TextEditingController();

  bool showSecondField = false;
  bool isEmailLogin = false;
  bool obscurePassword = true;

  String generatedOtp = "1234";

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void continueLogin() {
    final value = identifierController.text.trim();

    if (value.isEmpty) {
      showMessage("Enter Email or Mobile Number");
      return;
    }

    setState(() {
      if (value.contains("@")) {
        isEmailLogin = true;
      } else {
        if (value.length != 10) {
          showMessage("Enter Valid Mobile Number");
          return;
        }
        isEmailLogin = false;
      }
      showSecondField = true;
    });

    if (!isEmailLogin) {
      generatedOtp = "1234";

      showMessage(
        "OTP Sent Successfully\nUse OTP: 1234",
      );
    }
  }

  void login() {
    if (isEmailLogin) {
      if (passwordController.text.length < 6) {
        showMessage(
          "Password must be at least 6 characters",
        );
        return;
      }
    } else {
      if (otpController.text.trim() != generatedOtp) {
        showMessage("Invalid OTP");
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/fashion_bg.jpg",
              fit: BoxFit.cover,
            ),
          ),

          Container(
            color: Colors.white.withOpacity(0.78),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  Image.asset(
                    "assets/logo.png",
                    height: 110,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "VIRTUAL TRIALS, REAL YOU",
                    style: TextStyle(
                      letterSpacing: 2,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 45),

                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Sign in to continue",
                    style: TextStyle(
                      color: Colors.black.withOpacity(.6),
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 35),

                  glassField(
                    controller: identifierController,
                    hint: "Email or Mobile Number",
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 15),

                  if (showSecondField && isEmailLogin)
                    glassField(
                      controller: passwordController,
                      hint: "Password",
                      icon: Icons.lock_outline,
                      obscure: obscurePassword,
                      keyboardType: TextInputType.visiblePassword,
                      suffix: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword =
                                !obscurePassword;
                          });
                        },
                      ),
                    ),

                  if (showSecondField && !isEmailLogin)
                    glassField(
                      controller: otpController,
                      hint: "Enter OTP",
                      icon: Icons.sms_outlined,
                      keyboardType: TextInputType.number,
                    ),

                  if (showSecondField)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            showSecondField = false;
                            passwordController.clear();
                            otpController.clear();
                          });
                        },
                        child: const Text(
                          "Change",
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!showSecondField) {
                          continueLogin();
                        } else {
                          login();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        !showSecondField
                            ? "CONTINUE"
                            : isEmailLogin
                                ? "SIGN IN"
                                : "VERIFY OTP",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      const Expanded(
                        child: Divider(),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        child: Text(
                          "OR",
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  socialButton(
                    Icons.apple,
                    "Continue with Apple",
                    () {
                      showMessage(
                        "Apple Login Coming Soon",
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  socialButton(
                    Icons.login,
                    "Continue with Google",
                    () {
                      showMessage(
                        "Google Login Coming Soon",
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
        ),
      ),
    );
  }

  Widget socialButton(
    IconData icon,
    String text,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.70),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white,
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}