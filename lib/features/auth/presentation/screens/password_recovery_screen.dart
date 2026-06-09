import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../application/controllers/password_recovery_controller.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({
    required this.controller,
    super.key,
  });

  final PasswordRecoveryController controller;

  @override
  State<PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _requestFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final stage = widget.controller.stage;
        final isRequest = stage == PasswordRecoveryStage.request;

        return AuthScaffold(
          leading: GestureDetector(
            onTap: widget.controller.isSubmitting
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text(
              'Back to log in',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          title: isRequest ? 'Password Recovery' : 'Create New Password',
          description: isRequest
              ? 'The current backend does not expose recovery yet. This screen stays available so the mobile flow remains aligned to the report.'
              : 'Set a new password to recover access to your account.',
          child: Form(
            key: isRequest ? _requestFormKey : _resetFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRequest)
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.alternate_email_rounded,
                    validator: _validateEmail,
                    enabled: !widget.controller.isSubmitting,
                  )
                else ...[
                  AuthTextField(
                    controller: _passwordController,
                    label: 'New password',
                    obscureText: true,
                    prefixIcon: Icons.lock_reset_rounded,
                    validator: _validatePassword,
                    enabled: !widget.controller.isSubmitting,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AuthTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm password',
                    obscureText: true,
                    prefixIcon: Icons.verified_user_outlined,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }

                      return null;
                    },
                    enabled: !widget.controller.isSubmitting,
                  ),
                ],
                if (widget.controller.feedbackMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _RecoveryMessage(
                    message: widget.controller.feedbackMessage!,
                    isSuccess: widget.controller.isSuccess ||
                        stage == PasswordRecoveryStage.reset,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: widget.controller.isSubmitting
                      ? null
                      : isRequest
                          ? _sendRecovery
                          : _resetPassword,
                  child: widget.controller.isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isRequest ? 'Send Recovery' : 'Reset Password',
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendRecovery() async {
    final isValid = _requestFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    await widget.controller.requestRecovery(_emailController.text);
  }

  Future<void> _resetPassword() async {
    final isValid = _resetFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final success = await widget.controller.resetPassword(
      _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.feedbackMessage!),
        ),
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
    if ((value?.length ?? 0) < 8) {
      return 'Use at least 8 characters.';
    }

    return null;
  }
}

class _RecoveryMessage extends StatelessWidget {
  const _RecoveryMessage({
    required this.message,
    required this.isSuccess,
  });

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFF14532D)
            : const Color(0xFF7F1D1D),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isSuccess
              ? const Color(0xFF86EFAC)
              : const Color(0xFFFCA5A5),
        ),
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
