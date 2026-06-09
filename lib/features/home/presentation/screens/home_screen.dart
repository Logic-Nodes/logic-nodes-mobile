import 'package:flutter/material.dart';

import '../../../../core/network/api_environment.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/omnitrack_logo.dart';
import '../../../auth/application/controllers/session_controller.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/domain/entities/auth_user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.sessionController,
    super.key,
  });

  final SessionController sessionController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Future<void> _signOut() async {
    await widget.sessionController.signOut();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.sessionController.session;
    final user = session?.user;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      });

      return const SizedBox.shrink();
    }

    final destinations = _destinationsFor(user.role);
    final activeDestination = destinations[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OmnitrackLogo(
              foregroundColor: AppColors.ink,
              iconSize: 18,
              textSize: 20,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              activeDestination.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: _UserAvatar(name: user.name),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.background,
              AppColors.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.26, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey<_HomeTab>(activeDestination.tab),
              child: _buildTabContent(
                context,
                session: session!,
                user: user,
                tab: activeDestination.tab,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == _currentIndex) {
            return;
          }

          setState(() => _currentIndex = index);
        },
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context, {
    required AuthSession session,
    required AuthUser user,
    required _HomeTab tab,
  }) {
    return switch (tab) {
      _HomeTab.overview => _buildOverviewTab(context, user),
      _HomeTab.operations => _buildOperationsTab(context, user),
      _HomeTab.alerts => _buildAlertsTab(context, user),
      _HomeTab.billing => _buildBillingTab(context, user),
      _HomeTab.account => _buildAccountTab(context, session: session, user: user),
    };
  }

  Widget _buildOverviewTab(BuildContext context, AuthUser user) {
    final focusItems = _focusItemsFor(user.role);
    final modules = _modulesFor(user.role);

    return _ScrollablePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkspaceHero(
            title: 'Hola, ${user.name.split(' ').first}',
            description: user.role == UserRole.fleetManager
                ? 'Controla flota, cumplimiento de cadena de frio y respuesta operativa desde una sola vista.'
                : 'Sigue tus envios, revisa alertas y mantente al tanto del plan contratado.',
            roleLabel: user.role.label,
            companyLabel: user.companyName,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeading(
            title: 'Operational Snapshot',
            description: user.role == UserRole.fleetManager
                ? 'Indicadores del turno con foco en visibilidad y cumplimiento.'
                : 'Resumen rapido del estado actual de tus envios y servicio.',
          ),
          const SizedBox(height: AppSpacing.md),
          _MetricGrid(metrics: _metricsFor(user.role)),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Focus Today',
            description: 'Tareas y puntos de atencion ordenados por impacto.',
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in focusItems) ...[
            _FocusCard(item: item),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Workspace Access',
            description: 'Accesos visibles segun el rol autenticado.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final module in modules)
                _AccessChip(
                  icon: module.icon,
                  label: module.label,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsTab(BuildContext context, AuthUser user) {
    final cards = _routeCardsFor(user.role);
    final events = _timelineFor(user.role);
    final highlightStats = _operationsStatsFor(user.role);

    return _ScrollablePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBanner(
            title: user.role == UserRole.fleetManager
                ? 'Live Operations'
                : 'Shipment Progress',
            description: user.role == UserRole.fleetManager
                ? 'Seguimiento de rutas activas, disponibilidad y control de temperatura.'
                : 'Seguimiento de pedidos activos, hitos y proximos puntos de entrega.',
            accent: user.role == UserRole.fleetManager
                ? AppColors.primary
                : AppColors.secondary,
            icon: user.role == UserRole.fleetManager
                ? Icons.local_shipping_rounded
                : Icons.route_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeading(
            title: user.role == UserRole.fleetManager
                ? 'Routes In Motion'
                : 'Visible Shipments',
            description: user.role == UserRole.fleetManager
                ? 'Viajes con telemetria activa y estado consolidado.'
                : 'Pedidos activos con lectura de ruta y condicion actual.',
          ),
          const SizedBox(height: AppSpacing.md),
          for (final card in cards) ...[
            _ProgressCard(card: card),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Readiness Board',
            description: 'Capacidad operativa inmediata para el siguiente bloque.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final stat in highlightStats)
                _MiniStatCard(stat: stat),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Recent Activity',
            description: 'Eventos recientes del flujo visibles para el usuario actual.',
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  for (int index = 0; index < events.length; index++) ...[
                    _TimelineTile(
                      event: events[index],
                      isLast: index == events.length - 1,
                    ),
                    if (index != events.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab(BuildContext context, AuthUser user) {
    final alerts = _alertsFor(user.role);
    final summary = _alertSummaryFor(user.role);

    return _ScrollablePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBanner(
            title: 'Response Center',
            description: 'Alertas agrupadas por severidad para priorizar accion inmediata.',
            accent: AppColors.warning,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Alert Pipeline',
            description: 'Lectura operativa de criticidad, seguimiento y respuesta.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in summary)
                _MiniStatCard(stat: item),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final alert in alerts) ...[
            _AlertCard(alert: alert),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Immediate Actions',
            description: 'Siguientes pasos recomendados con base en el estado actual.',
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _ChecklistTile(
                    icon: Icons.thermostat_rounded,
                    title: 'Validar rango de temperatura en los vehiculos con alerta abierta.',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _ChecklistTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Notificar al responsable operativo antes del siguiente despacho.',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _ChecklistTile(
                    icon: Icons.fact_check_outlined,
                    title: 'Registrar evidencia y cierre para trazabilidad del incidente.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingTab(BuildContext context, AuthUser user) {
    final invoices = _billingRows();
    final usageStats = _billingUsageStats();

    return _ScrollablePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkspaceHero(
            title: 'Billing & Plan',
            description: 'Estado del plan, renovaciones y documentos de cobro asociados a la cuenta.',
            roleLabel: user.role.label,
            companyLabel: user.companyName ?? 'Customer workspace',
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OmniTrack Monitoring Pro',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Facturacion mensual con seguimiento en tiempo real y soporte operativo.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Row(
                    children: [
                      Expanded(
                        child: _KeyValueItem(
                          label: 'Status',
                          value: 'Active',
                        ),
                      ),
                      Expanded(
                        child: _KeyValueItem(
                          label: 'Renewal',
                          value: 'Jun 28',
                        ),
                      ),
                      Expanded(
                        child: _KeyValueItem(
                          label: 'Next charge',
                          value: 'USD 149',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Usage Snapshot',
            description: 'Consumo visible para el ciclo de facturacion actual.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final stat in usageStats)
                _MiniStatCard(stat: stat),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Recent Invoices',
            description: 'Ultimos comprobantes y estado de pago.',
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  for (int index = 0; index < invoices.length; index++) ...[
                    _InvoiceTile(invoice: invoices[index]),
                    if (index != invoices.length - 1)
                      const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTab(
    BuildContext context, {
    required AuthSession session,
    required AuthUser user,
  }) {
    final modules = _modulesFor(user.role);

    return _ScrollablePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UserAvatar(
                    name: user.name,
                    size: 60,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _PillTag(
                              label: user.role.label,
                              accent: AppColors.primary,
                            ),
                            if (user.companyName != null)
                              _PillTag(
                                label: user.companyName!,
                                accent: AppColors.secondary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Session Details',
            description: 'Datos visibles de la conexion actual y alcance de acceso.',
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Backend',
                    value: ApiEnvironment.baseUrl,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _DetailRow(
                    label: 'Docs',
                    value: ApiEnvironment.docsUrl,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _DetailRow(
                    label: 'Token expires',
                    value: _formatDateTime(session.expiresAt),
                  ),
                  const Divider(height: AppSpacing.lg),
                  _DetailRow(
                    label: 'Workspace',
                    value: user.companyName ?? 'Personal account',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Enabled Modules',
            description: 'Secciones visibles actualmente para este perfil.',
          ),
          const SizedBox(height: AppSpacing.md),
          for (final module in modules) ...[
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                leading: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(module.icon, color: AppColors.primary),
                ),
                title: Text(module.label),
                subtitle: Text(module.description),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  List<_HomeDestination> _destinationsFor(UserRole role) {
    switch (role) {
      case UserRole.fleetManager:
        return const [
          _HomeDestination(
            tab: _HomeTab.overview,
            label: 'Overview',
            subtitle: 'Operations command',
            icon: Icons.space_dashboard_outlined,
            selectedIcon: Icons.space_dashboard_rounded,
          ),
          _HomeDestination(
            tab: _HomeTab.operations,
            label: 'Fleet',
            subtitle: 'Fleet and trip tracking',
            icon: Icons.local_shipping_outlined,
            selectedIcon: Icons.local_shipping_rounded,
          ),
          _HomeDestination(
            tab: _HomeTab.alerts,
            label: 'Alerts',
            subtitle: 'Critical incidents and actions',
            icon: Icons.notifications_active_outlined,
            selectedIcon: Icons.notifications_active_rounded,
          ),
          _HomeDestination(
            tab: _HomeTab.account,
            label: 'Account',
            subtitle: 'Profile and access',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ];
      case UserRole.customer:
        return const [
          _HomeDestination(
            tab: _HomeTab.overview,
            label: 'Overview',
            subtitle: 'Shipment visibility',
            icon: Icons.space_dashboard_outlined,
            selectedIcon: Icons.space_dashboard_rounded,
          ),
          _HomeDestination(
            tab: _HomeTab.operations,
            label: 'Trips',
            subtitle: 'Routes and milestones',
            icon: Icons.route_outlined,
            selectedIcon: Icons.route_rounded,
          ),
          _HomeDestination(
            tab: _HomeTab.billing,
            label: 'Billing',
            subtitle: 'Plan and invoices',
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
          ),
          _HomeDestination(
            tab: _HomeTab.account,
            label: 'Account',
            subtitle: 'Profile and support',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ];
    }
  }

  List<_HomeModule> _modulesFor(UserRole role) {
    switch (role) {
      case UserRole.fleetManager:
        return const [
          _HomeModule(
            label: 'Dashboard',
            description: 'Vista ejecutiva con metricas en tiempo real.',
            icon: Icons.dashboard_outlined,
          ),
          _HomeModule(
            label: 'Fleet',
            description: 'Vehiculos, dispositivos y disponibilidad.',
            icon: Icons.local_shipping_outlined,
          ),
          _HomeModule(
            label: 'Trips',
            description: 'Rutas planificadas, activas y completadas.',
            icon: Icons.alt_route_rounded,
          ),
          _HomeModule(
            label: 'Alerts',
            description: 'Incidentes, severidad y tiempo de respuesta.',
            icon: Icons.warning_amber_rounded,
          ),
          _HomeModule(
            label: 'Monitoring',
            description: 'Sesiones de telemetria y trazabilidad.',
            icon: Icons.radar_outlined,
          ),
          _HomeModule(
            label: 'Billing',
            description: 'Plan contratado y facturacion del servicio.',
            icon: Icons.receipt_long_outlined,
          ),
        ];
      case UserRole.customer:
        return const [
          _HomeModule(
            label: 'Trips',
            description: 'Seguimiento de pedidos y entregas activas.',
            icon: Icons.route_rounded,
          ),
          _HomeModule(
            label: 'Alerts',
            description: 'Alertas asociadas al envio monitoreado.',
            icon: Icons.notifications_active_outlined,
          ),
          _HomeModule(
            label: 'Billing',
            description: 'Plan, renovaciones y comprobantes.',
            icon: Icons.receipt_long_outlined,
          ),
          _HomeModule(
            label: 'Profile',
            description: 'Datos de contacto y preferencias.',
            icon: Icons.person_outline_rounded,
          ),
        ];
    }
  }

  List<_MetricCardData> _metricsFor(UserRole role) {
    switch (role) {
      case UserRole.fleetManager:
        return const [
          _MetricCardData(
            label: 'Vehicles Online',
            value: '24',
            description: 'Unidades conectadas a telemetria.',
            icon: Icons.local_shipping_outlined,
            accent: AppColors.primary,
          ),
          _MetricCardData(
            label: 'Active Trips',
            value: '8',
            description: 'Rutas en progreso con monitoreo activo.',
            icon: Icons.route_outlined,
            accent: AppColors.secondary,
          ),
          _MetricCardData(
            label: 'Open Alerts',
            value: '3',
            description: 'Eventos que requieren seguimiento.',
            icon: Icons.warning_amber_rounded,
            accent: AppColors.warning,
          ),
          _MetricCardData(
            label: 'Compliance',
            value: '97%',
            description: 'Cumplimiento del rango de frio hoy.',
            icon: Icons.verified_outlined,
            accent: AppColors.success,
          ),
        ];
      case UserRole.customer:
        return const [
          _MetricCardData(
            label: 'Tracked Trips',
            value: '2',
            description: 'Envios visibles en tiempo real.',
            icon: Icons.route_outlined,
            accent: AppColors.primary,
          ),
          _MetricCardData(
            label: 'Stable Temp',
            value: '99%',
            description: 'Lecturas dentro del umbral esperado.',
            icon: Icons.thermostat_outlined,
            accent: AppColors.success,
          ),
          _MetricCardData(
            label: 'Open Alerts',
            value: '1',
            description: 'Incidente en seguimiento compartido.',
            icon: Icons.notification_important_outlined,
            accent: AppColors.warning,
          ),
          _MetricCardData(
            label: 'Plan Status',
            value: 'Active',
            description: 'Cuenta lista para el siguiente ciclo.',
            icon: Icons.workspace_premium_outlined,
            accent: AppColors.secondary,
          ),
        ];
    }
  }

  List<_FocusCardData> _focusItemsFor(UserRole role) {
    switch (role) {
      case UserRole.fleetManager:
        return const [
          _FocusCardData(
            title: 'Dispatch 04 leaves in 18 minutes',
            description: 'Validar que el sensor de temperatura del vehiculo V-18 mantenga rango estable antes de la salida.',
            icon: Icons.schedule_rounded,
            accent: AppColors.primary,
          ),
          _FocusCardData(
            title: '2 devices pending battery replacement',
            description: 'La visibilidad de telemetria podria degradarse si no se atiende en este turno.',
            icon: Icons.battery_alert_rounded,
            accent: AppColors.warning,
          ),
          _FocusCardData(
            title: 'Warehouse North still needs driver confirmation',
            description: 'Completar la asignacion para no afectar la ventana de entrega de la tarde.',
            icon: Icons.assignment_ind_outlined,
            accent: AppColors.secondary,
          ),
        ];
      case UserRole.customer:
        return const [
          _FocusCardData(
            title: 'Shipment LN-302 is entering delivery geofence',
            description: 'La unidad se encuentra en el tramo final y deberia completar entrega dentro del horario previsto.',
            icon: Icons.location_searching_rounded,
            accent: AppColors.primary,
          ),
          _FocusCardData(
            title: 'No temperature deviations in the last 6 hours',
            description: 'La cadena de frio se mantiene estable en los envios activos monitoreados.',
            icon: Icons.check_circle_outline_rounded,
            accent: AppColors.success,
          ),
          _FocusCardData(
            title: 'Subscription renewal opens in 4 days',
            description: 'Revisa el estado del plan y los comprobantes disponibles antes del corte.',
            icon: Icons.receipt_long_outlined,
            accent: AppColors.secondary,
          ),
        ];
    }
  }

  List<_ProgressCardData> _routeCardsFor(UserRole role) {
    switch (role) {
      case UserRole.fleetManager:
        return const [
          _ProgressCardData(
            title: 'Trip LN-204 / North Hub',
            subtitle: 'Van V-18 • Driver: Valeria Paredes',
            progress: 0.72,
            trailingLabel: 'ETA 12:40',
            tag: 'Cold chain stable',
            accent: AppColors.primary,
          ),
          _ProgressCardData(
            title: 'Trip LN-221 / Central Loop',
            subtitle: 'Truck T-04 • Driver: Luis Marquez',
            progress: 0.46,
            trailingLabel: 'ETA 13:05',
            tag: '1 alert acknowledged',
            accent: AppColors.warning,
          ),
          _ProgressCardData(
            title: 'Trip LN-228 / South Route',
            subtitle: 'Truck T-11 • Driver: Carla Nunez',
            progress: 0.83,
            trailingLabel: 'ETA 12:12',
            tag: 'On-time',
            accent: AppColors.success,
          ),
        ];
      case UserRole.customer:
        return const [
          _ProgressCardData(
            title: 'Order LN-302',
            subtitle: 'Route to Miraflores • Device IMEI 9842',
            progress: 0.81,
            trailingLabel: 'ETA 11:55',
            tag: '2.8°C stable',
            accent: AppColors.primary,
          ),
          _ProgressCardData(
            title: 'Order LN-318',
            subtitle: 'Route to San Isidro • Device IMEI 7621',
            progress: 0.58,
            trailingLabel: 'ETA 13:20',
            tag: 'Checkpoint reached',
            accent: AppColors.secondary,
          ),
        ];
    }
  }

  List<_MiniStatData> _operationsStatsFor(UserRole role) {
    switch (role) {
      case UserRole.fleetManager:
        return const [
          _MiniStatData(
            label: 'Ready Units',
            value: '14',
            icon: Icons.inventory_2_outlined,
            accent: AppColors.primary,
          ),
          _MiniStatData(
            label: 'Drivers On Shift',
            value: '11',
            icon: Icons.badge_outlined,
            accent: AppColors.secondary,
          ),
          _MiniStatData(
            label: 'Sensors Healthy',
            value: '96%',
            icon: Icons.sensors_outlined,
            accent: AppColors.success,
          ),
        ];
      case UserRole.customer:
        return const [
          _MiniStatData(
            label: 'Upcoming Stops',
            value: '3',
            icon: Icons.flag_outlined,
            accent: AppColors.primary,
          ),
          _MiniStatData(
            label: 'Shared Contacts',
            value: '2',
            icon: Icons.groups_outlined,
            accent: AppColors.secondary,
          ),
          _MiniStatData(
            label: 'Alert SLA',
            value: '< 5m',
            icon: Icons.timer_outlined,
            accent: AppColors.success,
          ),
        ];
    }
  }

  List<_TimelineEvent> _timelineFor(UserRole role) {
    switch (role) {
      case UserRole.fleetManager:
        return const [
          _TimelineEvent(
            time: '10:12',
            title: 'Vehicle V-18 left Warehouse North',
            description: 'Monitoreo iniciado con telemetria disponible.',
            accent: AppColors.primary,
          ),
          _TimelineEvent(
            time: '10:28',
            title: 'Alert acknowledged on Trip LN-221',
            description: 'Temperatura corregida y seguimiento en curso.',
            accent: AppColors.warning,
          ),
          _TimelineEvent(
            time: '10:41',
            title: 'Device IMEI 7621 synced successfully',
            description: 'Buffer de eventos subido sin perdida de lecturas.',
            accent: AppColors.success,
          ),
        ];
      case UserRole.customer:
        return const [
          _TimelineEvent(
            time: '09:54',
            title: 'Order LN-302 entered route midpoint',
            description: 'La unidad mantiene velocidad y temperatura esperadas.',
            accent: AppColors.primary,
          ),
          _TimelineEvent(
            time: '10:07',
            title: 'Checkpoint signed by operator',
            description: 'Se confirmo el tramo siguiente del envio compartido.',
            accent: AppColors.secondary,
          ),
          _TimelineEvent(
            time: '10:39',
            title: 'Delivery window remains on schedule',
            description: 'No hay alertas nuevas que afecten la entrega.',
            accent: AppColors.success,
          ),
        ];
    }
  }

  List<_MiniStatData> _alertSummaryFor(UserRole role) {
    switch (role) {
      case UserRole.fleetManager:
        return const [
          _MiniStatData(
            label: 'Critical',
            value: '1',
            icon: Icons.priority_high_rounded,
            accent: AppColors.danger,
          ),
          _MiniStatData(
            label: 'Acknowledged',
            value: '2',
            icon: Icons.rule_folder_outlined,
            accent: AppColors.warning,
          ),
          _MiniStatData(
            label: 'Resolved Today',
            value: '5',
            icon: Icons.task_alt_rounded,
            accent: AppColors.success,
          ),
        ];
      case UserRole.customer:
        return const [
          _MiniStatData(
            label: 'Open',
            value: '1',
            icon: Icons.notification_important_outlined,
            accent: AppColors.warning,
          ),
          _MiniStatData(
            label: 'Shared',
            value: '2',
            icon: Icons.people_outline_rounded,
            accent: AppColors.primary,
          ),
          _MiniStatData(
            label: 'Resolved',
            value: '4',
            icon: Icons.check_circle_outline_rounded,
            accent: AppColors.success,
          ),
        ];
    }
  }

  List<_AlertCardData> _alertsFor(UserRole role) {
    switch (role) {
      case UserRole.fleetManager:
        return const [
          _AlertCardData(
            severity: 'Critical',
            title: 'Temperature spike on Trip LN-221',
            description: 'Lectura de 8.1°C por encima del rango objetivo durante 4 minutos.',
            timestamp: 'Updated 6 min ago',
            accent: AppColors.danger,
          ),
          _AlertCardData(
            severity: 'Medium',
            title: 'Device battery low on Vehicle V-09',
            description: 'Reemplazo recomendado antes del siguiente despacho programado.',
            timestamp: 'Updated 18 min ago',
            accent: AppColors.warning,
          ),
          _AlertCardData(
            severity: 'Info',
            title: 'Route checkpoint skipped automatically',
            description: 'El viaje continuo sin detenerse por una geocerca intermedia configurada.',
            timestamp: 'Updated 24 min ago',
            accent: AppColors.secondary,
          ),
        ];
      case UserRole.customer:
        return const [
          _AlertCardData(
            severity: 'Open',
            title: 'Minor delay on Order LN-318',
            description: 'El trafico en ruta desplazo la llegada estimada 12 minutos.',
            timestamp: 'Updated 4 min ago',
            accent: AppColors.warning,
          ),
          _AlertCardData(
            severity: 'Resolved',
            title: 'Temperature drift corrected',
            description: 'La lectura volvio a rango sin comprometer la condicion del envio.',
            timestamp: 'Resolved 52 min ago',
            accent: AppColors.success,
          ),
        ];
    }
  }

  List<_InvoiceRowData> _billingRows() {
    return const [
      _InvoiceRowData(
        code: 'INV-2026-051',
        amount: 'USD 149',
        dueLabel: 'Paid on Jun 01',
        status: 'Paid',
        accent: AppColors.success,
      ),
      _InvoiceRowData(
        code: 'INV-2026-050',
        amount: 'USD 149',
        dueLabel: 'Due on Jun 28',
        status: 'Pending',
        accent: AppColors.warning,
      ),
      _InvoiceRowData(
        code: 'INV-2026-049',
        amount: 'USD 149',
        dueLabel: 'Paid on Apr 30',
        status: 'Paid',
        accent: AppColors.success,
      ),
    ];
  }

  List<_MiniStatData> _billingUsageStats() {
    return const [
      _MiniStatData(
        label: 'Active trips',
        value: '2',
        icon: Icons.route_outlined,
        accent: AppColors.primary,
      ),
      _MiniStatData(
        label: 'Alert channels',
        value: '3',
        icon: Icons.notifications_outlined,
        accent: AppColors.secondary,
      ),
      _MiniStatData(
        label: 'Renewal risk',
        value: 'Low',
        icon: Icons.health_and_safety_outlined,
        accent: AppColors.success,
      ),
    ];
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '${_monthLabel(local.month)} ${local.day}, $hours:$minutes';
  }

  String _monthLabel(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

enum _HomeTab {
  overview,
  operations,
  alerts,
  billing,
  account,
}

class _HomeDestination {
  const _HomeDestination({
    required this.tab,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selectedIcon,
  });

  final _HomeTab tab;
  final String label;
  final String subtitle;
  final IconData icon;
  final IconData selectedIcon;
}

class _ScrollablePage extends StatelessWidget {
  const _ScrollablePage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: child,
    );
  }
}

class _WorkspaceHero extends StatelessWidget {
  const _WorkspaceHero({
    required this.title,
    required this.description,
    required this.roleLabel,
    this.companyLabel,
  });

  final String title;
  final String description;
  final String roleLabel;
  final String? companyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: const LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _PillTag(
                label: roleLabel,
                accent: Colors.white,
                textColor: AppColors.secondary,
                fillColor: Colors.white,
              ),
              if (companyLabel != null)
                _PillTag(
                  label: companyLabel!,
                  accent: Colors.white,
                  textColor: Colors.white,
                  fillColor: Colors.white.withValues(alpha: 0.14),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeModule {
  const _HomeModule({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricCardData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 4
            : constraints.maxWidth >= 520
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricCardData metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: metric.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(metric.icon, color: metric.accent),
            ),
            const Spacer(),
            Text(
              metric.value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              metric.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              metric.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.item});

  final _FocusCardData item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: item.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(item.icon, color: item.accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessChip extends StatelessWidget {
  const _AccessChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.title,
    required this.description,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String description;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 24,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.card});

  final _ProgressCardData card;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        card.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _PillTag(
                  label: card.trailingLabel,
                  accent: card.accent,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: card.progress,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(card.accent),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  '${(card.progress * 100).round()}% complete',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  card.tag,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: card.accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({required this.stat});

  final _MiniStatData stat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: stat.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(stat.icon, color: stat.accent, size: 18),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                stat.value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                stat.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.isLast,
  });

  final _TimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Text(
            event.time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Column(
          children: [
            Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(
                color: event.accent,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  event.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final _AlertCardData alert;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        alert.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _PillTag(
                  label: alert.severity,
                  accent: alert.accent,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              alert.timestamp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice});

  final _InvoiceRowData invoice;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: invoice.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          Icons.receipt_long_outlined,
          color: invoice.accent,
        ),
      ),
      title: Text(invoice.code),
      subtitle: Text(invoice.dueLabel),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            invoice.amount,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            invoice.status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: invoice.accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueItem extends StatelessWidget {
  const _KeyValueItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({
    required this.label,
    required this.accent,
    this.textColor,
    this.fillColor,
  });

  final String label;
  final Color accent;
  final Color? textColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fillColor ?? accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.name,
    this.size = 38,
  });

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String description;
  final IconData icon;
  final Color accent;
}

class _FocusCardData {
  const _FocusCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}

class _ProgressCardData {
  const _ProgressCardData({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.trailingLabel,
    required this.tag,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final double progress;
  final String trailingLabel;
  final String tag;
  final Color accent;
}

class _MiniStatData {
  const _MiniStatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.time,
    required this.title,
    required this.description,
    required this.accent,
  });

  final String time;
  final String title;
  final String description;
  final Color accent;
}

class _AlertCardData {
  const _AlertCardData({
    required this.severity,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.accent,
  });

  final String severity;
  final String title;
  final String description;
  final String timestamp;
  final Color accent;
}

class _InvoiceRowData {
  const _InvoiceRowData({
    required this.code,
    required this.amount,
    required this.dueLabel,
    required this.status,
    required this.accent,
  });

  final String code;
  final String amount;
  final String dueLabel;
  final String status;
  final Color accent;
}
