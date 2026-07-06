import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/application/controllers/session_controller.dart';
import '../../../home/domain/entities/home_dashboard.dart';
import '../../data/models/trip_models.dart';
import '../../domain/repositories/trips_repository.dart';

enum TripStatusFilter {
  all,
  planned,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case TripStatusFilter.all:
        return 'All';
      case TripStatusFilter.planned:
        return 'Planned';
      case TripStatusFilter.inProgress:
        return 'In progress';
      case TripStatusFilter.completed:
        return 'Completed';
      case TripStatusFilter.cancelled:
        return 'Cancelled';
    }
  }

  String? get backendStatus {
    switch (this) {
      case TripStatusFilter.all:
        return null;
      case TripStatusFilter.planned:
        return 'PLANNED';
      case TripStatusFilter.inProgress:
        return 'IN_PROGRESS';
      case TripStatusFilter.completed:
        return 'COMPLETED';
      case TripStatusFilter.cancelled:
        return 'CANCELLED';
    }
  }

  bool matches(HomeTrip trip) {
    if (this == TripStatusFilter.all) {
      return true;
    }

    return trip.status == backendStatus;
  }
}

class TripsController extends ChangeNotifier {
  TripsController({
    required this.tripsRepository,
    required this.sessionController,
  });

  final TripsRepository tripsRepository;
  final SessionController sessionController;

  List<HomeTrip> _trips = const [];
  HomeTrip? _selectedTrip;
  List<HomeDeliveryOrder> _deliveryOrders = const [];
  List<OriginPointModel> _originPoints = const [];
  List<HomeVehicle> _vehicles = const [];
  List<HomeDevice> _devices = const [];

  bool _isLoading = false;
  bool _isLoadingDetail = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  TripStatusFilter _statusFilter = TripStatusFilter.all;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  TripStatusFilter get statusFilter => _statusFilter;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  HomeTrip? get selectedTrip => _selectedTrip;
  List<HomeDeliveryOrder> get deliveryOrders => _deliveryOrders;
  List<OriginPointModel> get originPoints => _originPoints;
  List<HomeVehicle> get vehicles => _vehicles;
  List<HomeDevice> get devices => _devices;

  List<HomeTrip> get visibleTrips {
    return _trips.where((trip) {
      if (!_statusFilter.matches(trip)) {
        return false;
      }

      final createdAt = trip.createdAt;
      if (createdAt == null) {
        return _dateFrom == null && _dateTo == null;
      }

      if (_dateFrom != null) {
        final from = DateTime(_dateFrom!.year, _dateFrom!.month, _dateFrom!.day);
        if (createdAt.isBefore(from)) {
          return false;
        }
      }

      if (_dateTo != null) {
        final to = DateTime(
          _dateTo!.year,
          _dateTo!.month,
          _dateTo!.day,
          23,
          59,
          59,
        );
        if (createdAt.isAfter(to)) {
          return false;
        }
      }

      return true;
    }).toList(growable: false);
  }

  void changeStatusFilter(TripStatusFilter filter) {
    if (filter == _statusFilter) {
      return;
    }

    _statusFilter = filter;
    notifyListeners();
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    _dateFrom = from;
    _dateTo = to;
    notifyListeners();
  }

  void clearDateRange() {
    _dateFrom = null;
    _dateTo = null;
    notifyListeners();
  }

  Future<void> load() async {
    final session = sessionController.session;
    if (session == null || _isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final status = _statusFilter.backendStatus;
      if (status != null) {
        _trips = await tripsRepository.searchTrips(
          accessToken: session.accessToken,
          status: status,
        );
      } else {
        _trips = await tripsRepository.listTrips(
          accessToken: session.accessToken,
        );
      }
    } on AppException catch (exception) {
      _errorMessage = exception.message;
    } on Exception {
      _errorMessage = 'Unable to load trips from the backend.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFormData() async {
    final session = sessionController.session;
    if (session == null) {
      return;
    }

    try {
      final results = await Future.wait([
        tripsRepository.listOriginPoints(accessToken: session.accessToken),
        tripsRepository.listVehicles(accessToken: session.accessToken),
        tripsRepository.listDevices(accessToken: session.accessToken),
      ]);

      _originPoints = results[0] as List<OriginPointModel>;
      _vehicles = results[1] as List<HomeVehicle>;
      _devices = results[2] as List<HomeDevice>;
      notifyListeners();
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      notifyListeners();
    }
  }

  Future<void> loadTripDetail(String tripId) async {
    final session = sessionController.session;
    if (session == null || _isLoadingDetail) {
      return;
    }

    _isLoadingDetail = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        tripsRepository.getTrip(
          accessToken: session.accessToken,
          tripId: tripId,
        ),
        tripsRepository.listDeliveryOrdersByTrip(
          accessToken: session.accessToken,
          tripId: tripId,
        ),
      ]);

      _selectedTrip = results[0] as HomeTrip;
      _deliveryOrders = results[1] as List<HomeDeliveryOrder>;
      _replaceTrip(_selectedTrip!);
    } on AppException catch (exception) {
      _errorMessage = exception.message;
    } on Exception {
      _errorMessage = 'Unable to load trip details.';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<HomeTrip?> createTrip({
    String? vehicleId,
    String? deviceId,
    String? originPointId,
  }) async {
    final session = sessionController.session;
    if (session == null || _isSubmitting) {
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = session.user.id;
      final trip = await tripsRepository.createTrip(
        accessToken: session.accessToken,
        request: CreateTripRequest(
          merchantId: userId,
          driverId: userId,
          vehicleId: vehicleId,
          deviceId: deviceId,
          originPointId: originPointId,
        ),
      );
      _trips = [trip, ..._trips];
      return trip;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> startTrip(String tripId) async {
    return _mutateTrip(
      () => tripsRepository.startTrip(
        accessToken: sessionController.session!.accessToken,
        tripId: tripId,
      ),
    );
  }

  Future<bool> completeTrip(String tripId) async {
    return _mutateTrip(
      () => tripsRepository.completeTrip(
        accessToken: sessionController.session!.accessToken,
        tripId: tripId,
      ),
    );
  }

  Future<bool> deleteTrip(String tripId) async {
    final session = sessionController.session;
    if (session == null || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await tripsRepository.deleteTrip(
        accessToken: session.accessToken,
        tripId: tripId,
      );
      _trips = _trips.where((trip) => trip.id != tripId).toList(growable: false);
      if (_selectedTrip?.id == tripId) {
        _selectedTrip = null;
        _deliveryOrders = const [];
      }
      return true;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> createDeliveryOrder({
    required String tripId,
    required String clientEmail,
    required int sequenceOrder,
    String? address,
  }) async {
    final session = sessionController.session;
    if (session == null || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final order = await tripsRepository.createDeliveryOrder(
        accessToken: session.accessToken,
        request: CreateDeliveryOrderRequest(
          tripId: tripId,
          clientEmail: clientEmail,
          sequenceOrder: sequenceOrder,
          address: address,
        ),
      );
      _deliveryOrders = [..._deliveryOrders, order];
      return true;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> markDelivery(String deliveryOrderId) async {
    final session = sessionController.session;
    if (session == null || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final updated = await tripsRepository.markDelivery(
        accessToken: session.accessToken,
        deliveryOrderId: deliveryOrderId,
      );
      _deliveryOrders = _deliveryOrders
          .map((order) => order.id == updated.id ? updated : order)
          .toList(growable: false);
      return true;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> _mutateTrip(Future<HomeTrip> Function() action) async {
    final session = sessionController.session;
    if (session == null || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final updated = await action();
      _selectedTrip = updated;
      _replaceTrip(updated);
      return true;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void _replaceTrip(HomeTrip updated) {
    _trips = _trips
        .map((trip) => trip.id == updated.id ? updated : trip)
        .toList(growable: false);
  }
}
