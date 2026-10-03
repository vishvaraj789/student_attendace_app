import 'package:flutter/material.dart';
import 'faculty/faculty_home.dart';
import 'student/student_home.dart';
import 'models/app_user.dart';
import 'utils/shared_preference.dart';
import 'utils/message_util.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Only faculty/admin sign up here. Student accounts are created by
  // faculty from the Student List (email + password given to the student).
  final UserRole _role = UserRole.faculty;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      MessageUtil.showErrorSnackBar(context, 'Please fix the errors above');
      return;
    }

    // NOTE: there is no real account backend yet (see login_page.dart).
    // This stores the current device's identity locally so login can
    // route to the right home screen. Swap this for real auth (e.g.
    // Firebase Auth + a users collection storing role) before shipping,
    // since a local pref is not a security boundary.
    // Faculty account credentials (checked on login)
    await SharedPrefsUtil.setString(
        'faculty_name', _nameController.text.trim());
    await SharedPrefsUtil.setString(
        'faculty_email', _emailController.text.trim());
    await SharedPrefsUtil.setString(
        'faculty_password', _passwordController.text);
    // Current session
    await SharedPrefsUtil.setString('user_name', _nameController.text.trim());
    await SharedPrefsUtil.setString(
        'user_email', _emailController.text.trim());
    await SharedPrefsUtil.setString('user_role', _role.asString);

    if (!mounted) return;
    MessageUtil.showSuccessSnackBar(context, 'Account created!');

    final home =
    _role == UserRole.faculty ? const FacultyHome() : const StudentHome();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => home),
          (route) => false,
    );
  }

  static const _accent = Color(0xFF6366F1);

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: border(Colors.grey.shade300),
      enabledBorder: border(Colors.grey.shade300),
      focusedBorder: border(_accent, 1.8),
      errorBorder: border(Colors.red.shade400),
      focusedErrorBorder: border(Colors.red.shade400, 1.8),
    );
  }

  Widget _eye(bool obscured, VoidCallback onTap) => IconButton(
    icon: Icon(
      obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      color: Colors.grey[600],
    ),
    onPressed: onTap,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded,
                        size: 34, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Create Faculty Account",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Students receive their login from faculty",
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: _fieldDecoration(
                              label: "Full Name",
                              hint: "Enter your name",
                              icon: Icons.person_outline,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Please enter your name'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDecoration(
                              label: "Email",
                              hint: "Enter your email",
                              icon: Icons.email_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDecoration(
                              label: "Password",
                              hint: "At least 6 characters",
                              icon: Icons.lock_outline,
                              suffix: _eye(
                                _obscurePassword,
                                    () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => v == null || v.length < 6
                                ? 'Password must be at least 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleRegister(),
                            decoration: _fieldDecoration(
                              label: "Confirm Password",
                              hint: "Re-enter your password",
                              icon: Icons.lock_outline,
                              suffix: _eye(
                                _obscureConfirm,
                                    () => setState(
                                        () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) => v != _passwordController.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Register",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?",
                          style: TextStyle(color: Colors.grey[700])),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                              color: _accent, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}