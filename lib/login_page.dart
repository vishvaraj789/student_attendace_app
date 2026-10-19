import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'admin/admin_home.dart';
import 'utils/admin_auth.dart';
import 'utils/faculty_repository.dart';
import 'faculty/faculty_home.dart';
import 'Student/student_home.dart';
import 'models/app_user.dart';
import 'models/student.dart';
import 'utils/student_repository.dart';
import 'utils/cloud_sync.dart';
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
  bool _loading = false;
  // Worked out from the email when the user taps Login.
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

    // Get the latest accounts from Google Sheets (new logins made by the admin).
    setState(() => _loading = true);
    await CloudSync.pullAll(timeout: const Duration(seconds: 6));
    if (!mounted) return;
    setState(() => _loading = false);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    // One login form for everyone: the role is worked out from the email.
    if (AdminAuth.isAdminEmail(email)) {
      _role = UserRole.admin;
    } else if (FacultyRepository.getAll().any(
            (f) => f.email.trim().toLowerCase() == email.toLowerCase())) {
      _role = UserRole.faculty;
    } else {
      _role = UserRole.student;
    }

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
      await SharedPrefsUtil.setString('user_id', faculty.id);
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

  static const _navy = Color(0xFF0F1F3D);
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFD1D5DB);
  static const _bg = Color(0xFFF3F5F9);

  static const _appName = 'Attendance Management System';

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14.5),
      prefixIcon: Icon(icon, size: 20, color: _muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      border: border(_line),
      enabledBorder: border(_line),
      focusedBorder: border(_blue, 1.8),
      errorBorder: border(const Color(0xFFDC2626)),
      focusedErrorBorder: border(const Color(0xFFDC2626), 1.8),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: _ink,
      ),
    ),
  );

  Widget _logoMark({double size = 44}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(size * 0.28),
      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
    ),
    child: Icon(Icons.fact_check_outlined,
        color: Colors.white, size: size * 0.55),
  );

  // ---------------------------------------------------------------- form
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Sign in',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your registered email and password to continue.',
            style: TextStyle(fontSize: 14, height: 1.4, color: _muted),
          ),
          const SizedBox(height: 28),
          _label('Email address'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            decoration: _decoration(
              hint: 'name@example.com',
              icon: Icons.mail_outline_rounded,
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Please enter your email address'
                : null,
          ),
          const SizedBox(height: 18),
          _label('Password'),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: _decoration(
              hint: 'Enter your password',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: _muted,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => v == null || v.isEmpty
                ? 'Please enter your password'
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _value,
                  activeColor: _blue,
                  side: const BorderSide(color: _line, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (v) => setState(() => _value = v ?? false),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _value = !_value),
                child: const Text('Remember me',
                    style: TextStyle(fontSize: 13.5, color: _ink)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                disabledBackgroundColor: _blue.withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
                  : const Text(
                'Sign in',
                style: TextStyle(
                    fontSize: 15.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: _muted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Forgot your password? Please contact your administrator.',
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: _muted),
                ),
              ),
            ],
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 14),
            Text(
              CloudSync.status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _footer({Color color = _muted}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Text(
      '© ${DateTime.now().year} $_appName',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: color),
    ),
  );

  // ------------------------------------------------------------ layouts
  Widget _brandPanel() {
    Widget point(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF93C5FD)),
          const SizedBox(width: 14),
          Text(text,
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFFE5E7EB))),
        ],
      ),
    );
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_navy, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _logoMark(size: 56),
          const SizedBox(height: 28),
          const Text(
            _appName,
            style: TextStyle(
              fontSize: 34,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'One place for classes, students and attendance.',
            style: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFFBFDBFE)),
          ),
          const SizedBox(height: 40),
          point(Icons.event_available_outlined, 'Quick daily attendance'),
          point(Icons.bar_chart_rounded, 'Clear reports and history'),
          point(Icons.verified_user_outlined, 'Separate access for each role'),
        ],
      ),
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        Expanded(flex: 5, child: _brandPanel()),
        Expanded(
          flex: 4,
          child: Container(
            color: _bg,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _buildForm(),
                      ),
                    ),
                  ),
                ),
                _footer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 72),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_navy, Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                _logoMark(size: 60),
                const SizedBox(height: 16),
                const Text(
                  _appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: _footer(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: LayoutBuilder(
        builder: (context, c) =>
        c.maxWidth >= 900 ? _wideLayout() : _narrowLayout(),
      ),
    );
  }
}