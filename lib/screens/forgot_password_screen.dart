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
import '../widgets/ornament_divider.dart';
import '../widgets/auth_primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _showMessage('Please enter your email address.');
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().sendPasswordResetEmail(email);
      if (!mounted) return;
      setState(() => _sent = true);
      _showMessage(
        'Password reset link sent. Check your inbox.',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    final c = context.c;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTheme.lato(color: c.textPrimary),
        ),
        backgroundColor: isSuccess ? c.accentGold.o(0.9) : c.backgroundElevated,
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
                  'Reset Password',
                  style: AppTheme.cinzelHeading(
                    fontSize: 20,
                    letterSpacing: 2,
                    color: c.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'We will email you a link to reset your password',
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
                      if (_sent) ...[
                        Icon(
                          Icons.mark_email_read_outlined,
                          size: 40,
                          color: c.accentGold,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Check your email for a password reset link. If you do not see it, check your spam folder.',
                          style: AppTheme.lato(
                            fontSize: 12,
                            color: c.textMuted,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        AuthTextField(
                          label: 'Email',
                          controller: _email,
                          hintText: 'you@email.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 18),
                        AuthPrimaryButton(
                          label: 'Send Reset Link',
                          loading: _loading,
                          onPressed: _submit,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loading ? null : () => context.go('/login'),
                        child: Text(
                          'Back to sign in',
                          style: AppTheme.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.accentGold,
                          ),
                        ),
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
