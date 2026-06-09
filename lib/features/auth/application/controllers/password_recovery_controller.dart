import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/auth_repository.dart';

enum PasswordRecoveryStage {
  request,
  reset,
}

class PasswordRecoveryController extends ChangeNotifier {
  PasswordRecoveryController({
    required this.authRepository,
  });

  final AuthRepository authRepository;

  PasswordRecoveryStage stage = PasswordRecoveryStage.request;
  bool isSubmitting = false;
  String? feedbackMessage;
  bool isSuccess = false;

  Future<bool> requestRecovery(String email) async {
    return _run(
      action: () => authRepository.requestPasswordReset(email: email.trim()),
      onSuccess: () {
        stage = PasswordRecoveryStage.reset;
        feedbackMessage =
            'Recovery instructions sent. Create your new password to complete the demo flow.';
      },
    );
  }

  Future<bool> resetPassword(String password) async {
    return _run(
      action: () => authRepository.resetPassword(password: password),
      onSuccess: () {
        isSuccess = true;
        feedbackMessage =
            'Password updated successfully. You can sign in again now.';
      },
    );
  }

  Future<bool> _run({
    required Future<void> Function() action,
    required VoidCallback onSuccess,
  }) async {
    isSubmitting = true;
    feedbackMessage = null;
    isSuccess = false;
    notifyListeners();

    try {
      await action();
      onSuccess();
      return true;
    } on AppException catch (exception) {
      feedbackMessage = exception.message;
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
