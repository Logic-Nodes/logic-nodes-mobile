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

    return BillingSnapshot(
      subscription: subscription.toDomain(),
      payments:
          payments.map((model) => model.toDomain()).toList(growable: false),
    );
  }

  @override
  Future<Subscription> linkPaymentMethod({
    required String accessToken,
    required String userId,
    required PaymentMethodDraft draft,
  }) async {
    final model = await datasource.linkPaymentMethod(
      accessToken: accessToken,
      userId: userId,
      cardNumber: draft.cardNumber,
    );

    return model.toDomain();
  }
}
