import '../../domain/entities/subscription.dart';

class SubscriptionModel {
  const SubscriptionModel({
    required this.planName,
    required this.amountCents,
    required this.currency,
    required this.status,
    required this.renewalDate,
    this.paymentMethodLabel,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      planName: _stringValue(map['planName'], fallback: 'PROFESSIONAL'),
      amountCents: _intValue(map['amountCents']),
      currency: _stringValue(map['currency'], fallback: 'USD'),
      status: _stringValue(map['status'], fallback: 'ACTIVE'),
      renewalDate: _stringValue(map['renewalDate'], fallback: '--'),
      paymentMethodLabel: _nullableStringValue(map['paymentMethodLabel']),
    );
  }

  final String planName;
  final int amountCents;
  final String currency;
  final String status;
  final String renewalDate;
  final String? paymentMethodLabel;

  Subscription toDomain() {
    return Subscription(
      planName: planName,
      amountLabel: '${_formatAmount(amountCents, currency)}/month',
      status: status,
      renewalLabel: renewalDate,
      paymentMethodLabel: paymentMethodLabel,
    );
  }
}

class PaymentRecordModel {
  const PaymentRecordModel({
    required this.date,
    required this.amountCents,
    required this.currency,
    required this.status,
    required this.transactionId,
  });

  factory PaymentRecordModel.fromMap(Map<String, dynamic> map) {
    return PaymentRecordModel(
      date: _stringValue(map['date'], fallback: '--'),
      amountCents: _intValue(map['amountCents']),
      currency: _stringValue(map['currency'], fallback: 'USD'),
      status: _stringValue(map['status'], fallback: 'PAID'),
      transactionId: _stringValue(map['transactionId'], fallback: '--'),
    );
  }

  final String date;
  final int amountCents;
  final String currency;
  final String status;
  final String transactionId;

  PaymentRecord toDomain() {
    return PaymentRecord(
      date: date,
      amountLabel: _formatAmount(amountCents, currency),
      status: status,
      transactionId: transactionId,
    );
  }
}

String _formatAmount(int amountCents, String currency) {
  final amount = (amountCents / 100).toStringAsFixed(2);
  final symbol = currency.toUpperCase() == 'USD' ? r'$' : '$currency ';
  return '$symbol$amount';
}

String _stringValue(Object? value, {required String fallback}) {
  final normalized = '$value'.trim();
  if (normalized.isEmpty || normalized == 'null') {
    return fallback;
  }
  return normalized;
}

String? _nullableStringValue(Object? value) {
  final normalized = '$value'.trim();
  if (normalized.isEmpty || normalized == 'null') {
    return null;
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
