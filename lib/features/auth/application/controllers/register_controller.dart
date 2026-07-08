import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/auth_repository.dart';

enum RegistrationSegment {
  shippingCompany,
  client,
}

class RegisterController extends ChangeNotifier {
  RegisterController({
    required this.authRepository,
  });

  final AuthRepository authRepository;

  RegistrationSegment selectedSegment = RegistrationSegment.shippingCompany;
  bool isSubmitting = false;
  String? feedbackMessage;
  bool isSuccess = false;

  void selectSegment(RegistrationSegment segment) {
    selectedSegment = segment;
    feedbackMessage = null;
    isSuccess = false;
    notifyListeners();
  }

  Future<bool> submitCompany({
    required String companyContactEmail,
    required String legalName,
    required String taxId,
    required String fiscalAddress,
    required String adminFirstName,
    required String adminLastName,
    required String adminEmail,
    required String password,
  }) async {
    return _run(
      action: () => authRepository.registerCompany(
        companyContactEmail: companyContactEmail.trim(),
        legalName: legalName.trim(),
        taxId: taxId.trim(),
        fiscalAddress: fiscalAddress.trim(),
        adminFirstName: adminFirstName.trim(),
        adminLastName: adminLastName.trim(),
        adminEmail: adminEmail.trim(),
        password: password,
      ),
      successMessage:
          'Cuenta de empresa creada. Puedes iniciar sesión con la cuenta del administrador.',
    );
  }

  Future<bool> submitClient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    return _run(
      action: () => authRepository.registerClient(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        password: password,
      ),
      successMessage:
          'Cuenta de cliente creada. Usa tus nuevas credenciales para acceder a OmniTrack.',
    );
  }

  Future<bool> _run({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    isSubmitting = true;
    feedbackMessage = null;
    isSuccess = false;
    notifyListeners();

    try {
      await action();
      isSuccess = true;
      feedbackMessage = successMessage;
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
