class FleetDevice {
  const FleetDevice({
    required this.id,
    required this.imei,
    required this.online,
    this.vehiclePlate,
    this.firmware,
  });

  final String id;
  final String imei;
  final bool online;
  final String? vehiclePlate;
  final String? firmware;

  bool get isAssigned => vehiclePlate != null && vehiclePlate!.isNotEmpty;

  FleetDevice copyWith({
    String? imei,
    bool? online,
    String? vehiclePlate,
    String? firmware,
  }) {
    return FleetDevice(
      id: id,
      imei: imei ?? this.imei,
      online: online ?? this.online,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      firmware: firmware ?? this.firmware,
    );
  }
}
