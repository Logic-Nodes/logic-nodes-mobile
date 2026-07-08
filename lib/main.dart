import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/demo/demo_tour.dart';
import 'core/network/api_client.dart';
import 'core/network/api_environment.dart';
import 'core/services/push_notification_service.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/storage/offline_cache_runner.dart';
import 'core/storage/offline_cache_store.dart';
import 'core/storage/persistent_session_store.dart';
import 'core/utils/app_theme.dart';
import 'features/auth/application/controllers/password_recovery_controller.dart';
import 'features/auth/application/controllers/register_controller.dart';
import 'features/auth/application/controllers/session_controller.dart';
import 'features/auth/application/use_cases/sign_in_use_case.dart';
import 'features/auth/data/datasources/remote_auth_datasource.dart';
import 'features/auth/data/repositories/remote_auth_repository.dart';
import 'features/alerts/application/controllers/alerts_controller.dart';
import 'features/alerts/data/datasources/remote_alert_datasource.dart';
import 'features/alerts/data/repositories/caching_alert_repository.dart';
import 'features/alerts/data/repositories/remote_alert_repository.dart';
import 'features/analytics/application/controllers/analytics_controller.dart';
import 'features/analytics/data/datasources/remote_analytics_datasource.dart';
import 'features/analytics/data/repositories/remote_analytics_repository.dart';
import 'features/billing/application/controllers/billing_controller.dart';
import 'features/billing/data/datasources/remote_billing_datasource.dart';
import 'features/billing/data/repositories/remote_billing_repository.dart';
import 'features/fleet/application/controllers/fleet_controller.dart';
import 'features/fleet/data/datasources/remote_fleet_datasource.dart';
import 'features/fleet/data/repositories/caching_fleet_repository.dart';
import 'features/fleet/data/repositories/remote_fleet_repository.dart';
import 'features/home/application/controllers/home_controller.dart';
import 'features/home/data/datasources/remote_home_datasource.dart';
import 'features/home/data/repositories/caching_home_repository.dart';
import 'features/home/data/repositories/remote_home_repository.dart';
import 'features/profile/application/controllers/profile_controller.dart';
import 'features/profile/data/datasources/remote_profile_datasource.dart';
import 'features/profile/data/repositories/remote_profile_repository.dart';
import 'features/trips/application/controllers/trips_controller.dart';
import 'features/trips/data/datasources/remote_trips_datasource.dart';
import 'features/trips/data/repositories/caching_trips_repository.dart';
import 'features/trips/data/repositories/remote_trips_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final SessionController sessionController;
  final apiClient = ApiClient(
    baseUrl: ApiEnvironment.baseUrl,
    timeout: const Duration(seconds: 45),
    getAccessToken: () => sessionController.accessToken,
    onUnauthorized: () => sessionController.tryRefreshSession(),
  );

  final authRepository = RemoteAuthRepository(
    datasource: RemoteAuthDatasource(
      apiClient: apiClient,
    ),
  );
  final offlineCacheStore = OfflineCacheStore();
  final offlineCacheRunner = OfflineCacheRunner(store: offlineCacheStore);
  sessionController = SessionController(
    sessionStore: PersistentSessionStore(),
    authRepository: authRepository,
    offlineCacheStore: offlineCacheStore,
  );

  final remoteHomeRepository = RemoteHomeRepository(
    datasource: RemoteHomeDatasource(
      apiClient: apiClient,
    ),
  );
  final homeRepository = CachingHomeRepository(
    remote: remoteHomeRepository,
    cacheRunner: offlineCacheRunner,
  );
  final remoteAlertRepository = RemoteAlertRepository(
    datasource: RemoteAlertDatasource(
      apiClient: apiClient,
    ),
  );
  final alertRepository = CachingAlertRepository(
    remote: remoteAlertRepository,
    cacheRunner: offlineCacheRunner,
    userIdResolver: () => sessionController.session?.user.id,
  );
  final billingRepository = RemoteBillingRepository(
    datasource: RemoteBillingDatasource(
      apiClient: apiClient,
    ),
  );
  final analyticsRepository = RemoteAnalyticsRepository(
    datasource: RemoteAnalyticsDatasource(
      apiClient: apiClient,
    ),
  );
  final remoteTripsRepository = RemoteTripsRepository(
    datasource: RemoteTripsDatasource(
      apiClient: apiClient,
    ),
  );
  final tripsRepository = CachingTripsRepository(
    remote: remoteTripsRepository,
    cacheRunner: offlineCacheRunner,
    userIdResolver: () => sessionController.session?.user.id,
  );
  final profileRepository = RemoteProfileRepository(
    datasource: RemoteProfileDatasource(
      apiClient: apiClient,
    ),
  );
  final remoteFleetRepository = RemoteFleetRepository(
    datasource: RemoteFleetDatasource(
      apiClient: apiClient,
    ),
  );
  final fleetRepository = CachingFleetRepository(
    remote: remoteFleetRepository,
    cacheRunner: offlineCacheRunner,
    userIdResolver: () => sessionController.session?.user.id,
  );

  final billingController = BillingController(
    billingRepository: billingRepository,
    sessionController: sessionController,
  );
  final analyticsController = AnalyticsController(
    analyticsRepository: analyticsRepository,
    sessionController: sessionController,
  );

  await sessionController.restore();

  final pushNotificationService = PushNotificationService(apiClient: apiClient);
  await pushNotificationService.initialize();

  Future<void> syncPushToken() async {
    final userId = sessionController.session?.user.id;
    if (userId != null) {
      await pushNotificationService.syncTokenForUser(userId);
    }
  }

  sessionController.addListener(() {
    syncPushToken();
  });
  await syncPushToken();

  if (kDemoAutoLogin && kDebugMode && !sessionController.isAuthenticated) {
    try {
      final session = await SignInUseCase(authRepository).call(
        email: demoEmail,
        password: demoPassword,
      );
      await sessionController.open(session);
    } on Exception catch (error) {
      debugPrint('DEMO_AUTO_LOGIN failed: $error');
    }
  }

  final initialRoute = sessionController.isAuthenticated
      ? AppRoutes.home
      : AppRoutes.login;

  final navigatorKey = GlobalKey<NavigatorState>();

  runApp(
    OmniTrackApp(
      navigatorKey: navigatorKey,
      demoTourEnabled:
          kDemoTour && kDebugMode && sessionController.isAuthenticated,
      router: AppRouter(
        initialRoute: initialRoute,
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
        fleetControllerFactory: () => FleetController(
          fleetRepository: fleetRepository,
          sessionController: sessionController,
        ),
        billingController: billingController,
        analyticsController: analyticsController,
        sessionController: sessionController,
        tripsControllerFactory: () => TripsController(
          tripsRepository: tripsRepository,
          sessionController: sessionController,
        ),
        profileControllerFactory: () => ProfileController(
          profileRepository: profileRepository,
          sessionController: sessionController,
        ),
      ),
    ),
  );
}

class OmniTrackApp extends StatelessWidget {
  const OmniTrackApp({
    required this.router,
    required this.navigatorKey,
    required this.demoTourEnabled,
    super.key,
  });

  final AppRouter router;
  final GlobalKey<NavigatorState> navigatorKey;
  final bool demoTourEnabled;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'OmniTrack',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: router.initialRoute,
      onGenerateRoute: router.onGenerateRoute,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!demoTourEnabled) {
          return content;
        }

        return DemoTourOverlay(
          navigatorKey: navigatorKey,
          enabled: demoTourEnabled,
          child: content,
        );
      },
    );
  }
}
