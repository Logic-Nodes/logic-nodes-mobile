import 'dart:async';

import 'package:flutter/material.dart';

import '../routing/app_routes.dart';
import '../utils/design_tokens.dart';

const kDemoAutoLogin = bool.fromEnvironment('DEMO_AUTO_LOGIN');
const kDemoTour = bool.fromEnvironment('DEMO_TOUR');

const _demoEmail = 'demo.mobile.2026@omnitrack.io';
const _demoPassword = 'DemoMobile123!';

String get demoEmail => _demoEmail;
String get demoPassword => _demoPassword;

class DemoTourOverlay extends StatefulWidget {
  const DemoTourOverlay({
    required this.navigatorKey,
    required this.enabled,
    required this.child,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final bool enabled;
  final Widget child;

  @override
  State<DemoTourOverlay> createState() => _DemoTourOverlayState();
}

class _DemoTourOverlayState extends State<DemoTourOverlay> {
  String? _banner;
  int _step = 0;
  int _totalSteps = 0;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runTour());
    }
  }

  Future<void> _runTour() async {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    final stops = <_TourStop>[
      const _TourStop(
        title: 'Home · Resumen operativo',
        route: AppRoutes.home,
      ),
      const _TourStop(
        title: 'Nuevo · Flota (vehículos)',
        route: AppRoutes.fleetVehicles,
      ),
      const _TourStop(
        title: 'Nuevo · Dispositivos IoT',
        route: AppRoutes.fleetDevices,
      ),
      const _TourStop(
        title: 'Nuevo · Viajes',
        route: AppRoutes.trips,
      ),
      const _TourStop(
        title: 'Nuevo · Crear viaje',
        route: AppRoutes.tripForm,
      ),
      const _TourStop(
        title: 'Nuevo · Perfil',
        route: AppRoutes.profile,
      ),
      const _TourStop(
        title: 'Analíticas',
        route: AppRoutes.analytics,
      ),
      const _TourStop(
        title: 'Alertas ampliadas',
        route: AppRoutes.alerts,
      ),
    ];

    _totalSteps = stops.length;
    await Future<void>.delayed(const Duration(seconds: 3));

    for (var i = 0; i < stops.length; i++) {
      if (!mounted) {
        return;
      }

      final stop = stops[i];
      setState(() {
        _step = i + 1;
        _banner = stop.title;
      });

      if (stop.route != AppRoutes.home) {
        unawaited(navigator.pushNamed(stop.route));
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }

      await Future<void>.delayed(const Duration(seconds: 5));

      if (!mounted) {
        return;
      }

      if (stop.route != AppRoutes.home && navigator.canPop()) {
        navigator.pop();
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }

    if (mounted) {
      setState(() => _banner = 'Tour finalizado — explora libremente');
      await Future<void>.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _banner = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (_banner != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: AppColors.ink,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _banner!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (_totalSteps > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Paso $_step de $_totalSteps · Demo automática',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TourStop {
  const _TourStop({
    required this.title,
    required this.route,
  });

  final String title;
  final String route;
}
