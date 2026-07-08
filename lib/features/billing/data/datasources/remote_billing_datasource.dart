import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/subscription_model.dart';

class RemoteBillingDatasource {
  RemoteBillingDatasource({
    required this.apiClient,
  });

  final ApiClient apiClient;

  Future<List<PlanModel>> getPlans({
    required String accessToken,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/v1/plans',
        headers: _authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );
      return _expectList(response, 'plans')
          .whereType<Map<String, dynamic>>()
          .map(PlanModel.fromMap)
          .toList(growable: false);
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<SubscriptionModel> getSubscription({
    required String accessToken,
    required String userId,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/v1/subscription/user-id/$userId',
        headers: _authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );
      return SubscriptionModel.fromMap(_expectMap(response, 'subscription'));
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<List<PaymentModel>> getPayments({
    required String accessToken,
    required String userId,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/v1/payments/user-id/$userId',
        headers: _authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );
      return _expectList(response, 'payments')
          .whereType<Map<String, dynamic>>()
          .map(PaymentModel.fromMap)
          .toList(growable: false);
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<SubscriptionModel> changePlan({
    required String accessToken,
    required int subscriptionId,
    required int newPlanId,
  }) async {
    try {
      final response = await apiClient.put(
        '/api/v1/subscription/$subscriptionId/plan',
        headers: _authHeaders(accessToken),
        body: {'newPlanId': newPlanId},
        expectedStatusCodes: const {200},
      );
      return SubscriptionModel.fromMap(_expectMap(response, 'subscription'));
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<SubscriptionModel> cancelSubscription({
    required String accessToken,
    required int subscriptionId,
  }) async {
    try {
      final response = await apiClient.delete(
        '/api/v1/subscription/$subscriptionId',
        headers: _authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );
      return SubscriptionModel.fromMap(_expectMap(response, 'subscription'));
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Map<String, String> _authHeaders(String accessToken) {
    return {'Authorization': 'Bearer $accessToken'};
  }

  List<Object?> _expectList(Object? value, String source) {
    if (value is List) {
      return value.cast<Object?>();
    }
    throw AppException('Respuesta inesperada del servidor.');
  }

  Map<String, dynamic> _expectMap(Object? value, String source) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw AppException('Respuesta inesperada del servidor.');
  }
}
