import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../application/controllers/billing_controller.dart';

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
        title: const Text('Vincular método de pago'),
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
                'VINCULAR MÉTODO DE PAGO',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                controller: _cardNumberController,
                label: 'Número de tarjeta',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.credit_card_rounded,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                ],
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 13) {
                    return 'Ingresa un número de tarjeta válido.';
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
                      label: 'Fecha de vencimiento',
                      hintText: 'MM/YY',
                      keyboardType: TextInputType.datetime,
                      prefixIcon: Icons.event_rounded,
                      validator: (value) {
                        if (!RegExp(r'^\d{2}/\d{2}$')
                            .hasMatch((value ?? '').trim())) {
                          return 'Usa MM/AA.';
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
                          return 'CVC inválido.';
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
                      label: 'Código postal',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.local_post_office_outlined,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Obligatorio.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AuthTextField(
                      controller: _countryController,
                      label: 'País',
                      prefixIcon: Icons.public_rounded,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Obligatorio.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _confirm,
                child: const Text('CONFIRMAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    // The billing contract does not expose a card-linking endpoint yet, so the
    // card is only validated locally. Surfaced as a dependency, not faked.
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tarjeta validada. La vinculación se guardará cuando el backend exponga el endpoint de pagos.',
        ),
      ),
    );
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
                'La vinculación de tarjetas aún no está disponible en el backend de facturación, por lo que la tarjeta solo se valida localmente. No se envían datos de la tarjeta.',
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
