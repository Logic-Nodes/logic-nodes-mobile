import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/design_tokens.dart';
import '../../../../core/utils/omnitrack_logo.dart';
import '../../../auth/application/controllers/session_controller.dart';
import '../../../auth/domain/entities/auth_user.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.sessionController,
    super.key,
  });

  final SessionController sessionController;

  @override
  Widget build(BuildContext context) {
    final session = sessionController.session;
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

    final modules = _modulesFor(user.role);
    final metrics = _metricsFor(user.role);

    return Scaffold(
      appBar: AppBar(
        title: const OmnitrackLogo(
          foregroundColor: AppColors.ink,
          iconSize: 18,
          textSize: 20,
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await sessionController.signOut();

              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: OmnitrackLogo(
                  foregroundColor: AppColors.ink,
                  iconSize: 18,
                  textSize: 20,
                ),
              ),
              for (final module in modules)
                ListTile(
                  leading: Icon(module.icon),
                  title: Text(module.label),
                  onTap: () => Navigator.of(context).pop(),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await sessionController.signOut();

                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${user.name.split(' ').first}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 28,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      user.role == UserRole.fleetManager
                          ? 'Keep your cold-chain operation visible, compliant and ready to react.'
                          : 'Track active shipments, alert status and subscription activity from one place.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _StatusChip(label: user.role.label),
                        if (user.companyName != null)
                          _StatusChip(label: user.companyName!),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Operational Snapshot',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final metric in metrics) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: metric.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(metric.icon, color: metric.accent),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                metric.label,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                metric.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          metric.value,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Available Modules',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final module in modules) ...[
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    leading: Icon(module.icon, color: AppColors.primary),
                    title: Text(module.label),
                    subtitle: Text(module.description),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_HomeModule> _modulesFor(UserRole role) {
    switch (role) {
      case UserRole.fleetManager:
        return const [
          _HomeModule(
            label: 'Dashboard',
            description: 'Live cold-chain and fleet overview.',
            icon: Icons.dashboard_outlined,
          ),
          _HomeModule(
            label: 'Fleet',
            description: 'Vehicles, devices and assignment status.',
            icon: Icons.local_shipping_outlined,
          ),
          _HomeModule(
            label: 'Trips',
            description: 'Upcoming, in-progress and completed trips.',
            icon: Icons.alt_route_rounded,
          ),
          _HomeModule(
            label: 'Alerts',
            description: 'Incidents by severity and response state.',
            icon: Icons.notifications_active_outlined,
          ),
          _HomeModule(
            label: 'Monitoring',
            description: 'Telemetry sessions and route visibility.',
            icon: Icons.radar_outlined,
          ),
          _HomeModule(
            label: 'Settings',
            description: 'Preferences, users and operational rules.',
            icon: Icons.tune_rounded,
          ),
          _HomeModule(
            label: 'Billing',
            description: 'Subscription management and payment history.',
            icon: Icons.receipt_long_outlined,
          ),
        ];
      case UserRole.customer:
        return const [
          _HomeModule(
            label: 'Trips',
            description: 'Track active shipments and route progress.',
            icon: Icons.alt_route_rounded,
          ),
          _HomeModule(
            label: 'Alerts',
            description: 'Monitor temperature and delivery incidents.',
            icon: Icons.notifications_active_outlined,
          ),
          _HomeModule(
            label: 'Billing',
            description: 'Review plans, invoices and renewals.',
            icon: Icons.receipt_long_outlined,
          ),
          _HomeModule(
            label: 'Profile',
            description: 'Contact information and preferences.',
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
            description: 'Operational units connected to telemetry.',
            icon: Icons.local_shipping_outlined,
            accent: AppColors.primary,
          ),
          _MetricCardData(
            label: 'Open Alerts',
            value: '3',
            description: 'Critical or major incidents requiring action.',
            icon: Icons.warning_amber_rounded,
            accent: AppColors.warning,
          ),
          _MetricCardData(
            label: 'Cold Chain Compliance',
            value: '97%',
            description: 'Trips that stayed within target conditions today.',
            icon: Icons.verified_outlined,
            accent: AppColors.success,
          ),
        ];
      case UserRole.customer:
        return const [
          _MetricCardData(
            label: 'Tracked Trips',
            value: '2',
            description: 'Shipments currently visible in your account.',
            icon: Icons.route_outlined,
            accent: AppColors.primary,
          ),
          _MetricCardData(
            label: 'Resolved Alerts',
            value: '5',
            description: 'Issues handled before delivery completion.',
            icon: Icons.check_circle_outline_rounded,
            accent: AppColors.success,
          ),
          _MetricCardData(
            label: 'Plan Status',
            value: 'Active',
            description: 'Your subscription is ready for the next cycle.',
            icon: Icons.workspace_premium_outlined,
            accent: AppColors.secondary,
          ),
        ];
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
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
