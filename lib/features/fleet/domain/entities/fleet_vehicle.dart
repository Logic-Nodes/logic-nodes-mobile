class FleetVehicle {
  const FleetVehicle({
    required this.id,
    required this.plate,
    required this.type,
    required this.status,
    required this.deviceImeis,
    this.odometerKm,
  });

  final String id;
  final String plate;
  final String type;
  final String status;
  final num? odometerKm;
  final List<String> deviceImeis;

  bool get hasAssignedDevices => deviceImeis.isNotEmpty;

  String get statusLabel {
    switch (status) {
      case 'IN_SERVICE':
        return 'En servicio';
      case 'MAINTENANCE':
        return 'Mantenimiento';
      case 'OUT_OF_SERVICE':
        return 'Fuera de servicio';
      default:
        return status;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'TRUCK':
        return 'Camión';
      case 'VAN':
        return 'Furgoneta';
      case 'MOTORCYCLE':
        return 'Motocicleta';
      case 'CAR':
        return 'Automóvil';
      default:
        return type;
    }
  }

  FleetVehicle copyWith({
    String? plate,
    String? type,
    String? status,
    num? odometerKm,
    List<String>? deviceImeis,
  }) {
    return FleetVehicle(
      id: id,
      plate: plate ?? this.plate,
      type: type ?? this.type,
      status: status ?? this.status,
      odometerKm: odometerKm ?? this.odometerKm,
      deviceImeis: deviceImeis ?? this.deviceImeis,
    );
  }
}
