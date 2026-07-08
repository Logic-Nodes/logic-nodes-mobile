abstract final class StatusLabels {
  static String tripStatus(String? status) {
    return switch ((status ?? '').toUpperCase()) {
      'PLANNED' => 'Planificado',
      'IN_PROGRESS' => 'En curso',
      'COMPLETED' => 'Completado',
      'CANCELLED' => 'Cancelado',
      _ => status ?? '—',
    };
  }

  static String alertStatus(String? status) {
    return switch ((status ?? '').toUpperCase()) {
      'OPEN' => 'Abierta',
      'ACKNOWLEDGED' => 'Reconocida',
      'CLOSED' => 'Cerrada',
      'RESOLVED' => 'Resuelta',
      _ => status ?? '—',
    };
  }

  static String deliveryStatus(String? status) {
    return switch ((status ?? '').toUpperCase()) {
      'PENDING' => 'Pendiente',
      'DELIVERED' => 'Entregado',
      'FAILED' => 'Fallido',
      _ => status ?? '—',
    };
  }

  static String alertType(String? type) {
    return switch ((type ?? '').toUpperCase()) {
      'TEMPERATURE' => 'Temperatura',
      'DELAY' => 'Retraso',
      'VIBRATION' => 'Vibración',
      'GEOFENCE' => 'Geocerca',
      _ => type ?? '—',
    };
  }

  static String publicTripStatus(String? status) {
    return switch ((status ?? '').toUpperCase()) {
      'COMPLETED' => 'Entregado',
      'IN_PROGRESS' => 'En tránsito',
      'PLANNED' => 'Programado',
      'CANCELLED' => 'Cancelado',
      _ => tripStatus(status),
    };
  }
}
