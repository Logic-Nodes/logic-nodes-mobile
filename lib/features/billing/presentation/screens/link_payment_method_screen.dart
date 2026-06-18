import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../application/controllers/billing_controller.dart';
import '../../domain/entities/subscription.dart';

class LinkPaymentMethodScreen extends StatefulWidget {
  const LinkPaymentMethodScreen({
    required this.controller,
    super.key,
  });

  final BillingController controller;

  @override
  State<LinkPaymentMethodScreen> createState() =>
      _LinkPaymentMethodScreenState();
}

class _LinkPaymentMethodScreenState extends State<LinkPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expireController = TextEditingController();
  final _cvcController = TextEditingController();
  final _postalController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expireController.dispose();
    _cvcController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link payment method'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _NoBackendNotice(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'LINK PAYMENT METHOD',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                controller: _cardNumberController,
                label: 'Card number',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.credit_card_rounded,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                ],
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 13) {
                    return 'Enter a valid card number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      controller: _expireController,
                      label: 'Expire date',
                      hintText: 'MM/YY',
                      keyboardType: TextInputType.datetime,
                      prefixIcon: Icons.event_rounded,
                      validator: (value) {
                        if (!RegExp(r'^\d{2}/\d{2}$')
                            .hasMatch((value ?? '').trim())) {
                          return 'Use MM/YY.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AuthTextField(
                      controller: _cvcController,
                      label: 'CVC',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.password_rounded,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (value) {
                        if ((value ?? '').trim().length < 3) {
                          return 'Invalid CVC.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      controller: _postalController,
                      label: 'Postal code',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.local_post_office_outlined,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Required.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AuthTextField(
                      controller: _countryController,
                      label: 'Country',
                      prefixIcon: Icons.public_rounded,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Required.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedBuilder(
                animation: widget.controller,
                builder: (context, _) {
                  final isLinking = widget.controller.isLinking;
                  return FilledButton(
                    onPressed: isLinking ? null : _confirm,
                    child: isLinking
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('CONFIRM'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final success = await widget.controller.linkPaymentMethod(
      PaymentMethodDraft(
        cardNumber: _cardNumberController.text,
        expireDate: _expireController.text,
        cvc: _cvcController.text,
        postalCode: _postalController.text,
        country: _countryController.text,
      ),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment method linked successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ??
                'Unable to link the payment method.',
          ),
        ),
      );
    }
  }
}

class _NoBackendNotice extends StatelessWidget {
  const _NoBackendNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7E8),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'For your safety only the last 4 digits are stored. Use a test '
                'card such as 4242 4242 4242 4242.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
