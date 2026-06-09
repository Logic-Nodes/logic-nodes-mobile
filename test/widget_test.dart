import 'package:flutter_test/flutter_test.dart';
import 'package:logic_nodes_mobile/core/routing/app_router.dart';
import 'package:logic_nodes_mobile/core/routing/app_routes.dart';
import 'package:logic_nodes_mobile/core/storage/memory_store.dart';
import 'package:logic_nodes_mobile/features/auth/application/controllers/password_recovery_controller.dart';
import 'package:logic_nodes_mobile/features/auth/application/controllers/register_controller.dart';
import 'package:logic_nodes_mobile/features/auth/application/controllers/session_controller.dart';
import 'package:logic_nodes_mobile/features/auth/application/use_cases/sign_in_use_case.dart';
import 'package:logic_nodes_mobile/features/auth/data/datasources/mock_auth_datasource.dart';
import 'package:logic_nodes_mobile/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:logic_nodes_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:logic_nodes_mobile/features/home/application/controllers/home_controller.dart';
import 'package:logic_nodes_mobile/features/home/domain/entities/home_dashboard.dart';
import 'package:logic_nodes_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:logic_nodes_mobile/main.dart';

void main() {
  testWidgets('renders OmniTrack login flow', (tester) async {
    final repository = MockAuthRepository(
      datasource: MockAuthDatasource(),
    );
    final sessionController = SessionController(
      sessionStore: MemoryStore<AuthSession>(),
      authRepository: repository,
    );

    await tester.pumpWidget(
      OmniTrackApp(
        router: AppRouter(
          initialRoute: AppRoutes.login,
          signInUseCase: SignInUseCase(repository),
          registerControllerFactory:
              () => RegisterController(authRepository: repository),
          passwordRecoveryControllerFactory:
              () => PasswordRecoveryController(authRepository: repository),
          homeControllerFactory: () => HomeController(
            homeRepository: _FakeHomeRepository(),
            sessionController: sessionController,
          ),
          sessionController: sessionController,
        ),
      ),
    );

    expect(find.text('WELCOME'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Backend connection'), findsOneWidget);
  });
}

class _FakeHomeRepository implements HomeRepository {
  @override
  Future<HomeDashboard> loadDashboard({
    required String accessToken,
    required String userId,
    required String email,
    required bool isFleetManager,
  }) async {
    return HomeDashboard(
      trips: const [],
      alerts: const [],
      vehicles: const [],
      devices: const [],
      activeSessions: const [],
      loadedAt: DateTime(2026, 1, 1),
      scopeApplied: true,
    );
  }
}
