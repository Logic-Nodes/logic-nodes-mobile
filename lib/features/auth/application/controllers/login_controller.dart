import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../use_cases/sign_in_use_case.dart';
import 'session_controller.dart';

class LoginController extends ChangeNotifier {
  LoginController({
    required this.signInUseCase,
    required this.sessionController,
  });

  final SignInUseCase signInUseCase;
  final SessionController sessionController;

  bool rememberMe = true;
  bool isSubmitting = false;
  String? errorMessage;

  void toggleRememberMe(bool? value) {
    rememberMe = value ?? false;
    notifyListeners();
  }

  Future<AuthSession?> signIn({
    required String email,
    required String password,
  }) async {
    isSubmitting = true;
    errorMessage = null;
      notifyListeners();

    try {
      final session = await signInUseCase(
        email: email,
        password: password,
      );

      await sessionController.open(session);
      return session;
    } on AppException catch (exception) {
      errorMessage = exception.message;
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
