import '../../domain/entities/alert.dart';

class AlertModel {
  const AlertModel({
    required this.id,
    required this.type,
    required this.status,
    this.deliveryOrderId,
    this.createdAt,
    this.updatedAt,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: _stringValue(map['id']),
      deliveryOrderId: _nullableStringValue(map['deliveryOrderId']),
      type: _stringValue(map['alertType']).toUpperCase(),
      status: _stringValue(map['alertStatus']).toUpperCase(),
      createdAt: _dateValue(map['createdAt']),
      updatedAt: _dateValue(map['updatedAt']),
    );
  }

  final String id;
  final String? deliveryOrderId;
  final String type;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Alert toDomain() {
    return Alert(
      id: id,
      type: type,
      status: AlertStatus.fromBackend(status),
      deliveryOrderId: deliveryOrderId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

String _stringValue(Object? value) => '$value'.trim();

String? _nullableStringValue(Object? value) {
  final normalized = '$value'.trim();
  if (normalized.isEmpty || normalized == 'null') {
    return null;
  }

  return normalized;
}

DateTime? _dateValue(Object? value) {
  final raw = _nullableStringValue(value);
  if (raw == null) {
    return null;
  }

  return DateTime.tryParse(raw);
}
