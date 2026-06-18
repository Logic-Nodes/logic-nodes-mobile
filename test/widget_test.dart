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
import 'package:logic_nodes_mobile/features/alerts/application/controllers/alerts_controller.dart';
import 'package:logic_nodes_mobile/features/alerts/domain/entities/alert.dart';
import 'package:logic_nodes_mobile/features/alerts/domain/repositories/alert_repository.dart';
import 'package:logic_nodes_mobile/features/billing/application/controllers/billing_controller.dart';
import 'package:logic_nodes_mobile/features/billing/domain/entities/subscription.dart';
import 'package:logic_nodes_mobile/features/billing/domain/repositories/billing_repository.dart';
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
          alertsControllerFactory: () => AlertsController(
            alertRepository: _FakeAlertRepository(),
            sessionController: sessionController,
          ),
          billingControllerFactory: () => BillingController(
            billingRepository: _FakeBillingRepository(),
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

class _FakeAlertRepository implements AlertRepository {
  @override
  Future<List<Alert>> listAlerts({required String accessToken}) async => const [];

  @override
  Future<Alert> getAlert({
    required String accessToken,
    required String alertId,
  }) async =>
      Alert(id: alertId, type: 'OTHER', status: AlertStatus.open);

  @override
  Future<Alert> resolveAlert({
    required String accessToken,
    required String alertId,
  }) async =>
      Alert(id: alertId, type: 'OTHER', status: AlertStatus.closed);

  @override
  Future<Alert> acknowledgeAlert({
    required String accessToken,
    required String alertId,
  }) async =>
      Alert(id: alertId, type: 'OTHER', status: AlertStatus.acknowledged);
}

class _FakeBillingRepository implements BillingRepository {
  static const _plan = Plan(
    id: 2,
    name: 'PROFESSIONAL',
    limits: 'Up to 25 vehicles',
    price: 79,
    description: 'Advanced monitoring.',
  );

  @override
  Future<BillingSnapshot> loadBilling({
    required String accessToken,
    required String userId,
  }) async {
    return const BillingSnapshot(
      subscription: Subscription(
        id: 1,
        status: 'ACTIVE',
        renewal: '2026-07-17',
        paymentMethod: '',
        plan: _plan,
      ),
      plans: [_plan],
      payments: [],
    );
  }

  @override
  Future<Subscription> changePlan({
    required String accessToken,
    required int subscriptionId,
    required int newPlanId,
  }) async {
    return const Subscription(
      id: 1,
      status: 'ACTIVE',
      renewal: '2026-07-17',
      paymentMethod: '',
      plan: _plan,
    );
  }

  @override
  Future<Subscription> cancelSubscription({
    required String accessToken,
    required int subscriptionId,
  }) async {
    return const Subscription(
      id: 1,
      status: 'CANCELED',
      renewal: '2026-07-17',
      paymentMethod: '',
      plan: _plan,
    );
  }
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
