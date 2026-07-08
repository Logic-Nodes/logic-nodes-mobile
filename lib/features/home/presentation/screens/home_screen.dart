import 'package:flutter/material.dart';

import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/network/api_environment.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/omnitrack_logo.dart';
import '../../../../core/utils/status_labels.dart';
import '../../../auth/application/controllers/session_controller.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../billing/application/controllers/billing_controller.dart';
import '../../application/controllers/home_controller.dart';
import '../../domain/entities/home_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.controller,
    required this.sessionController,
    required this.billingController,
    super.key,
  });

  final HomeController controller;
  final SessionController sessionController;
  final BillingController billingController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.load();
    widget.billingController.load();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

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

  String? _moduleRoute(String label) {
    return switch (label) {
      'Panel' => AppRoutes.analytics,
      'Flota' => AppRoutes.fleetVehicles,
      'Viajes' => AppRoutes.trips,
      'Alertas' => AppRoutes.alerts,
      'Monitoreo' => AppRoutes.analytics,
      'Facturación' => AppRoutes.subscription,
      _ => null,
    };
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
            tooltip: 'Actualizar',
            onPressed: widget.controller.isLoading ? null : widget.controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
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
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final dashboard = widget.controller.dashboard;

              if (dashboard == null) {
                if (widget.controller.isLoading) {
                  return const _LoadingState();
                }

                return _ErrorState(
                  message: widget.controller.errorMessage ??
                      'No hay datos del workspace disponibles para esta cuenta.',
                  onRetry: widget.controller.load,
                );
              }

              return Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey<String>(
                        '${activeDestination.tab.name}-${dashboard.loadedAt.toIso8601String()}',
                      ),
                      child: _buildTabContent(
                        context,
                        session: session!,
                        user: user,
                        dashboard: dashboard,
                        tab: activeDestination.tab,
                      ),
                    ),
                  ),
                  if (dashboard.isFromCache)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: OfflineBanner(
                        message:
                            'Modo offline: datos desde SQLite. Se actualizaran al reconectar.',
                      ),
                    ),
                  if (widget.controller.isLoading)
                    const Align(
                      alignment: Alignment.topCenter,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                ],
              );
            },
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
    required HomeDashboard dashboard,
    required _HomeTab tab,
  }) {
    return switch (tab) {
      _HomeTab.overview => _buildOverviewTab(context, user, dashboard),
      _HomeTab.operations => _buildOperationsTab(context, user, dashboard),
      _HomeTab.alerts => _buildAlertsTab(context, dashboard),
      _HomeTab.billing => _buildBillingTab(context, user, dashboard),
      _HomeTab.account => _buildAccountTab(
          context,
          session: session,
          user: user,
          dashboard: dashboard,
        ),
    };
  }

  Widget _buildOverviewTab(
    BuildContext context,
    AuthUser user,
    HomeDashboard dashboard,
  ) {
    final focusItems = _focusItemsFor(user.role, dashboard);
    final modules = _modulesFor(user.role);

    return _ScrollablePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dashboard.scopeNotice != null) ...[
            _ScopeNoticeCard(message: dashboard.scopeNotice!),
            const SizedBox(height: AppSpacing.md),
          ],
          _WorkspaceHero(
            title: 'Hola, ${user.name.split(' ').first}',
            description: user.role == UserRole.fleetManager
                ? 'Controla flota, viajes, alertas y monitoreo desde una sola vista conectada al backend real.'
                : 'Sigue tus envios, alertas y estado del workspace desde datos reales del backend.',
            roleLabel: user.role.label,
            companyLabel: user.companyName,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeading(
            title: 'Resumen operativo',
            description: user.role == UserRole.fleetManager
                ? 'Indicadores construidos con viajes, dispositivos y alertas visibles.'
                : 'Resumen construido con viajes, ordenes y alertas asociadas a tu cuenta.',
          ),
          const SizedBox(height: AppSpacing.md),
          _MetricGrid(metrics: _metricsFor(user.role, dashboard)),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.analytics),
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Abrir panel de analíticas'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Foco de hoy',
            description: 'Puntos de atencion calculados desde el estado actual del backend.',
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in focusItems) ...[
            _FocusCard(item: item),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Acceso al workspace',
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
                  onTap: () {
                    final route = _moduleRoute(module.label);
                    if (route != null) {
                      Navigator.of(context).pushNamed(route);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsTab(
    BuildContext context,
    AuthUser user,
    HomeDashboard dashboard,
  ) {
    final cards = _routeCardsFor(user.role, dashboard);
    final events = _timelineFor(user.role, dashboard);
    final stats = _operationsStatsFor(user.role, dashboard);

    return _ScrollablePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBanner(
            title: user.role == UserRole.fleetManager
                ? 'Operaciones en vivo'
                : 'Progreso del envío',
            description: user.role == UserRole.fleetManager
                ? 'Seguimiento real de rutas, dispositivos y sesiones activas.'
                : 'Seguimiento real de los viajes y ordenes vinculadas a tu cuenta.',
            accent: user.role == UserRole.fleetManager
                ? AppColors.primary
                : AppColors.secondary,
            icon: user.role == UserRole.fleetManager
                ? Icons.local_shipping_rounded
                : Icons.route_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (user.role == UserRole.fleetManager) ...[
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.fleetVehicles),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Gestionar vehiculos'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.fleetDevices),
                  icon: const Icon(Icons.sensors_outlined),
                  label: const Text('Dispositivos IoT'),
                ),
              ],
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.trips),
                icon: const Icon(Icons.route_outlined),
                label: const Text('Gestionar viajes'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeading(
            title: user.role == UserRole.fleetManager
                ? 'Rutas en movimiento'
                : 'Envíos visibles',
            description: 'Tarjetas alimentadas con los viajes retornados por la API.',
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.analytics),
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Abrir panel de analíticas'),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final card in cards) ...[
            _ProgressCard(
              card: card,
              onTap: card.tripId == null
                  ? null
                  : () => Navigator.of(context).pushNamed(
                        AppRoutes.analyticsTripDetail,
                        arguments: card.tripId,
                      ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Panel de preparación',
            description: 'Estadisticas operativas derivadas del backend visible.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final stat in stats) _MiniStatCard(stat: stat),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Actividad reciente',
            description: 'Eventos recientes deducidos de viajes y alertas.',
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

  Widget _buildAlertsTab(BuildContext context, HomeDashboard dashboard) {
    final alerts = _alertsFor(dashboard);
    final summary = _alertSummaryFor(dashboard);

    return _ScrollablePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBanner(
            title: 'Centro de respuesta',
            description: 'Alertas agrupadas con base en la respuesta real del backend.',
            accent: AppColors.warning,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.alerts),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Abrir centro de alertas'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Canal de alertas',
            description: 'Lectura operativa de criticidad, seguimiento y cierre.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final stat in summary) _MiniStatCard(stat: stat),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final alert in alerts) ...[
            _AlertCard(alert: alert),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Acciones inmediatas',
            description: 'Acciones sugeridas segun las entidades que hoy devuelve el backend.',
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _ChecklistTile(
                    icon: Icons.thermostat_rounded,
                    title:
                        'Validar las alertas abiertas y su orden de entrega asociada antes del siguiente movimiento.',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _ChecklistTile(
                    icon: Icons.support_agent_rounded,
                    title:
                        'Confirmar si las alertas reconocidas fueron efectivamente atendidas en operacion.',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _ChecklistTile(
                    icon: Icons.fact_check_outlined,
                    title:
                        'Cerrar solo las alertas con evidencia trazable para mantener el flujo consistente.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingTab(
    BuildContext context,
    AuthUser user,
    HomeDashboard dashboard,
  ) {
    final usageStats = _billingUsageStats(dashboard);

    return AnimatedBuilder(
      animation: widget.billingController,
      builder: (context, _) {
        final billing = widget.billingController;
        final subscription = billing.subscription;

        return _ScrollablePage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WorkspaceHero(
                title: 'Facturación y plan',
                description:
                    'Suscripcion y pagos cargados desde /api/v1/subscription y /api/v1/payments.',
                roleLabel: user.role.label,
                companyLabel: user.companyName ?? 'Workspace personal',
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.subscription),
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('Gestionar suscripción y pagos'),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (billing.isLoading && subscription == null)
                const Center(child: CircularProgressIndicator())
              else if (subscription != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.plan.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subscription.plan.priceLabel,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _KeyValueItem(
                                label: 'Estado',
                                value: subscription.status,
                              ),
                            ),
                            Expanded(
                              child: _KeyValueItem(
                                label: 'Renovación',
                                value: subscription.renewal,
                              ),
                            ),
                            Expanded(
                              child: _KeyValueItem(
                                label: 'Pagos',
                                value: '${billing.payments.length}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      billing.errorMessage ??
                          'El backend aún no devolvió datos de suscripción.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionHeading(
                title: 'Resumen de uso',
                description: 'Consumo operativo visible desde trips, devices y alertas.',
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final stat in usageStats) _MiniStatCard(stat: stat),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountTab(
    BuildContext context, {
    required AuthSession session,
    required AuthUser user,
    required HomeDashboard dashboard,
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
            title: 'Detalles de sesión',
            description: 'Datos visibles de la conexion actual y del ultimo sync.',
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
                    label: 'Documentación',
                    value: ApiEnvironment.docsUrl,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _DetailRow(
                    label: 'Token expira',
                    value: _formatDateTime(session.expiresAt),
                  ),
                  const Divider(height: AppSpacing.lg),
                  _DetailRow(
                    label: 'Workspace',
                    value: user.companyName ?? 'Cuenta personal',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _DetailRow(
                    label: 'Última sincronización',
                    value: _formatDateTime(dashboard.loadedAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Módulos habilitados',
            description: 'Secciones disponibles actualmente para este perfil.',
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
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  final route = _moduleRoute(module.label);
                  if (route != null) {
                    Navigator.of(context).pushNamed(route);
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeading(
            title: 'Acceso rápido',
            description: 'Pantallas del flujo mobile alineadas al reporte.',
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.profile),
            icon: const Icon(Icons.person_outline_rounded),
            label: const Text('Editar perfil'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.analytics),
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Abrir panel de analíticas'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.trips),
            icon: const Icon(Icons.route_outlined),
            label: const Text('Gestionar viajes'),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (user.role == UserRole.fleetManager) ...[
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.fleetVehicles),
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Gestionar flota'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.alerts),
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Abrir centro de alertas'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.subscription),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Gestionar suscripción y pagos'),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
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
            label: 'Resumen',
            subtitle: 'Centro de operaciones',
            icon: Icons.space_dashboard_outlined,
            selectedIcon: Icons.space_dashboard_rounded,
          ),
          _HomeDestination(
            tab: _HomeTab.operations,
            label: 'Flota',
            subtitle: 'Flota y seguimiento de viajes',
            icon: Icons.local_shipping_outlined,
            selectedIcon: Icons.local_shipping_rounded,
          ),
          _HomeDestination(
            tab: _HomeTab.alerts,
            label: 'Alertas',
            subtitle: 'Incidentes y respuesta',
            icon: Icons.notifications_active_outlined,
            selectedIcon: Icons.notifications_active_rounded,
          ),
          _HomeDestination(
            tab: _HomeTab.account,
            label: 'Cuenta',
            subtitle: 'Perfil y accesos',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ];
      case UserRole.customer:
        return const [
          _HomeDestination(
            tab: _HomeTab.overview,
            label: 'Resumen',
            subtitle: 'Visibilidad de envíos',
            icon: Icons.space_dashboard_outlined,
            selectedIcon: Icons.space_dashboard_rounded,
          ),
          _HomeDestination(
            tab: _HomeTab.operations,
            label: 'Viajes',
            subtitle: 'Rutas e hitos',
            icon: Icons.route_outlined,
            selectedIcon: Icons.route_rounded,
          ),
          _HomeDestination(
            tab: _HomeTab.billing,
            label: 'Facturación',
            subtitle: 'Estado del módulo',
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
          ),
          _HomeDestination(
            tab: _HomeTab.account,
            label: 'Cuenta',
            subtitle: 'Perfil y soporte',
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
            label: 'Panel',
            description: 'Vista ejecutiva con metricas en tiempo real.',
            icon: Icons.dashboard_outlined,
          ),
          _HomeModule(
            label: 'Flota',
            description: 'Vehiculos, dispositivos y disponibilidad.',
            icon: Icons.local_shipping_outlined,
          ),
          _HomeModule(
            label: 'Viajes',
            description: 'Rutas planificadas, activas y completadas.',
            icon: Icons.alt_route_rounded,
          ),
          _HomeModule(
            label: 'Alertas',
            description: 'Incidentes, severidad y tiempo de respuesta.',
            icon: Icons.warning_amber_rounded,
          ),
          _HomeModule(
            label: 'Monitoreo',
            description: 'Sesiones de telemetria y trazabilidad.',
            icon: Icons.radar_outlined,
          ),
          _HomeModule(
            label: 'Facturación',
            description: 'Estado del modulo de billing.',
            icon: Icons.receipt_long_outlined,
          ),
        ];
      case UserRole.customer:
        return const [
          _HomeModule(
            label: 'Viajes',
            description: 'Seguimiento de pedidos y entregas activas.',
            icon: Icons.route_rounded,
          ),
          _HomeModule(
            label: 'Alertas',
            description: 'Alertas asociadas al envio monitoreado.',
            icon: Icons.notifications_active_outlined,
          ),
          _HomeModule(
            label: 'Facturación',
            description: 'Estado del modulo de facturacion.',
            icon: Icons.receipt_long_outlined,
          ),
          _HomeModule(
            label: 'Perfil',
            description: 'Datos de contacto y preferencias.',
            icon: Icons.person_outline_rounded,
          ),
        ];
    }
  }

  List<_MetricCardData> _metricsFor(UserRole role, HomeDashboard dashboard) {
    switch (role) {
      case UserRole.fleetManager:
        return [
          _MetricCardData(
            label: 'Vehículos visibles',
            value: '${dashboard.totalVehicles}',
            description: 'Vehiculos obtenidos desde el backend actual.',
            icon: Icons.local_shipping_outlined,
            accent: AppColors.primary,
          ),
          _MetricCardData(
            label: 'Viajes activos',
            value: '${dashboard.activeTrips}',
            description: 'Rutas en progreso dentro del alcance visible.',
            icon: Icons.route_outlined,
            accent: AppColors.secondary,
          ),
          _MetricCardData(
            label: 'Alertas abiertas',
            value: '${dashboard.openAlerts + dashboard.acknowledgedAlerts}',
            description: 'Alertas abiertas o reconocidas pendientes.',
            icon: Icons.warning_amber_rounded,
            accent: AppColors.warning,
          ),
          _MetricCardData(
            label: 'Sesiones en vivo',
            value: '${dashboard.activeSessions.length}',
            description: 'Sesiones activas de monitoreo detectadas.',
            icon: Icons.radar_outlined,
            accent: AppColors.success,
          ),
        ];
      case UserRole.customer:
        return [
          _MetricCardData(
            label: 'Viajes rastreados',
            value: '${dashboard.totalTrips}',
            description: 'Envios vinculados a tu correo.',
            icon: Icons.route_outlined,
            accent: AppColors.primary,
          ),
          _MetricCardData(
            label: 'Órdenes de entrega',
            value: '${dashboard.totalDeliveryOrders}',
            description: 'Ordenes visibles para tu cuenta.',
            icon: Icons.inventory_2_outlined,
            accent: AppColors.secondary,
          ),
          _MetricCardData(
            label: 'Alertas abiertas',
            value: '${dashboard.openAlerts + dashboard.acknowledgedAlerts}',
            description: 'Alertas activas en tus envios.',
            icon: Icons.notification_important_outlined,
            accent: AppColors.warning,
          ),
          _MetricCardData(
            label: 'Sesiones en vivo',
            value: '${dashboard.activeSessions.length}',
            description: 'Sesiones activas asociadas a tus viajes.',
            icon: Icons.sensors_outlined,
            accent: AppColors.success,
          ),
        ];
    }
  }

  List<_FocusCardData> _focusItemsFor(
    UserRole role,
    HomeDashboard dashboard,
  ) {
    switch (role) {
      case UserRole.fleetManager:
        return [
          _FocusCardData(
            title: '${dashboard.activeTrips} viajes activos requieren revisión',
            description:
                'El backend reporta ${dashboard.activeSessions.length} sesiones activas y ${dashboard.plannedTrips} rutas aun planificadas.',
            icon: Icons.schedule_rounded,
            accent: AppColors.primary,
          ),
          _FocusCardData(
            title:
                '${dashboard.openAlerts + dashboard.acknowledgedAlerts} alertas pendientes en cola',
            description:
                'Las alertas visibles incluyen ${dashboard.openAlerts} abiertas y ${dashboard.acknowledgedAlerts} reconocidas.',
            icon: Icons.warning_amber_rounded,
            accent: AppColors.warning,
          ),
          _FocusCardData(
            title: '${dashboard.onlineDevices} dispositivos en línea ahora',
            description:
                'El inventario visible tiene ${dashboard.totalVehicles} vehiculos y ${dashboard.offlineDevices} dispositivos sin conexion.',
            icon: Icons.sensors_outlined,
            accent: AppColors.secondary,
          ),
        ];
      case UserRole.customer:
        return [
          _FocusCardData(
            title: '${dashboard.totalTrips} viajes rastreados coinciden con tu correo',
            description:
                'La app encontro ${dashboard.totalDeliveryOrders} ordenes de entrega relacionadas con tu cuenta.',
            icon: Icons.location_searching_rounded,
            accent: AppColors.primary,
          ),
          _FocusCardData(
            title:
                '${dashboard.deliveredOrders}/${dashboard.totalDeliveryOrders} hitos completados',
            description:
                'Puedes ver ${dashboard.pendingOrders} pedidos pendientes y ${dashboard.failedOrders} fallidos.',
            icon: Icons.check_circle_outline_rounded,
            accent: AppColors.success,
          ),
          _FocusCardData(
            title:
                '${dashboard.openAlerts + dashboard.acknowledgedAlerts} alertas requieren seguimiento',
            description:
                'Las alertas se muestran filtradas segun las ordenes de entrega vinculadas a tu cuenta.',
            icon: Icons.notifications_active_outlined,
            accent: AppColors.secondary,
          ),
        ];
    }
  }

  List<_ProgressCardData> _routeCardsFor(
    UserRole role,
    HomeDashboard dashboard,
  ) {
    final trips = [...dashboard.trips]
      ..sort(
        (left, right) => (right.lastActivityAt ?? dashboard.loadedAt)
            .compareTo(left.lastActivityAt ?? dashboard.loadedAt),
      );

    if (trips.isEmpty) {
      return [
        _ProgressCardData(
          title: role == UserRole.fleetManager
              ? 'Aún no hay viajes disponibles'
              : 'Aún no hay envíos rastreados',
          subtitle:
              'Cuando el backend tenga viajes para este workspace aparecerán aquí automáticamente.',
          progress: 0,
          trailingLabel: 'En espera',
          tag: 'Backend listo',
          accent: AppColors.secondary,
        ),
      ];
    }

    return trips.take(3).map((trip) {
      final vehicleLabel = _vehicleLabel(dashboard, trip.vehicleId);
      final order = role == UserRole.customer && trip.deliveryOrders.isNotEmpty
          ? trip.deliveryOrders.first
          : null;

      return _ProgressCardData(
        title: role == UserRole.fleetManager
            ? 'Viaje #${trip.id}${trip.originPointName != null ? ' / ${trip.originPointName}' : ''}'
            : 'Pedido #${order?.id ?? trip.id}',
        subtitle: role == UserRole.fleetManager
            ? '$vehicleLabel | ${StatusLabels.tripStatus(trip.status)}'
            : '${trip.deliveryOrders.length} ordenes | $vehicleLabel',
        progress: trip.completionProgress,
        trailingLabel: StatusLabels.tripStatus(trip.status),
        tag: trip.deliveryOrders.isEmpty
            ? 'Sin órdenes de entrega'
            : '${trip.deliveredOrders}/${trip.deliveryOrders.length} entregadas',
        accent: _statusAccent(trip.status),
        tripId: trip.id,
      );
    }).toList(growable: false);
  }

  List<_MiniStatData> _operationsStatsFor(
    UserRole role,
    HomeDashboard dashboard,
  ) {
    switch (role) {
      case UserRole.fleetManager:
        return [
          _MiniStatData(
            label: 'Vehículos',
            value: '${dashboard.totalVehicles}',
            icon: Icons.inventory_2_outlined,
            accent: AppColors.primary,
          ),
          _MiniStatData(
            label: 'Dispositivos en línea',
            value: '${dashboard.onlineDevices}',
            icon: Icons.sensors_outlined,
            accent: AppColors.secondary,
          ),
          _MiniStatData(
            label: 'Sesiones activas',
            value: '${dashboard.activeSessions.length}',
            icon: Icons.radar_outlined,
            accent: AppColors.success,
          ),
        ];
      case UserRole.customer:
        return [
          _MiniStatData(
            label: 'Pedidos',
            value: '${dashboard.totalDeliveryOrders}',
            icon: Icons.flag_outlined,
            accent: AppColors.primary,
          ),
          _MiniStatData(
            label: 'Entregados',
            value: '${dashboard.deliveredOrders}',
            icon: Icons.task_alt_rounded,
            accent: AppColors.secondary,
          ),
          _MiniStatData(
            label: 'Sesiones en vivo',
            value: '${dashboard.activeSessions.length}',
            icon: Icons.timer_outlined,
            accent: AppColors.success,
          ),
        ];
    }
  }

  List<_TimelineEvent> _timelineFor(UserRole role, HomeDashboard dashboard) {
    final events = <_TimelineEvent>[];

    final trips = [...dashboard.trips]
      ..sort(
        (left, right) => (right.lastActivityAt ?? dashboard.loadedAt)
            .compareTo(left.lastActivityAt ?? dashboard.loadedAt),
      );
    final alerts = [...dashboard.alerts]
      ..sort(
        (left, right) => (right.lastActivityAt ?? dashboard.loadedAt)
            .compareTo(left.lastActivityAt ?? dashboard.loadedAt),
      );

    for (final trip in trips.take(2)) {
      final time = trip.lastActivityAt ?? dashboard.loadedAt;
      events.add(
        _TimelineEvent(
          time: _formatHourMinute(time),
          title: role == UserRole.fleetManager
              ? 'Viaje #${trip.id} está ${StatusLabels.tripStatus(trip.status).toLowerCase()}'
              : 'Viaje rastreado #${trip.id} cambió a ${StatusLabels.tripStatus(trip.status).toLowerCase()}',
          description: trip.deliveryOrders.isEmpty
              ? 'No se devolvieron órdenes de entrega para este viaje.'
              : '${trip.deliveredOrders}/${trip.deliveryOrders.length} órdenes de entrega están marcadas como entregadas.',
          accent: _statusAccent(trip.status),
        ),
      );
    }

    for (final alert in alerts.take(2)) {
      final time = alert.lastActivityAt ?? dashboard.loadedAt;
      events.add(
        _TimelineEvent(
          time: _formatHourMinute(time),
          title:
              'Alerta de ${StatusLabels.alertType(alert.type)} está ${StatusLabels.alertStatus(alert.status).toLowerCase()}',
          description: alert.deliveryOrderId == null
              ? 'La alerta es visible sin una orden de entrega vinculada.'
              : 'Orden de entrega vinculada: #${alert.deliveryOrderId}.',
          accent: _statusAccent(alert.status),
        ),
      );
    }

    if (events.isEmpty) {
      return const [
        _TimelineEvent(
          time: '--:--',
          title: 'Sin actividad reciente',
          description:
              'Los viajes y alertas del backend aparecerán aquí cuando existan datos.',
          accent: AppColors.secondary,
        ),
      ];
    }

    return events.take(4).toList(growable: false);
  }

  List<_MiniStatData> _alertSummaryFor(HomeDashboard dashboard) {
    return [
      _MiniStatData(
        label: 'Abiertas',
        value: '${dashboard.openAlerts}',
        icon: Icons.priority_high_rounded,
        accent: AppColors.danger,
      ),
      _MiniStatData(
        label: 'Reconocidas',
        value: '${dashboard.acknowledgedAlerts}',
        icon: Icons.rule_folder_outlined,
        accent: AppColors.warning,
      ),
      _MiniStatData(
        label: 'Cerradas',
        value: '${dashboard.closedAlerts}',
        icon: Icons.task_alt_rounded,
        accent: AppColors.success,
      ),
    ];
  }

  List<_AlertCardData> _alertsFor(HomeDashboard dashboard) {
    final alerts = [...dashboard.alerts]
      ..sort(
        (left, right) => (right.lastActivityAt ?? dashboard.loadedAt)
            .compareTo(left.lastActivityAt ?? dashboard.loadedAt),
      );

    if (alerts.isEmpty) {
      return const [
        _AlertCardData(
          severity: 'Sin alertas',
          title: 'No hay alertas disponibles',
          description:
              'El backend actual no devolvió alertas para el workspace visible.',
          timestamp: 'Backend sincronizado',
          accent: AppColors.success,
        ),
      ];
    }

    return alerts.take(4).map((alert) {
      return _AlertCardData(
        severity: StatusLabels.alertStatus(alert.status),
        title: 'Alerta de ${StatusLabels.alertType(alert.type)}'
            '${alert.deliveryOrderId != null ? ' en pedido #${alert.deliveryOrderId}' : ''}',
        description:
            'Estado actual del backend: ${StatusLabels.alertStatus(alert.status).toLowerCase()}.',
        timestamp: _relativeTimestamp(
          alert.lastActivityAt,
          fallback: dashboard.loadedAt,
        ),
        accent: _statusAccent(alert.status),
      );
    }).toList(growable: false);
  }

  List<_MiniStatData> _billingUsageStats(HomeDashboard dashboard) {
    return [
      _MiniStatData(
        label: 'Viajes activos',
        value: '${dashboard.activeTrips}',
        icon: Icons.route_outlined,
        accent: AppColors.primary,
      ),
      _MiniStatData(
        label: 'Alertas visibles',
        value: '${dashboard.totalAlerts}',
        icon: Icons.notifications_outlined,
        accent: AppColors.secondary,
      ),
      _MiniStatData(
        label: 'Sesiones en vivo',
        value: '${dashboard.activeSessions.length}',
        icon: Icons.health_and_safety_outlined,
        accent: AppColors.success,
      ),
    ];
  }

  String _vehicleLabel(HomeDashboard dashboard, String? vehicleId) {
    if (vehicleId == null) {
      return 'Sin vehículo asignado';
    }

    for (final vehicle in dashboard.vehicles) {
      if (vehicle.id == vehicleId) {
        return 'Vehículo ${vehicle.plate}';
      }
    }

    return 'Vehículo #$vehicleId';
  }

  Color _statusAccent(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'CLOSED':
      case 'DELIVERED':
        return AppColors.success;
      case 'OPEN':
      case 'FAILED':
      case 'CANCELLED':
        return AppColors.danger;
      case 'ACKNOWLEDGED':
        return AppColors.warning;
      case 'IN_PROGRESS':
      case 'ACTIVE':
        return AppColors.primary;
      default:
        return AppColors.secondary;
    }
  }

  String _formatHourMinute(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _relativeTimestamp(DateTime? value, {required DateTime fallback}) {
    final timestamp = (value ?? fallback).toLocal();
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Actualizado hace un momento';
    }
    if (difference.inMinutes < 60) {
      return 'Actualizado hace ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'Actualizado hace ${difference.inHours} h';
    }
    return 'Actualizado hace ${difference.inDays} d';
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '${_monthLabel(local.month)} ${local.day}, $hours:$minutes';
  }

  String _monthLabel(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Cargando datos del espacio de trabajo...'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 42,
                  color: AppColors.warning,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScopeNoticeCard extends StatelessWidget {
  const _ScopeNoticeCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7E8),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                    ),
              ),
            ),
          ],
        ),
      ),
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
            childAspectRatio: 0.9,
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
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
  const _ProgressCard({
    required this.card,
    this.onTap,
  });

  final _ProgressCardData card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
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
                value: card.progress.clamp(0, 1),
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
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    final initials = parts.isEmpty
        ? 'U'
        : parts.map((part) => part.substring(0, 1).toUpperCase()).join();

    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
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
    this.tripId,
  });

  final String title;
  final String subtitle;
  final double progress;
  final String trailingLabel;
  final String tag;
  final Color accent;
  final String? tripId;
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
