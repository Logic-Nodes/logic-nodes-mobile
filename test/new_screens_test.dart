import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logic_nodes_mobile/core/utils/app_theme.dart';
import 'package:logic_nodes_mobile/features/alerts/application/controllers/alerts_controller.dart';
import 'package:logic_nodes_mobile/features/alerts/domain/entities/alert.dart';
import 'package:logic_nodes_mobile/features/alerts/domain/repositories/alert_repository.dart';
import 'package:logic_nodes_mobile/features/auth/application/controllers/session_controller.dart';
import 'package:logic_nodes_mobile/features/auth/data/datasources/mock_auth_datasource.dart';
import 'package:logic_nodes_mobile/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:logic_nodes_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:logic_nodes_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:logic_nodes_mobile/features/billing/application/controllers/billing_controller.dart';
import 'package:logic_nodes_mobile/features/billing/domain/entities/subscription.dart';
import 'package:logic_nodes_mobile/features/billing/domain/repositories/billing_repository.dart';
import 'package:logic_nodes_mobile/features/billing/presentation/screens/subscription_screen.dart';
import 'package:logic_nodes_mobile/core/storage/memory_store.dart';

Future<SessionController> _signedInSession() async {
  final sessionController = SessionController(
    sessionStore: MemoryStore<AuthSession>(),
    authRepository: MockAuthRepository(datasource: MockAuthDatasource()),
  );
  await sessionController.open(
    AuthSession(
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
      user: const AuthUser(
        id: '1',
        name: 'Demo User',
        email: 'demo@omnitrack.io',
        role: UserRole.customer,
      ),
      expiresAt: DateTime(2026, 12, 31),
    ),
  );
  return sessionController;
}

void main() {
  testWidgets('Subscription screen renders the backend snapshot',
      (tester) async {
    final controller = BillingController(
      billingRepository: _FakeBillingRepository(),
      sessionController: await _signedInSession(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: SubscriptionScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('Subscription'), findsOneWidget);
    expect(find.textContaining('PROFESSIONAL'), findsOneWidget);
    expect(find.text('Add card'), findsOneWidget);
    expect(find.text('Upgrade your plan'), findsOneWidget);
  });

  test('BillingController loads snapshot and links a card via the repository',
      () async {
    final controller = BillingController(
      billingRepository: _FakeBillingRepository(),
      sessionController: await _signedInSession(),
    );

    await controller.load();
    expect(controller.subscription?.planName, 'PROFESSIONAL');
    expect(controller.subscription?.hasPaymentMethod, isFalse);
    expect(controller.payments.length, 2);

    final linked = await controller.linkPaymentMethod(
      const PaymentMethodDraft(
        cardNumber: '4242424242424242',
        expireDate: '12/28',
        cvc: '123',
        postalCode: '15001',
        country: 'Peru',
      ),
    );
    expect(linked, isTrue);
    expect(controller.subscription?.paymentMethodLabel, 'Card ending in 4242');
  });

  test('AlertsController loads, filters and resolves against the repository',
      () async {
    final authRepository =
        MockAuthRepository(datasource: MockAuthDatasource());
    final sessionController = SessionController(
      sessionStore: MemoryStore<AuthSession>(),
      authRepository: authRepository,
    );
    final session = await authRepository.signIn(
      email: 'client@omnitrack.io',
      password: 'Client123!',
    );
    await sessionController.open(session);

    final controller = AlertsController(
      alertRepository: _SeededAlertRepository(),
      sessionController: sessionController,
    );

    await controller.load();

    expect(controller.openCount, 1);
    expect(controller.acknowledgedCount, 1);
    expect(controller.resolvedCount, 1);
    expect(controller.visibleAlerts.length, 3);

    controller.changeFilter(AlertStatusFilter.resolved);
    expect(controller.visibleAlerts.length, 1);

    controller.changeFilter(AlertStatusFilter.all);
    controller.search('humidity');
    expect(controller.visibleAlerts.single.typeLabel, 'Humidity');

    controller.search('');
    final resolved = await controller.resolve('1');
    expect(resolved, isTrue);
    expect(controller.resolvedCount, 2);
  });
}

class _SeededAlertRepository implements AlertRepository {
  final List<Alert> _alerts = [
    Alert(id: '1', type: 'TEMPERATURE', status: AlertStatus.open),
    Alert(id: '2', type: 'HUMIDITY', status: AlertStatus.acknowledged),
    Alert(id: '3', type: 'VIBRATION', status: AlertStatus.closed),
  ];

  @override
  Future<List<Alert>> listAlerts({required String accessToken}) async =>
      List<Alert>.from(_alerts);

  @override
  Future<Alert> getAlert({
    required String accessToken,
    required String alertId,
  }) async =>
      _alerts.firstWhere((alert) => alert.id == alertId);

  @override
  Future<Alert> resolveAlert({
    required String accessToken,
    required String alertId,
  }) async =>
      Alert(id: alertId, type: 'TEMPERATURE', status: AlertStatus.closed);

  @override
  Future<Alert> acknowledgeAlert({
    required String accessToken,
    required String alertId,
  }) async =>
      Alert(id: alertId, type: 'TEMPERATURE', status: AlertStatus.acknowledged);
}

class _FakeBillingRepository implements BillingRepository {
  String? _cardLabel;

  @override
  Future<BillingSnapshot> loadBilling({
    required String accessToken,
    required String userId,
  }) async {
    return BillingSnapshot(
      subscription: Subscription(
        planName: 'PROFESSIONAL',
        amountLabel: r'$79.00/month',
        status: 'ACTIVE',
        renewalLabel: '07/16/2026',
        paymentMethodLabel: _cardLabel,
      ),
      payments: const [
        PaymentRecord(
          date: '06/16/2026',
          amountLabel: r'$79.00',
          status: 'PAID',
          transactionId: 'TXN-1-0001',
        ),
        PaymentRecord(
          date: '05/16/2026',
          amountLabel: r'$79.00',
          status: 'PAID',
          transactionId: 'TXN-1-0002',
        ),
      ],
    );
  }

  @override
  Future<Subscription> linkPaymentMethod({
    required String accessToken,
    required String userId,
    required PaymentMethodDraft draft,
  }) async {
    _cardLabel = draft.maskedLabel;
    return Subscription(
      planName: 'PROFESSIONAL',
      amountLabel: r'$79.00/month',
      status: 'ACTIVE',
      renewalLabel: '07/16/2026',
      paymentMethodLabel: _cardLabel,
    );
  }
}
