class Incident {
  const Incident({
    required this.id,
    required this.alertId,
    required this.type,
    required this.status,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String alertId;
  final String type;
  final String status;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
