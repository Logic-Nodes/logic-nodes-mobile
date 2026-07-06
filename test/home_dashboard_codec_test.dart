import 'package:flutter_test/flutter_test.dart';
import 'package:logic_nodes_mobile/features/home/data/models/home_dashboard_codec.dart';
import 'package:logic_nodes_mobile/features/home/domain/entities/home_dashboard.dart';

void main() {
  test('HomeDashboardCodec roundtrip preserves dashboard data', () {
    final dashboard = HomeDashboard(
      trips: [
        HomeTrip(
          id: '1',
          status: 'PLANNED',
          deliveryOrders: const [
            HomeDeliveryOrder(
              id: '10',
              clientEmail: 'client@example.com',
              sequenceOrder: 1,
              status: 'PENDING',
            ),
          ],
          createdAt: DateTime(2026, 7, 1, 12),
        ),
      ],
      alerts: const [
        HomeAlert(
          id: '2',
          type: 'TEMPERATURE',
          status: 'OPEN',
        ),
      ],
      vehicles: const [
        HomeVehicle(
          id: '3',
          plate: 'ABC-123',
          type: 'TRUCK',
          status: 'IN_SERVICE',
          deviceImeis: ['imei-1'],
        ),
      ],
      devices: const [
        HomeDevice(
          id: '4',
          imei: 'imei-1',
          online: true,
        ),
      ],
      activeSessions: const [
        HomeMonitoringSession(
          id: '5',
          tripId: '1',
          deviceId: '4',
          status: 'ACTIVE',
        ),
      ],
      loadedAt: DateTime(2026, 7, 6, 10),
      scopeApplied: true,
    );

    final encoded = HomeDashboardCodec.encode(dashboard);
    final decoded = HomeDashboardCodec.decode(encoded);

    expect(decoded.trips.length, 1);
    expect(decoded.trips.first.id, '1');
    expect(decoded.alerts.first.type, 'TEMPERATURE');
    expect(decoded.vehicles.first.plate, 'ABC-123');
    expect(decoded.devices.first.online, isTrue);
    expect(decoded.activeSessions.first.tripId, '1');
  });
}
