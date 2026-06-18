import '../../domain/entities/subscription.dart';
import '../../domain/repositories/billing_repository.dart';
import '../datasources/remote_billing_datasource.dart';

class RemoteBillingRepository implements BillingRepository {
  const RemoteBillingRepository({
    required this.datasource,
  });

  final RemoteBillingDatasource datasource;

  @override
  Future<BillingSnapshot> loadBilling({
    required String accessToken,
    required String userId,
  }) async {
    final subscription = await datasource.getSubscription(
      accessToken: accessToken,
      userId: userId,
    );
    final payments = await datasource.getPayments(
      accessToken: accessToken,
      userId: userId,
    );
    final plans = await datasource.getPlans(accessToken: accessToken);

    return BillingSnapshot(
      subscription: subscription.toDomain(),
      payments:
          payments.map((model) => model.toDomain()).toList(growable: false),
      plans: plans.map((model) => model.toDomain()).toList(growable: false),
    );
  }

  @override
  Future<Subscription> changePlan({
    required String accessToken,
    required int subscriptionId,
    required int newPlanId,
  }) async {
    final model = await datasource.changePlan(
      accessToken: accessToken,
      subscriptionId: subscriptionId,
      newPlanId: newPlanId,
    );
    return model.toDomain();
  }

  @override
  Future<Subscription> cancelSubscription({
    required String accessToken,
    required int subscriptionId,
  }) async {
    final model = await datasource.cancelSubscription(
      accessToken: accessToken,
      subscriptionId: subscriptionId,
    );
    return model.toDomain();
  }
}
