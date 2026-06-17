import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/network/api_environment.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/storage/memory_store.dart';
import 'core/utils/app_theme.dart';
import 'features/auth/application/controllers/password_recovery_controller.dart';
import 'features/auth/application/controllers/register_controller.dart';
import 'features/auth/application/controllers/session_controller.dart';
import 'features/auth/application/use_cases/sign_in_use_case.dart';
import 'features/auth/data/datasources/remote_auth_datasource.dart';
import 'features/auth/data/repositories/remote_auth_repository.dart';
import 'features/auth/domain/entities/auth_session.dart';
import 'features/alerts/application/controllers/alerts_controller.dart';
import 'features/alerts/data/datasources/remote_alert_datasource.dart';
import 'features/alerts/data/repositories/remote_alert_repository.dart';
import 'features/billing/application/controllers/billing_controller.dart';
import 'features/billing/data/datasources/remote_billing_datasource.dart';
import 'features/billing/data/repositories/remote_billing_repository.dart';
import 'features/home/application/controllers/home_controller.dart';
import 'features/home/data/datasources/remote_home_datasource.dart';
import 'features/home/data/repositories/remote_home_repository.dart';

void main() {
  final apiClient = ApiClient(
    baseUrl: ApiEnvironment.baseUrl,
  );
  final authRepository = RemoteAuthRepository(
    datasource: RemoteAuthDatasource(
      apiClient: apiClient,
    ),
  );
  final homeRepository = RemoteHomeRepository(
    datasource: RemoteHomeDatasource(
      apiClient: apiClient,
    ),
  );
  final alertRepository = RemoteAlertRepository(
    datasource: RemoteAlertDatasource(
      apiClient: apiClient,
    ),
  );
  final billingRepository = RemoteBillingRepository(
    datasource: RemoteBillingDatasource(
      apiClient: apiClient,
    ),
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
        homeControllerFactory: () => HomeController(
          homeRepository: homeRepository,
          sessionController: sessionController,
        ),
        alertsControllerFactory: () => AlertsController(
          alertRepository: alertRepository,
          sessionController: sessionController,
        ),
        billingControllerFactory: () => BillingController(
          billingRepository: billingRepository,
          sessionController: sessionController,
        ),
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
