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
  String? _lastSentEmail;

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
      setState(() {
        _sent = true;
        _lastSentEmail = email.trim().toLowerCase();
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage(passwordResetErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    final c = context.c;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTheme.lato(color: c.textPrimary),
        ),
        backgroundColor: c.backgroundElevated,
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
                  'For accounts created with email and password',
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
                          _lastSentEmail == null
                              ? 'If an account exists for that email, a reset link has been sent.'
                              : 'If an account exists for $_lastSentEmail, a reset link has been sent.',
                          style: AppTheme.lato(
                            fontSize: 12,
                            color: c.textPrimary,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Check your inbox and spam/promotions folders. The email is sent from Firebase (noreply address).\n\n'
                          'If you originally signed in with Google, use Continue with Google on the sign-in screen — password reset does not change your Google password.',
                          style: AppTheme.lato(
                            fontSize: 12,
                            color: c.textMuted,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        AuthPrimaryButton(
                          label: 'Resend link',
                          loading: _loading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() => _sent = false),
                          child: Text(
                            'Use a different email',
                            style: AppTheme.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: c.accentGold,
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.backgroundInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.borderDefault, width: 0.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 18, color: c.accentGold),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Use this only if you signed up with email and password. '
                                  'Google sign-in accounts should use Continue with Google instead.',
                                  style: AppTheme.lato(
                                    fontSize: 11,
                                    color: c.textMuted,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
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
