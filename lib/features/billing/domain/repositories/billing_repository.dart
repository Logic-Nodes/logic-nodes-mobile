import '../entities/subscription.dart';

class BillingSnapshot {
  const BillingSnapshot({
    required this.subscription,
    required this.payments,
    required this.plans,
  });

  final Subscription subscription;
  final List<Payment> payments;
  final List<Plan> plans;
}

abstract class BillingRepository {
  Future<BillingSnapshot> loadBilling({
    required String accessToken,
    required String userId,
  });

  Future<Subscription> changePlan({
    required String accessToken,
    required int subscriptionId,
    required int newPlanId,
  });

  Future<Subscription> cancelSubscription({
    required String accessToken,
    required int subscriptionId,
  });
}
