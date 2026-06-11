import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_error_messages.dart';
import '../auth/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/auth_screen_decor.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/gold_card.dart';
import '../widgets/murshid_avatar.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/ornament_divider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final confirm = _confirmPassword.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().signUpWithEmail(
            email: email,
            password: password,
            displayName: name.isEmpty ? null : name,
          );
    } catch (e) {
      if (!mounted) return;
      _showError(authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                const MurshidAvatar(
                  diameter: 88,
                  goldRingWidth: 2.5,
                  outerRingWidth: 4,
                  applyGoldenOverlay: true,
                ),
                const SizedBox(height: 14),
                Text(
                  'Create Account',
                  style: AppTheme.cinzelHeading(
                    fontSize: 20,
                    letterSpacing: 2,
                    color: c.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Join AL Nisar to access spiritual learnings',
                  style: AppTheme.lato(
                    fontSize: 12,
                    color: c.textMuted.o(0.95),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                const OrnamentDivider(),
                const SizedBox(height: 16),
                GoldCard(
                  backgroundColor: c.backgroundSurface.o(0.9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthTextField(
                        label: 'Name (optional)',
                        controller: _name,
                        hintText: 'Your name',
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
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
                        hintText: 'At least 6 characters',
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.next,
                        suffix: IconButton(
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        label: 'Confirm password',
                        controller: _confirmPassword,
                        hintText: 'Re-enter password',
                        obscureText: _hideConfirm,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        suffix: IconButton(
                          onPressed: () =>
                              setState(() => _hideConfirm = !_hideConfirm),
                          icon: Icon(
                            _hideConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AuthPrimaryButton(
                        label: 'Create Account',
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTheme.lato(
                              fontSize: 12,
                              color: c.textMuted,
                            ),
                          ),
                          TextButton(
                            onPressed:
                                _loading ? null : () => context.go('/login'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Sign in',
                              style: AppTheme.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: c.accentGold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
