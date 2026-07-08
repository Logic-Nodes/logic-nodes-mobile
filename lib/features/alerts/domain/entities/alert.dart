import '../../../../core/utils/status_labels.dart';

enum AlertStatus {
  open,
  acknowledged,
  closed;

  static AlertStatus fromBackend(String value) {
    switch (value.toUpperCase()) {
      case 'ACKNOWLEDGED':
        return AlertStatus.acknowledged;
      case 'CLOSED':
        return AlertStatus.closed;
      default:
        return AlertStatus.open;
    }
  }

  String get label {
    switch (this) {
      case AlertStatus.open:
        return StatusLabels.alertStatus('OPEN');
      case AlertStatus.acknowledged:
        return StatusLabels.alertStatus('ACKNOWLEDGED');
      case AlertStatus.closed:
        return StatusLabels.alertStatus('CLOSED');
    }
  }

  bool get isResolved => this == AlertStatus.closed;
}

class Alert {
  const Alert({
    required this.id,
    required this.type,
    required this.status,
    this.deliveryOrderId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String type;
  final AlertStatus status;
  final String? deliveryOrderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DateTime? get lastActivityAt => updatedAt ?? createdAt;

  String get typeLabel => StatusLabels.alertType(type);

  Alert copyWith({AlertStatus? status, DateTime? updatedAt}) {
    return Alert(
      id: id,
      type: type,
      status: status ?? this.status,
      deliveryOrderId: deliveryOrderId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
