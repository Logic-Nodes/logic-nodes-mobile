import '../../../../core/network/api_helpers.dart';
import '../../domain/entities/notification.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.alertId,
    required this.channel,
    required this.status,
    this.recipient,
    this.message,
    this.createdAt,
    this.sentAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: stringValue(map['id']),
      alertId: stringValue(map['alertId']),
      channel: stringValue(map['channel'] ?? map['type']).toUpperCase(),
      status: stringValue(map['notificationStatus'] ?? map['status']).toUpperCase(),
      recipient: nullableStringValue(map['recipient'] ?? map['recipientEmail']),
      message: nullableStringValue(map['message'] ?? map['body']),
      createdAt: dateValue(map['createdAt']),
      sentAt: dateValue(map['sentAt']),
    );
  }

  final String id;
  final String alertId;
  final String channel;
  final String status;
  final String? recipient;
  final String? message;
  final DateTime? createdAt;
  final DateTime? sentAt;

  AlertNotification toDomain() {
    return AlertNotification(
      id: id,
      alertId: alertId,
      channel: channel,
      status: status,
      recipient: recipient,
      message: message,
      createdAt: createdAt,
      sentAt: sentAt,
    );
  }
}
