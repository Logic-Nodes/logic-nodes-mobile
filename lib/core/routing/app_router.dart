import 'package:flutter/material.dart';

import '../../features/auth/application/controllers/login_controller.dart';
import '../../features/auth/application/controllers/password_recovery_controller.dart';
import '../../features/auth/application/controllers/register_controller.dart';
import '../../features/auth/application/controllers/session_controller.dart';
import '../../features/auth/application/use_cases/sign_in_use_case.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/password_recovery_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/application/controllers/home_controller.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter({
    required this.initialRoute,
    required this.signInUseCase,
    required this.registerControllerFactory,
    required this.passwordRecoveryControllerFactory,
    required this.homeControllerFactory,
    required this.sessionController,
  });

  final String initialRoute;
  final SignInUseCase signInUseCase;
  final RegisterController Function() registerControllerFactory;
  final PasswordRecoveryController Function()
      passwordRecoveryControllerFactory;
  final HomeController Function() homeControllerFactory;
  final SessionController sessionController;

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
