import 'dart:convert';

import 'alert_model.dart';
import '../../domain/entities/alert.dart';

class AlertListCodec {
  static String encode(List<Alert> alerts) {
    return jsonEncode(
      alerts
          .map(
            (alert) => {
              'id': alert.id,
              'deliveryOrderId': alert.deliveryOrderId,
              'type': alert.type,
              'status': switch (alert.status) {
                AlertStatus.open => 'OPEN',
                AlertStatus.acknowledged => 'ACKNOWLEDGED',
                AlertStatus.closed => 'CLOSED',
              },
              'createdAt': alert.createdAt?.toUtc().toIso8601String(),
              'updatedAt': alert.updatedAt?.toUtc().toIso8601String(),
            },
          )
          .toList(growable: false),
    );
  }

  static List<Alert> decode(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AlertModel.fromMap)
        .map((model) => model.toDomain())
        .toList(growable: false);
  }
}
