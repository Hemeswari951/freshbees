import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/t_colors.dart';
import '../../models/create_admin.dart';
import '../../services/dashboard_service.dart';
import '../../core/responsive.dart';

class AddAdminScreen extends StatefulWidget {
  const AddAdminScreen({super.key});

  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String selectedRole = "Admin";
  bool isActive = true;

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: TColors.cream,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //------------------------------------------------
              // HEADER
              //------------------------------------------------
              //------------------------------------------------
              // HEADER
              //------------------------------------------------
             if (isMobile)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TColors.border),
        ),
        child: IconButton(
          onPressed: () {
            context.go('/dashboard');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),

      const SizedBox(height: 16),

      const Text(
        "Add Administrator",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: TColors.black,
        ),
      ),

      const SizedBox(height: 4),

      Text(
        "Create a new administrator account",
        style: TextStyle(
          color: TColors.brownLight,
          fontSize: 13,
        ),
      ),
    ],
  )
else
  Row(
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TColors.border),
        ),
        child: IconButton(
          onPressed: () {
            context.go('/dashboard');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),

      const SizedBox(width: 16),

      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Add Administrator",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: TColors.black,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Create a new administrator account",
            style: TextStyle(
              color: TColors.brownLight,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ],
  ),

              const SizedBox(height: 30),
              //------------------------------------------------
              // PERSONAL INFO
              //------------------------------------------------
              _sectionCard(
                title: "Personal Information",
                child: Column(
                  children: [
                    
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller: fullNameController,
                            label: "Full Name",
                            icon: Icons.person_outline,
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: _textField(
                            controller: usernameController,
                            label: "Username",
                            icon: Icons.badge_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller: emailController,
                            label: "Email",
                            icon: Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedRole,
                            decoration: _inputDecoration(
                              "Role",
                              Icons.admin_panel_settings_outlined,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: "Admin",
                                child: Text("Admin"),
                              ),

                              DropdownMenuItem(
                                value: "SuperAdmin",
                                child: Text("Super Admin"),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                selectedRole = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              //------------------------------------------------
              // SECURITY
              //------------------------------------------------
              _sectionCard(
                title: "Security",
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: passwordController,
                            obscureText: hidePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Password required";
                              }

                              if (value.length < 6) {
                                return "Minimum 6 characters";
                              }

                              return null;
                            },

                            decoration:
                                _inputDecoration(
                                  "Password",
                                  Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        hidePassword = !hidePassword;
                                      });
                                    },
                                    icon: Icon(
                                      hidePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                  ),
                                ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: TextFormField(
                            controller: confirmPasswordController,
                            obscureText: hideConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Confirm Password is required";
                              }

                              if (value != passwordController.text) {
                                return "Passwords do not match";
                              }

                              return null;
                            },
                            decoration:
                                _inputDecoration(
                                  "Confirm Password",
                                  Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        hideConfirmPassword =
                                            !hideConfirmPassword;
                                      });
                                    },
                                    icon: Icon(
                                      hideConfirmPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        passwordController.text.length < 6
                            ? "Weak Password"
                            : passwordController.text.length < 10
                            ? "Medium Password"
                            : "Strong Password",
                        style: TextStyle(
                          color: passwordController.text.length < 6
                              ? Colors.red
                              : passwordController.text.length < 10
                              ? Colors.orange
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    CheckboxListTile(
                      value: isActive,
                      activeColor: TColors.black,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Active Account"),
                      subtitle: const Text(
                        "Admin can login immediately",
                        style: TextStyle(color: TColors.brownLight),
                      ),
                      onChanged: (value) {
                        setState(() {
                          isActive = value ?? true;
                        });
                      },
                      //onChanged: (_){},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              //------------------------------------------------
              // BUTTONS
              //------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
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
                              final admin = CreateAdmin(
                                fullName: fullNameController.text.trim(),
                                username: usernameController.text.trim(),
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                                role: selectedRole,
                                isActive: isActive,
                              );

                              final response = await DashboardService()
                                  .createAdmin(admin);

                              if (!mounted) return;
                              if (response["success"] == true) {
                                await showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (dialogContext) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Row(
                                        children: const [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 30,
                                          ),
                                          SizedBox(width: 10),
                                          Text("Success"),
                                        ],
                                      ),
                                      content: const Text(
                                        "Admin created successfully.",
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(dialogContext).pop();
                                            context.go('/dashboard');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: TColors.black,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text(response["message"]),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
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
                          },
                    icon: const Icon(Icons.person_add),
                    label: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Create Admin"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    fullNameController.dispose();

    usernameController.dispose();

    emailController.dispose();

    passwordController.dispose();

    confirmPasswordController.dispose();

    super.dispose();
  }
  //------------------------------------------------

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 25),

          child,
        ],
      ),
    );
  }

  //------------------------------------------------

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "$label is required";
        }

        if (label == "Email") {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

          if (!emailRegex.hasMatch(value)) {
            return "Enter valid email";
          }
        }

        return null;
      },

      decoration: _inputDecoration(label, icon),
    );
  }

  //------------------------------------------------

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TColors.border),
      ),
    );
  }
}
