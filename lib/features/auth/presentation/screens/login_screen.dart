import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/design_tokens.dart';
import '../../application/controllers/login_controller.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.controller,
    super.key,
  });

  final LoginController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return AuthScaffold(
          title: 'WELCOME',
          description:
              'Monitor your fleet, shipments and incident response with a mobile flow aligned to the OmniTrack report.',
          footer: _DemoAccessCard(
            onFleetTap: () {
              _emailController.text = 'fleet@omnitrack.io';
              _passwordController.text = 'Fleet123!';
            },
            onClientTap: () {
              _emailController.text = 'client@omnitrack.io';
              _passwordController.text = 'Client123!';
            },
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthTextField(
                  controller: _emailController,
                  label: 'Email address',
                  hintText: 'fleet@omnitrack.io',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.alternate_email_rounded,
                  enabled: !widget.controller.isSubmitting,
                  validator: _validateEmail,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Enter your password',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_outline_rounded,
                  enabled: !widget.controller.isSubmitting,
                  validator: _validatePassword,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: widget.controller.rememberMe,
                          onChanged: widget.controller.isSubmitting
                              ? null
                              : widget.controller.toggleRememberMe,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.white,
                          checkColor: AppColors.primary,
                          title: const Text(
                            'Remember me',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.controller.isSubmitting
                          ? null
                          : () => Navigator.of(context).pushNamed(
                                AppRoutes.passwordRecovery,
                              ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Forgot your password?'),
                    ),
                  ],
                ),
                if (widget.controller.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _FeedbackBanner(
                    message: widget.controller.errorMessage!,
                    backgroundColor: const Color(0xFF7F1D1D),
                    borderColor: const Color(0xFFFCA5A5),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: widget.controller.isSubmitting ? null : _submit,
                  child: widget.controller.isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign In'),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                      ),
                      GestureDetector(
                        onTap: widget.controller.isSubmitting
                            ? null
                            : () => Navigator.of(context).pushNamed(
                                  AppRoutes.register,
                                ),
                        child: const Text(
                          'Sign up here',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final session = await widget.controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (session != null && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }

    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }

    return null;
  }
}

class _DemoAccessCard extends StatelessWidget {
  const _DemoAccessCard({
    required this.onFleetTap,
    required this.onClientTap,
  });

  final VoidCallback onFleetTap;
  final VoidCallback onClientTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demo access',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Use one of the report-aligned roles while the mobile app is still disconnected from the real IAM backend.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onFleetTap,
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Fleet Manager Demo'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onClientTap,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Customer Demo'),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String message;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
