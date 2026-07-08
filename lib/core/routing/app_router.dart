import 'package:flutter/material.dart';

import '../../features/auth/application/controllers/login_controller.dart';
import '../../features/auth/application/controllers/password_recovery_controller.dart';
import '../../features/auth/application/controllers/register_controller.dart';
import '../../features/auth/application/controllers/session_controller.dart';
import '../../features/auth/application/use_cases/sign_in_use_case.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/password_recovery_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/alerts/application/controllers/alerts_controller.dart';
import '../../features/alerts/presentation/screens/alerts_screen.dart';
import '../../features/analytics/application/controllers/analytics_controller.dart';
import '../../features/analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../../features/analytics/presentation/screens/trip_analytics_detail_screen.dart';
import '../../features/billing/application/controllers/billing_controller.dart';
import '../../features/billing/presentation/screens/subscription_screen.dart';
import '../../features/fleet/application/controllers/fleet_controller.dart';
import '../../features/fleet/presentation/screens/devices_screen.dart';
import '../../features/fleet/presentation/screens/vehicles_screen.dart';
import '../../features/home/application/controllers/home_controller.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/application/controllers/profile_controller.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/trips/application/controllers/trips_controller.dart';
import '../../features/trips/presentation/screens/public_tracking_screen.dart';
import '../../features/trips/presentation/screens/trip_detail_screen.dart';
import '../../features/trips/presentation/screens/trip_form_screen.dart';
import '../../features/trips/presentation/screens/trip_reschedule_screen.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter({
    required this.initialRoute,
    required this.signInUseCase,
    required this.registerControllerFactory,
    required this.passwordRecoveryControllerFactory,
    required this.homeControllerFactory,
    required this.alertsControllerFactory,
    required this.fleetControllerFactory,
    required this.analyticsController,
    required this.billingController,
    required this.sessionController,
    required this.tripsControllerFactory,
    required this.profileControllerFactory,
  });

  final String initialRoute;
  final SignInUseCase signInUseCase;
  final RegisterController Function() registerControllerFactory;
  final PasswordRecoveryController Function()
      passwordRecoveryControllerFactory;
  final HomeController Function() homeControllerFactory;
  final AlertsController Function() alertsControllerFactory;
  final FleetController Function() fleetControllerFactory;
  final AnalyticsController analyticsController;
  final BillingController billingController;
  final SessionController sessionController;
  final TripsController Function() tripsControllerFactory;
  final ProfileController Function() profileControllerFactory;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          builder: (_) => LoginScreen(
            controller: LoginController(
              signInUseCase: signInUseCase,
              sessionController: sessionController,
            ),
          ),
          settings: settings,
        );
      case AppRoutes.register:
        return MaterialPageRoute<void>(
          builder: (_) => RegisterScreen(
            controller: registerControllerFactory(),
          ),
          settings: settings,
        );
      case AppRoutes.passwordRecovery:
        return MaterialPageRoute<void>(
          builder: (_) => PasswordRecoveryScreen(
            controller: passwordRecoveryControllerFactory(),
          ),
          settings: settings,
        );
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          builder: (_) => HomeScreen(
            controller: homeControllerFactory(),
            sessionController: sessionController,
            billingController: billingController,
          ),
          settings: settings,
        );
      case AppRoutes.alerts:
        return MaterialPageRoute<void>(
          builder: (_) => AlertsScreen(
            controller: alertsControllerFactory(),
          ),
          settings: settings,
        );
      case AppRoutes.fleetVehicles:
        return MaterialPageRoute<void>(
          builder: (_) => VehiclesScreen(
            controller: fleetControllerFactory(),
          ),
          settings: settings,
        );
      case AppRoutes.fleetDevices:
        return MaterialPageRoute<void>(
          builder: (_) => DevicesScreen(
            controller: fleetControllerFactory(),
          ),
          settings: settings,
        );
      case AppRoutes.subscription:
        return MaterialPageRoute<void>(
          builder: (_) => SubscriptionScreen(
            controller: billingController,
          ),
          settings: settings,
        );
      case AppRoutes.analytics:
        return MaterialPageRoute<void>(
          builder: (_) => AnalyticsDashboardScreen(
            controller: analyticsController,
          ),
          settings: settings,
        );
      case AppRoutes.analyticsTrips:
        return MaterialPageRoute<void>(
          builder: (_) => AnalyticsTripsScreen(
            controller: analyticsController,
          ),
          settings: settings,
        );
      case AppRoutes.analyticsTripDetail:
        final tripId = settings.arguments;
        if (tripId is! String || tripId.isEmpty) {
          return MaterialPageRoute<void>(
            builder: (_) => AnalyticsDashboardScreen(
              controller: analyticsController,
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => TripAnalyticsDetailScreen(
            controller: analyticsController,
            tripId: tripId,
          ),
          settings: settings,
        );
      case AppRoutes.trips:
        return MaterialPageRoute<void>(
          builder: (_) => TripsScreen(
            controller: tripsControllerFactory(),
          ),
          settings: settings,
        );
      case AppRoutes.tripForm:
        return MaterialPageRoute<void>(
          builder: (_) => TripFormScreen(
            controller: tripsControllerFactory(),
          ),
          settings: settings,
        );
      case AppRoutes.tripDetail:
        final tripId = settings.arguments;
        if (tripId is! String || tripId.isEmpty) {
          return MaterialPageRoute<void>(
            builder: (_) => TripsScreen(
              controller: tripsControllerFactory(),
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => TripDetailScreen(
            controller: tripsControllerFactory(),
            tripId: tripId,
          ),
          settings: settings,
        );
      case AppRoutes.tripReschedule:
        final tripId = settings.arguments;
        if (tripId is! String || tripId.isEmpty) {
          return MaterialPageRoute<void>(
            builder: (_) => TripsScreen(
              controller: tripsControllerFactory(),
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => TripRescheduleScreen(
            controller: tripsControllerFactory(),
            tripId: tripId,
          ),
          settings: settings,
        );
      case AppRoutes.publicTracking:
        final initialCode = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => PublicTrackingScreen(
            controller: tripsControllerFactory(),
            initialCode: initialCode is String ? initialCode : null,
          ),
          settings: settings,
        );
      case AppRoutes.profile:
        return MaterialPageRoute<void>(
          builder: (_) => ProfileScreen(
            controller: profileControllerFactory(),
            sessionController: sessionController,
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => LoginScreen(
            controller: LoginController(
              signInUseCase: signInUseCase,
              sessionController: sessionController,
            ),
          ),
          settings: settings,
        );
    }
  }
}
