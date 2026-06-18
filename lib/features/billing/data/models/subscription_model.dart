import '../../domain/entities/subscription.dart';

class PlanModel {
  const PlanModel({
    required this.id,
    required this.name,
    required this.limits,
    required this.price,
    required this.description,
  });

  factory PlanModel.fromMap(Map<String, dynamic> map) {
    return PlanModel(
      id: _intValue(map['id']),
      name: _stringValue(map['name'], fallback: 'PLAN'),
      limits: _stringValue(map['limits'], fallback: ''),
      price: _doubleValue(map['price']),
      description: _stringValue(map['description'], fallback: ''),
    );
  }

  final int id;
  final String name;
  final String limits;
  final double price;
  final String description;

  Plan toDomain() => Plan(
        id: id,
        name: name,
        limits: limits,
        price: price,
        description: description,
      );
}

class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    required this.status,
    required this.renewal,
    required this.paymentMethod,
    required this.plan,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    final rawPlan = map['plan'];
    return SubscriptionModel(
      id: _intValue(map['id']),
      status: _stringValue(map['status'], fallback: 'ACTIVE'),
      renewal: _stringValue(map['renewal'], fallback: '--'),
      paymentMethod: _stringValue(map['paymentMethod'], fallback: ''),
      plan: PlanModel.fromMap(
        rawPlan is Map<String, dynamic> ? rawPlan : const {},
      ),
    );
  }

  final int id;
  final String status;
  final String renewal;
  final String paymentMethod;
  final PlanModel plan;

  Subscription toDomain() => Subscription(
        id: id,
        status: status,
        renewal: renewal,
        paymentMethod: paymentMethod,
        plan: plan.toDomain(),
      );
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.status,
    required this.transactionId,
    required this.amount,
    required this.paymentDate,
    required this.receiptUrl,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: _intValue(map['id']),
      status: _stringValue(map['status'], fallback: 'PAID'),
      transactionId: _stringValue(map['transactionId'], fallback: '--'),
      amount: _doubleValue(map['amount']),
      paymentDate: _stringValue(map['paymentDate'], fallback: '--'),
      receiptUrl: _stringValue(map['receiptUrl'], fallback: ''),
    );
  }

  final int id;
  final String status;
  final String transactionId;
  final double amount;
  final String paymentDate;
  final String receiptUrl;

  Payment toDomain() => Payment(
        id: id,
        status: status,
        transactionId: transactionId,
        amount: amount,
        paymentDate: paymentDate,
        receiptUrl: receiptUrl,
      );
}

String _stringValue(Object? value, {required String fallback}) {
  final normalized = '$value'.trim();
  if (normalized.isEmpty || normalized == 'null') {
    return fallback;
  }
  return normalized;
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? 0;
}

double _doubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value') ?? 0;
}
