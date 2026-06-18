import '../entities/subscription.dart';

class BillingSnapshot {
  const BillingSnapshot({
    required this.subscription,
    required this.payments,
  });

  final Subscription subscription;
  final List<PaymentRecord> payments;
}

abstract class BillingRepository {
  Future<BillingSnapshot> loadBilling({
    required String accessToken,
    required String userId,
  });

  Future<Subscription> linkPaymentMethod({
    required String accessToken,
    required String userId,
    required PaymentMethodDraft draft,
  });
}
