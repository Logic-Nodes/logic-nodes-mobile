import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/application/controllers/session_controller.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/home_repository.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required this.homeRepository,
    required this.sessionController,
  });

  final HomeRepository homeRepository;
  final SessionController sessionController;

  HomeDashboard? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;

  HomeDashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
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
      _dashboard = await homeRepository.loadDashboard(
        accessToken: session.accessToken,
        userId: session.user.id,
        email: session.user.email,
        isFleetManager: session.user.role == UserRole.fleetManager,
      );
    } on AppException catch (exception) {
      _errorMessage = exception.message;
    } on Exception {
      _errorMessage =
          'Unable to load workspace data from the current backend.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
