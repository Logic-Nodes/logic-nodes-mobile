import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/subscription_model.dart';

class RemoteBillingDatasource {
  RemoteBillingDatasource({
    required this.apiClient,
  });

  final ApiClient apiClient;

  Future<SubscriptionModel> getSubscription({
    required String accessToken,
    required String userId,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/v1/billing/$userId/subscription',
        headers: _authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );

      return SubscriptionModel.fromMap(_expectMap(response, 'subscription'));
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<List<PaymentRecordModel>> getPayments({
    required String accessToken,
    required String userId,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/v1/billing/$userId/payments',
        headers: _authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );

      final rows = _expectList(response, 'payments');
      return rows
          .whereType<Map<String, dynamic>>()
          .map(PaymentRecordModel.fromMap)
          .toList(growable: false);
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<SubscriptionModel> linkPaymentMethod({
    required String accessToken,
    required String userId,
    required String cardNumber,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/v1/billing/$userId/payment-method',
        headers: _authHeaders(accessToken),
        body: {
          'cardNumber': cardNumber,
        },
        expectedStatusCodes: const {200},
      );

      return SubscriptionModel.fromMap(_expectMap(response, 'subscription'));
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Map<String, String> _authHeaders(String accessToken) {
    return {
      'Authorization': 'Bearer $accessToken',
    };
  }

  List<Object?> _expectList(Object? value, String source) {
    if (value is List) {
      return value.cast<Object?>();
    }
    throw AppException('Unexpected response received from $source.');
  }

  Map<String, dynamic> _expectMap(Object? value, String source) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw AppException('Unexpected response received from $source.');
  }
}
