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
        return 'Open';
      case AlertStatus.acknowledged:
        return 'Acknowledged';
      case AlertStatus.closed:
        return 'Resolved';
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

  String get typeLabel => type
      .toLowerCase()
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

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
