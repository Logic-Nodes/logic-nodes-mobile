import '../../../../core/network/api_helpers.dart';
import '../../../../core/utils/json_parse.dart';

export '../../../home/data/models/home_dashboard_model.dart'
    show HomeTripModel, HomeDeliveryOrderModel, HomeVehicleModel, HomeDeviceModel;

class OriginPointModel {
  const OriginPointModel({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory OriginPointModel.fromMap(Map<String, dynamic> map) {
    return OriginPointModel(
      id: stringValue(map['id']),
      name: stringValue(map['name']),
      address: nullableStringValue(map['address']),
      latitude: nullableNumValue(map['latitude']),
      longitude: nullableNumValue(map['longitude']),
    );
  }

  final String id;
  final String name;
  final String? address;
  final num? latitude;
  final num? longitude;
}

class CreateTripRequest {
  const CreateTripRequest({
    required this.merchantId,
    required this.driverId,
    this.deviceId,
    this.vehicleId,
    this.originPointId,
    this.status = 'PLANNED',
  });

  Map<String, dynamic> toJson() {
    return {
      'merchantId': merchantId,
      'driverId': driverId,
      if (deviceId != null) 'deviceId': deviceId,
      if (vehicleId != null) 'vehicleId': vehicleId,
      if (originPointId != null) 'originPointId': originPointId,
      'status': status,
    };
  }

  final String merchantId;
  final String driverId;
  final String? deviceId;
  final String? vehicleId;
  final String? originPointId;
  final String status;
}

class CreateDeliveryOrderRequest {
  const CreateDeliveryOrderRequest({
    required this.tripId,
    required this.clientEmail,
    required this.sequenceOrder,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'clientEmail': clientEmail,
      'sequenceOrder': sequenceOrder,
      if (address != null && address!.isNotEmpty) 'address': address,
    };
  }

  final String tripId;
  final String clientEmail;
  final int sequenceOrder;
  final String? address;
}

class CreateOriginPointRequest {
  const CreateOriginPointRequest({
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  final String name;
  final String? address;
  final num? latitude;
  final num? longitude;
}
