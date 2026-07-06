class AlertNotification {
  const AlertNotification({
    required this.id,
    required this.alertId,
    required this.channel,
    required this.status,
    this.recipient,
    this.message,
    this.createdAt,
    this.sentAt,
  });

  final String id;
  final String alertId;
  final String channel;
  final String status;
  final String? recipient;
  final String? message;
  final DateTime? createdAt;
  final DateTime? sentAt;
}
