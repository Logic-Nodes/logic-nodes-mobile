import '../../../../core/network/api_helpers.dart';
import '../../domain/entities/incident.dart';

class IncidentModel {
  const IncidentModel({
    required this.id,
    required this.alertId,
    required this.type,
    required this.status,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory IncidentModel.fromMap(Map<String, dynamic> map) {
    return IncidentModel(
      id: stringValue(map['id']),
      alertId: stringValue(map['alertId']),
      type: stringValue(map['incidentType'] ?? map['type']).toUpperCase(),
      status: stringValue(map['incidentStatus'] ?? map['status']).toUpperCase(),
      description: nullableStringValue(map['description']),
      createdAt: dateValue(map['createdAt']),
      updatedAt: dateValue(map['updatedAt']),
    );
  }

  final String id;
  final String alertId;
  final String type;
  final String status;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Incident toDomain() {
    return Incident(
      id: id,
      alertId: alertId,
      type: type,
      status: status,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
