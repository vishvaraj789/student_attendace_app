import 'package:flutter/material.dart';
import 'admin/admin_home.dart';
import 'utils/admin_auth.dart';
import 'utils/faculty_repository.dart';
import 'faculty/faculty_home.dart';
import 'student/student_home.dart';
import 'models/app_user.dart';
import 'models/student.dart';
import 'utils/student_repository.dart';
import 'utils/shared_preference.dart';
import 'utils/message_util.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _value = false;
  bool _obscurePassword = true;
  UserRole _role = UserRole.student;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    bool rememberMe =
    SharedPrefsUtil.getBool('remember_me', defaultValue: false);
    if (rememberMe) {
      setState(() {
        _value = true;
        _emailController.text = SharedPrefsUtil.getString('saved_email');
      });
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      MessageUtil.showErrorSnackBar(context, 'Please fix the errors above');
      return;
    }

    if (_value) {
      await SharedPrefsUtil.setBool('remember_me', true);
      await SharedPrefsUtil.setString('saved_email', _emailController.text);
    } else {
      await SharedPrefsUtil.remove('remember_me');
      await SharedPrefsUtil.remove('saved_email');
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // NOTE: accounts are stored on this device only (no server yet).
    // Students: the email + password their faculty created for them.
    // Faculty: the account registered on this device.
    if (_role == UserRole.student) {
      Student? match;
      for (final st in StudentRepository.getAll()) {
        if (st.email.toLowerCase() == email.toLowerCase()) {
          match = st;
          break;
        }
      }
      if (match == null ||
          match.password.isEmpty ||
          match.password != password) {
        if (!mounted) return;
        MessageUtil.showErrorSnackBar(context,
            'Invalid email or password. Ask your admin for your login.');
        return;
      }
      await SharedPrefsUtil.setString('user_name', match.name);
      await SharedPrefsUtil.setString('user_email', match.email);
      await SharedPrefsUtil.setString('user_role', UserRole.student.asString);
    } else if (_role == UserRole.faculty) {
      final faculty = FacultyRepository.authenticate(email, password);
      if (faculty == null) {
        if (!mounted) return;
        MessageUtil.showErrorSnackBar(context,
            'Invalid email or password. Ask the admin for your login.');
        return;
      }
      await SharedPrefsUtil.setString('user_name', faculty.name);
      await SharedPrefsUtil.setString('user_email', faculty.email);
      await SharedPrefsUtil.setString('user_role', UserRole.faculty.asString);
    } else {
      if (!AdminAuth.verify(email, password)) {
        if (!mounted) return;
        MessageUtil.showErrorSnackBar(context, 'Invalid admin email or password.');
        return;
      }
      await SharedPrefsUtil.setString('user_name', 'Admin');
      await SharedPrefsUtil.setString('user_email', AdminAuth.email);
      await SharedPrefsUtil.setString('user_role', UserRole.admin.asString);
    }

    if (!mounted) return;
    MessageUtil.showSuccessSnackBar(context, 'Login successful!');

    final Widget home;
    switch (_role) {
      case UserRole.admin:
        home = const AdminHome();
        break;
      case UserRole.faculty:
        home = const FacultyHome();
        break;
      case UserRole.student:
        home = const StudentHome();
        break;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => home),
          (route) => false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.fact_check_rounded,
                        size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Attendance Manager",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Sign in to continue",
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 28),

                  // Form card
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
                          SegmentedButton<UserRole>(
                            showSelectedIcon: false,
                            style: ButtonStyle(
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              backgroundColor:
                              WidgetStateProperty.resolveWith((states) {
                                return states.contains(WidgetState.selected)
                                    ? _accent.withValues(alpha: 0.12)
                                    : null;
                              }),
                              foregroundColor:
                              WidgetStateProperty.resolveWith((states) {
                                return states.contains(WidgetState.selected)
                                    ? _accent
                                    : Colors.grey[700];
                              }),
                            ),
                            segments: const [
                              ButtonSegment(
                                value: UserRole.student,
                                label: Text('Student'),
                              ),
                              ButtonSegment(
                                value: UserRole.faculty,
                                label: Text('Faculty'),
                              ),
                              ButtonSegment(
                                value: UserRole.admin,
                                label: Text('Admin'),
                              ),
                            ],
                            selected: {_role},
                            onSelectionChanged: (selection) {
                              setState(() => _role = selection.first);
                            },
                          ),
                          if (_role != UserRole.admin) ...[
                            const SizedBox(height: 12),
                            Text(
                              _role == UserRole.student
                                  ? 'Use the email and password given to you by your admin.'
                                  : 'Use the email and password given to you by the admin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                          const SizedBox(height: 22),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDecoration(
                              label: "Email",
                              hint: "Enter your email",
                              icon: Icons.email_outlined,
                            ),
                            validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Please enter email'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            decoration: _fieldDecoration(
                              label: "Password",
                              hint: "Enter your password",
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) =>
                            value == null || value.isEmpty
                                ? 'Please enter password'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Checkbox(
                                value: _value,
                                activeColor: _accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (bool? newValue) {
                                  setState(() => _value = newValue ?? false);
                                },
                              ),
                              const Text("Remember me"),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Password reset isn't available yet"),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Forgot password?",
                                  style: TextStyle(color: _accent),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Login",
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}