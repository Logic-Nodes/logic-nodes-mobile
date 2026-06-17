import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/application/controllers/session_controller.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/billing_repository.dart';

/// Billing module wired to the real backend (`/api/v1/billing/*`).
///
/// Loads the subscription snapshot and payment history for the authenticated
/// user, and links payment methods through the API.
class BillingController extends ChangeNotifier {
  BillingController({
    required this.billingRepository,
    required this.sessionController,
  });

  final BillingRepository billingRepository;
  final SessionController sessionController;

  Subscription? _subscription;
  List<PaymentRecord> _payments = const [];
  bool _isLoading = false;
  bool _isLinking = false;
  String? _errorMessage;

  Subscription? get subscription => _subscription;
  List<PaymentRecord> get payments => _payments;
  bool get isLoading => _isLoading;
  bool get isLinking => _isLinking;
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
    } on AppException catch (exception) {
      _errorMessage = exception.message;
    } on Exception {
      _errorMessage = 'Unable to load billing data from the backend.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> linkPaymentMethod(PaymentMethodDraft draft) async {
    final session = sessionController.session;
    if (session == null || _isLinking) {
      return false;
    }

    _isLinking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscription = await billingRepository.linkPaymentMethod(
        accessToken: session.accessToken,
        userId: session.user.id,
        draft: draft,
      );
      return true;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return false;
    } finally {
      _isLinking = false;
      notifyListeners();
    }
  }
}
