import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() =>
      _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void createAccount() {

    if (nameController.text.trim().isEmpty) {
      showMessage("Enter Full Name");
      return;
    }

    if (emailController.text.trim().isEmpty) {
      showMessage("Enter Email Address");
      return;
    }

    if (mobileController.text.trim().length != 10) {
      showMessage("Enter Valid Mobile Number");
      return;
    }

    if (passwordController.text.length < 6) {
      showMessage(
        "Password must be at least 6 characters",
      );
      return;
    }

    if (passwordController.text !=
        confirmPasswordController.text) {
      showMessage("Passwords do not match");
      return;
    }

    showMessage("Account Created Successfully");

    Future.delayed(
      const Duration(milliseconds: 700),
      () {
        Navigator.pop(context);
      },
    );
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
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
            color: Colors.white.withOpacity(.80),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
              ),
              child: Column(
                children: [

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  Image.asset(
                    "assets/logo.png",
                    height: 100,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "VIRTUAL TRIALS, REAL YOU",
                    style: TextStyle(
                      letterSpacing: 2,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 35),

                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Join Thiraa and start your\nvirtual fashion journey",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black
                          .withOpacity(.6),
                    ),
                  ),

                  const SizedBox(height: 30),

                  glassField(
                    controller: nameController,
                    hint: "Full Name",
                    icon: Icons.person_outline,
                  ),

                  const SizedBox(height: 15),

                  glassField(
                    controller: emailController,
                    hint: "Email Address",
                    icon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 15),

                  glassField(
                    controller: mobileController,
                    hint: "Mobile Number",
                    icon: Icons.phone_outlined,
                  ),

                  const SizedBox(height: 15),

                  glassField(
                    controller: passwordController,
                    hint: "Password",
                    icon: Icons.lock_outline,
                    obscure: obscurePassword,
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

                  const SizedBox(height: 15),

                  glassField(
                    controller:
                        confirmPasswordController,
                    hint: "Confirm Password",
                    icon: Icons.lock_outline,
                    obscure:
                        obscureConfirmPassword,
                    suffix: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword =
                              !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: createAccount,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.black,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                      child: const Text(
                        "CREATE ACCOUNT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [

                      const Text(
                        "Already have an account? ",
                      ),

                      GestureDetector(
                        onTap: () {
                          Navigator.pop(
                            context,
                          );
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
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
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}