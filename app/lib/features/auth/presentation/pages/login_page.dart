import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/gradient_button.dart';
import 'register_step1_page.dart';
import 'forgot_password_page.dart';
import '../../../../core/l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final proxyEmail = '$username${AppConstants.proxyEmailDomain}';

      await Supabase.instance.client.auth.signInWithPassword(
        email: proxyEmail,
        password: password,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.current.incorrectCredentials, style: GoogleFonts.googleSans()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error during login: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.current.loginErrorMsg, style: GoogleFonts.googleSans()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context).loginTitle,
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                // Logo + Greeting
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primaryLight, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, e, s) => const Icon(
                              Icons.health_and_safety_outlined,
                              color: AppColors.primary,
                              size: 44,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).loginWelcome,
                        style: GoogleFonts.googleSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).loginSubtitle,
                        style: GoogleFonts.googleSans(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Username Field
                FormField<void>(
                  autovalidateMode: AutovalidateMode.disabled,
                  validator: (_) {
                    final v = _usernameController.text.trim();
                    if (v.isEmpty) return AppLocalizations.current.usernameRequired;
                    if (v.length < 4) return AppLocalizations.current.usernameTooShort;
                    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(v)) return AppLocalizations.current.usernameInvalidChars;
                    return null;
                  },
                  builder: (field) => _buildFieldContainer(
                    hasError: field.hasError,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          Icon(Icons.person_outline, color: Colors.grey[400], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _usernameController,
                              style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context).usernameHint,
                                hintStyle: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ]),
                        if (field.hasError)
                          _buildErrorText(field.errorText!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Password Field
                FormField<void>(
                  autovalidateMode: AutovalidateMode.disabled,
                  validator: (_) {
                    if (_passwordController.text.isEmpty) return AppLocalizations.current.passwordRequired;
                    return null;
                  },
                  builder: (field) => _buildFieldContainer(
                    hasError: field.hasError,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          Icon(Icons.lock_outline, color: Colors.grey[400], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context).passwordHint,
                                hintStyle: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey[400],
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                          ),
                        ]),
                        if (field.hasError)
                          _buildErrorText(field.errorText!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4.0),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context).forgotPassword,
                      style: GoogleFonts.googleSans(color: AppColors.primary),
                    ),
                  ),
                ),

                const SizedBox(height: 32.0),

                // Login Button
                GradientButton(
                  onPressed: _isLoading ? null : _login,
                  label: AppLocalizations.of(context).loginBtn,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 12.0),

                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterStep1Page(),
                              ),
                            );
                            if (result == true && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).createNewAccount,
                      style: GoogleFonts.googleSans(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldContainer({required Widget child, bool hasError = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }

  Widget _buildErrorText(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        message,
        style: GoogleFonts.googleSans(color: AppColors.error, fontSize: 12),
      ),
    );
  }
}
