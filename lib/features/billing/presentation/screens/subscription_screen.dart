import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/omnitrack_logo.dart';
import '../../application/controllers/billing_controller.dart';
import '../../domain/entities/subscription.dart';
import 'link_payment_method_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({
    required this.controller,
    super.key,
  });

  final BillingController controller;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OmnitrackLogo(
              foregroundColor: AppColors.ink,
              iconSize: 18,
              textSize: 20,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Manage your plan and payments',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: widget.controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final subscription = controller.subscription;

          if (subscription == null) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return _BillingError(
              message: controller.errorMessage ??
                  'No subscription data is available yet.',
              onRetry: controller.load,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                _SubscriptionCard(subscription: subscription),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _openLinkPayment,
                        child: Text(
                          subscription.hasPaymentMethod
                              ? 'Change card'
                              : 'Add card',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showSoon(context, 'Cancel your plan'),
                        child: const Text('Cancel your plan'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: () => _showSoon(context, 'Upgrade your plan'),
                  child: const Text('Upgrade your plan'),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'PAYMENT HISTORY',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                _PaymentHistory(payments: controller.payments),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openLinkPayment() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LinkPaymentMethodScreen(controller: widget.controller),
      ),
    );
    await widget.controller.load();
  }

  void _showSoon(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action will be available soon.')),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Subscription',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _KeyValueRow(label: 'Current Plan', value: subscription.planName),
            const SizedBox(height: AppSpacing.sm),
            _KeyValueRow(label: 'Amount', value: subscription.amountLabel),
            const SizedBox(height: AppSpacing.sm),
            _KeyValueRow(
              label: 'Status',
              value: subscription.status,
              valueColor: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.sm),
            _KeyValueRow(label: 'Renewal', value: subscription.renewalLabel),
            const SizedBox(height: AppSpacing.sm),
            _KeyValueRow(
              label: 'Payment Method',
              value: subscription.paymentMethodLabel ?? '--------',
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor ?? AppColors.ink,
                ),
          ),
        ),
      ],
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  const _PaymentHistory({required this.payments});

  final List<PaymentRecord> payments;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No payments registered yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                _HeaderCell('DATE', flex: 3),
                _HeaderCell('AMOUNT', flex: 2),
                _HeaderCell('STATUS', flex: 2),
                _HeaderCell('TXN ID', flex: 3),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final payment in payments)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  _BodyCell(payment.date, flex: 3),
                  _BodyCell(payment.amountLabel, flex: 2),
                  _BodyCell(
                    payment.status,
                    flex: 2,
                    color: AppColors.success,
                  ),
                  _BodyCell(payment.transactionId, flex: 3),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.value, {required this.flex, this.color});

  final String value;
  final int flex;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _BillingError extends StatelessWidget {
  const _BillingError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
