import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/application/controllers/session_controller.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({
    required this.profileRepository,
    required this.sessionController,
  });

  final ProfileRepository profileRepository;
  final SessionController sessionController;

  UserProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
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
      _profile = await profileRepository.getProfileByUserId(
        accessToken: session.accessToken,
        userId: session.user.id,
      );
    } on AppException catch (exception) {
      _errorMessage = exception.message;
    } on Exception {
      _errorMessage = 'No se pudo cargar el perfil desde el backend.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    final session = sessionController.session;
    final profile = _profile;
    if (session == null || profile == null || _isSaving) {
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await profileRepository.updateProfile(
        accessToken: session.accessToken,
        profileId: profile.id,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phoneNumber: phoneNumber?.trim(),
      );
      return true;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
