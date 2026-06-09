import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/storage/memory_store.dart';
import 'core/utils/app_theme.dart';
import 'features/auth/application/controllers/password_recovery_controller.dart';
import 'features/auth/application/controllers/register_controller.dart';
import 'features/auth/application/controllers/session_controller.dart';
import 'features/auth/application/use_cases/sign_in_use_case.dart';
import 'features/auth/data/datasources/mock_auth_datasource.dart';
import 'features/auth/data/repositories/mock_auth_repository.dart';
import 'features/auth/domain/entities/auth_session.dart';

void main() {
  final authRepository = MockAuthRepository(
    datasource: MockAuthDatasource(),
  );
  final sessionController = SessionController(
    sessionStore: MemoryStore<AuthSession>(),
    authRepository: authRepository,
  );

  runApp(
    OmniTrackApp(
      router: AppRouter(
        initialRoute: AppRoutes.login,
        signInUseCase: SignInUseCase(authRepository),
        registerControllerFactory:
            () => RegisterController(authRepository: authRepository),
        passwordRecoveryControllerFactory:
            () => PasswordRecoveryController(authRepository: authRepository),
        sessionController: sessionController,
      ),
    ),
  );
}

class OmniTrackApp extends StatelessWidget {
  const OmniTrackApp({
    required this.router,
    super.key,
  });

  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniTrack',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: router.initialRoute,
      onGenerateRoute: router.onGenerateRoute,
    );
  }
}
