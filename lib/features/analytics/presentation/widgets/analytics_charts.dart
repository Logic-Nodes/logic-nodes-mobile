import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/design_tokens.dart';
import '../../application/controllers/analytics_controller.dart';

class IncidentsAreaChart extends StatelessWidget {
  const IncidentsAreaChart({
    required this.data,
    required this.alertTypeFilter,
    super.key,
  });

  final List<IncidentsChartPoint> data;
  final AnalyticsAlertTypeFilter alertTypeFilter;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: Text(
            'No hay datos para el rango seleccionado.',
            style: TextStyle(color: AppColors.inkMuted),
          ),
        ),
      );
    }

    final maxY = data
        .map(
          (point) => [
            point.temperature,
            point.movement,
            point.total,
          ].reduce((left, right) => left > right ? left : right),
        )
        .fold<double>(0, (left, right) => left > right ? left : right);

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 0 ? 4 : maxY + 1,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      data[index].label,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final label = spot.barIndex == 0 ? 'Temperatura' : 'Movimiento';
                  return LineTooltipItem(
                    '$label: ${spot.y.toInt()}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            if (alertTypeFilter != AnalyticsAlertTypeFilter.movement &&
                data.any((point) => point.temperature > 0))
              LineChartBarData(
                spots: [
                  for (int index = 0; index < data.length; index++)
                    FlSpot(index.toDouble(), data[index].temperature),
                ],
                isCurved: true,
                color: AppColors.primary,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
            if (alertTypeFilter != AnalyticsAlertTypeFilter.temperature &&
                data.any((point) => point.movement > 0))
              LineChartBarData(
                spots: [
                  for (int index = 0; index < data.length; index++)
                    FlSpot(index.toDouble(), data[index].movement),
                ],
                isCurved: true,
                color: AppColors.warning,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.warning.withValues(alpha: 0.12),
                ),
              ),
            if (alertTypeFilter == AnalyticsAlertTypeFilter.all &&
                !data.any((point) => point.temperature > 0 || point.movement > 0))
              LineChartBarData(
                spots: [
                  for (int index = 0; index < data.length; index++)
                    FlSpot(index.toDouble(), data[index].total),
                ],
                isCurved: true,
                color: AppColors.primary,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SensorLineChart extends StatelessWidget {
  const SensorLineChart({
    required this.data,
    required this.color,
    required this.unit,
    required this.emptyMessage,
    super.key,
  });

  final List<SensorChartPoint> data;
  final Color color;
  final String unit;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            emptyMessage,
            style: const TextStyle(color: AppColors.inkMuted),
          ),
        ),
      );
    }

    final maxY = data
        .map((point) => point.value)
        .fold<double>(0, (left, right) => left > right ? left : right);

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 0 ? 10 : maxY * 1.15,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: data.length <= 6 ? 1 : (data.length / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    data[index].time,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              getTooltipItems: (spots) {
                return spots
                    .map(
                      (spot) => LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)} $unit',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                    .toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int index = 0; index < data.length; index++)
                  FlSpot(index.toDouble(), data[index].value),
              ],
              isCurved: true,
              color: color,
              barWidth: 2.5,
              dotData: FlDotData(
                show: data.length <= 12,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
