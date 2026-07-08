import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/application/controllers/session_controller.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/billing_repository.dart';

/// Billing module wired to the backend contract
/// (`/plans`, `/subscription/user-id/:id`, `/subscription/:id/plan`,
/// `/subscription/:id`, `/payments/user-id/:id`).
class BillingController extends ChangeNotifier {
  BillingController({
    required this.billingRepository,
    required this.sessionController,
  });

  final BillingRepository billingRepository;
  final SessionController sessionController;

  Subscription? _subscription;
  List<Payment> _payments = const [];
  List<Plan> _plans = const [];
  bool _isLoading = false;
  bool _isMutating = false;
  String? _errorMessage;

  Subscription? get subscription => _subscription;
  List<Payment> get payments => _payments;
  List<Plan> get plans => _plans;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    final session = sessionController.session;
    if (session == null || _isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await billingRepository.loadBilling(
        accessToken: session.accessToken,
        userId: session.user.id,
      );
      _subscription = snapshot.subscription;
      _payments = snapshot.payments;
      _plans = snapshot.plans;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
    } on Exception {
      _errorMessage = 'No se pudieron cargar los datos de facturación desde el backend.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePlan(int newPlanId) async {
    return _mutate(
      (session, subscription) => billingRepository.changePlan(
        accessToken: session.accessToken,
        subscriptionId: subscription.id,
        newPlanId: newPlanId,
      ),
    );
  }

  Future<bool> cancelSubscription() async {
    return _mutate(
      (session, subscription) => billingRepository.cancelSubscription(
        accessToken: session.accessToken,
        subscriptionId: subscription.id,
      ),
    );
  }

  Future<bool> _mutate(
    Future<Subscription> Function(dynamic session, Subscription subscription)
        action,
  ) async {
    final session = sessionController.session;
    final current = _subscription;
    if (session == null || current == null || _isMutating) {
      return false;
    }

    _isMutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscription = await action(session, current);
      return true;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
