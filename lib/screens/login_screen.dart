import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_error_messages.dart';
import '../auth/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_screen_decor.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/gold_card.dart';
import '../widgets/google_logo.dart';
import '../widgets/murshid_avatar.dart';
import '../widgets/ornament_divider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _hidePassword = true;

  bool get _busy => _loading || _googleLoading;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTheme.lato(color: context.c.textPrimary),
        ),
        backgroundColor: context.c.backgroundElevated,
      ),
    );
  }

  Future<void> _signInWithEmail() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().signInWithEmail(email, password);
    } catch (e) {
      if (!mounted) return;
      _showError(authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('cancelled')
          ? null
          : authErrorMessage(e);
      if (msg != null) _showError(msg);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: AuthScreenDecor(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const MurshidAvatar(
                  diameter: 112,
                  goldRingWidth: 2.5,
                  outerRingWidth: 4,
                  applyGoldenOverlay: true,
                ),
                const SizedBox(height: 18),
                Text(
                  'AL Nisar',
                  style: AppTheme.cinzelHeading(
                    fontSize: 22,
                    letterSpacing: 3,
                    color: c.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Spiritual Learnings',
                  style: AppTheme.lato(
                    fontSize: 13,
                    color: c.textMuted.o(0.95),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                const OrnamentDivider(),
                const SizedBox(height: 18),
                GoldCard(
                  backgroundColor: c.backgroundSurface.o(0.9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome back',
                        style: AppTheme.cormorantGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to access lessons, Irshadat, and your saved content.',
                        style: AppTheme.lato(
                          fontSize: 12,
                          color: c.textMuted,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        label: 'Email',
                        controller: _email,
                        hintText: 'you@email.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        label: 'Password',
                        controller: _password,
                        hintText: 'Your password',
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signInWithEmail(),
                        suffix: IconButton(
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              _busy ? null : () => context.go('/forgot-password'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot password?',
                            style: AppTheme.lato(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: c.accentGold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AuthPrimaryButton(
                        label: 'Sign In',
                        loading: _loading,
                        onPressed: _signInWithEmail,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: Divider(color: c.borderDefault)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'or',
                              style: AppTheme.lato(
                                fontSize: 11,
                                color: c.textMuted,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: c.borderDefault)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: _busy ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.textPrimary,
                          side: BorderSide(color: c.borderDefault),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _googleLoading
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: c.textPrimary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const GoogleLogo(size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Continue with Google',
                                    style: AppTheme.lato(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New here? ',
                            style: AppTheme.lato(
                              fontSize: 12,
                              color: c.textMuted,
                            ),
                          ),
                          TextButton(
                            onPressed:
                                _busy ? null : () => context.go('/signup'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Create an account',
                              style: AppTheme.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: c.accentGold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Admin features appear automatically when your role is upgraded.',
                        textAlign: TextAlign.center,
                        style: AppTheme.lato(
                          fontSize: 11.5,
                          color: c.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'By continuing, you agree to our terms of use and privacy policy.',
                  textAlign: TextAlign.center,
                  style: AppTheme.lato(fontSize: 11, color: c.textFaint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
