import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../application/controllers/register_controller.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    required this.controller,
    super.key,
  });

  final RegisterController controller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyContactEmailController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _fiscalAddressController = TextEditingController();
  final _adminFirstNameController = TextEditingController();
  final _adminLastNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _companyPasswordController = TextEditingController();
  final _companyConfirmPasswordController = TextEditingController();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientPasswordController = TextEditingController();
  final _clientConfirmPasswordController = TextEditingController();

  bool _acceptedTerms = false;

  @override
  void dispose() {
    _companyContactEmailController.dispose();
    _legalNameController.dispose();
    _taxIdController.dispose();
    _fiscalAddressController.dispose();
    _adminFirstNameController.dispose();
    _adminLastNameController.dispose();
    _adminEmailController.dispose();
    _companyPasswordController.dispose();
    _companyConfirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _clientEmailController.dispose();
    _clientPasswordController.dispose();
    _clientConfirmPasswordController.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final isCompany = widget.controller.selectedSegment ==
            RegistrationSegment.shippingCompany;

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
          title: 'Create New Account',
          description:
              'Follow the mobile flow from the report and choose the segment that defines your access level inside OmniTrack.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose your segment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SegmentPicker(
                  selected: widget.controller.selectedSegment,
                  onChanged: widget.controller.isSubmitting
                      ? null
                      : widget.controller.selectSegment,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (isCompany) _buildCompanyFields() else _buildClientFields(),
                const SizedBox(height: AppSpacing.md),
                Material(
                  color: Colors.transparent,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _acceptedTerms,
                    onChanged: widget.controller.isSubmitting
                        ? null
                        : (value) =>
                            setState(() => _acceptedTerms = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.white,
                    checkColor: AppColors.primary,
                    title: const Text(
                      'By accepting, you agree to the application Terms and conditions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (widget.controller.feedbackMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InlineMessage(
                    message: widget.controller.feedbackMessage!,
                    isSuccess: widget.controller.isSuccess,
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
                      : const Text('Sign Up'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompanyFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'Company Data'),
        const SizedBox(height: AppSpacing.sm),
        AuthTextField(
          controller: _companyContactEmailController,
          label: 'Company contact email',
          keyboardType: TextInputType.emailAddress,
          validator: _requiredEmail,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AuthTextField(
                controller: _legalNameController,
                label: 'Legal name',
                validator: _requiredText,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AuthTextField(
                controller: _taxIdController,
                label: 'ID',
                validator: _requiredText,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AuthTextField(
          controller: _fiscalAddressController,
          label: 'Fiscal address',
          validator: _requiredText,
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionTitle(label: 'Administrator Details'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AuthTextField(
                controller: _adminFirstNameController,
                label: 'First name',
                validator: _requiredText,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AuthTextField(
                controller: _adminLastNameController,
                label: 'Last name',
                validator: _requiredText,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionTitle(label: 'Administrator Account'),
        const SizedBox(height: AppSpacing.sm),
        AuthTextField(
          controller: _adminEmailController,
          label: 'Email address',
          keyboardType: TextInputType.emailAddress,
          validator: _requiredEmail,
        ),
        const SizedBox(height: AppSpacing.sm),
        AuthTextField(
          controller: _companyPasswordController,
          label: 'Password',
          obscureText: true,
          validator: _requiredPassword,
        ),
        const SizedBox(height: AppSpacing.sm),
        AuthTextField(
          controller: _companyConfirmPasswordController,
          label: 'Confirm password',
          obscureText: true,
          validator: (value) => _confirmPassword(
            value,
            against: _companyPasswordController.text,
          ),
        ),
      ],
    );
  }

  Widget _buildClientFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'Profile Data'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AuthTextField(
                controller: _firstNameController,
                label: 'First name',
                validator: _requiredText,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AuthTextField(
                controller: _lastNameController,
                label: 'Last name',
                validator: _requiredText,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionTitle(label: 'Account Data'),
        const SizedBox(height: AppSpacing.sm),
        AuthTextField(
          controller: _clientEmailController,
          label: 'Email address',
          keyboardType: TextInputType.emailAddress,
          validator: _requiredEmail,
        ),
        const SizedBox(height: AppSpacing.sm),
        AuthTextField(
          controller: _clientPasswordController,
          label: 'Password',
          obscureText: true,
          validator: _requiredPassword,
        ),
        const SizedBox(height: AppSpacing.sm),
        AuthTextField(
          controller: _clientConfirmPasswordController,
          label: 'Confirm password',
          obscureText: true,
          validator: (value) => _confirmPassword(
            value,
            against: _clientPasswordController.text,
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (!formIsValid) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the Terms and conditions.'),
        ),
      );
      return;
    }

    final success = switch (widget.controller.selectedSegment) {
      RegistrationSegment.shippingCompany => widget.controller.submitCompany(
          companyContactEmail: _companyContactEmailController.text,
          legalName: _legalNameController.text,
          taxId: _taxIdController.text,
          fiscalAddress: _fiscalAddressController.text,
          adminFirstName: _adminFirstNameController.text,
          adminLastName: _adminLastNameController.text,
          adminEmail: _adminEmailController.text,
          password: _companyPasswordController.text,
        ),
      RegistrationSegment.client => widget.controller.submitClient(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _clientEmailController.text,
          password: _clientPasswordController.text,
        ),
    };

    if (await success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.feedbackMessage!),
        ),
      );
    }
  }

  String? _requiredText(String? value) {
    if ((value?.trim().isEmpty ?? true)) {
      return 'Required field.';
    }

    return null;
  }

  String? _requiredEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email.';
    }

    return null;
  }

  String? _requiredPassword(String? value) {
    if ((value?.length ?? 0) < 8) {
      return 'Use at least 8 characters.';
    }

    return null;
  }

  String? _confirmPassword(
    String? value, {
    required String against,
  }) {
    if (value != against) {
      return 'Passwords do not match.';
    }

    return null;
  }
}

class _SegmentPicker extends StatelessWidget {
  const _SegmentPicker({
    required this.selected,
    required this.onChanged,
  });

  final RegistrationSegment selected;
  final ValueChanged<RegistrationSegment>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _SegmentOption(
          label: 'Shipping Company',
          value: RegistrationSegment.shippingCompany,
          selected: selected,
          onChanged: onChanged,
        ),
        _SegmentOption(
          label: 'Client',
          value: RegistrationSegment.client,
          selected: selected,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SegmentOption extends StatelessWidget {
  const _SegmentOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final RegistrationSegment value;
  final RegistrationSegment selected;
  final ValueChanged<RegistrationSegment>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;

    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(value),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
          ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
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
