class Subscription {
  const Subscription({
    required this.planName,
    required this.amountLabel,
    required this.status,
    required this.renewalLabel,
    this.paymentMethodLabel,
  });

  final String planName;
  final String amountLabel;
  final String status;
  final String renewalLabel;
  final String? paymentMethodLabel;

  bool get hasPaymentMethod =>
      paymentMethodLabel != null && paymentMethodLabel!.trim().isNotEmpty;

  Subscription copyWith({String? paymentMethodLabel}) {
    return Subscription(
      planName: planName,
      amountLabel: amountLabel,
      status: status,
      renewalLabel: renewalLabel,
      paymentMethodLabel: paymentMethodLabel ?? this.paymentMethodLabel,
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.date,
    required this.amountLabel,
    required this.status,
    required this.transactionId,
  });

  final String date;
  final String amountLabel;
  final String status;
  final String transactionId;
}

class PaymentMethodDraft {
  const PaymentMethodDraft({
    required this.cardNumber,
    required this.expireDate,
    required this.cvc,
    required this.postalCode,
    required this.country,
  });

  final String cardNumber;
  final String expireDate;
  final String cvc;
  final String postalCode;
  final String country;

  String get maskedLabel {
    final digitsOnly = cardNumber.replaceAll(RegExp(r'\D'), '');
    final lastFour = digitsOnly.length >= 4
        ? digitsOnly.substring(digitsOnly.length - 4)
        : digitsOnly;
    return 'Card ending in $lastFour';
  }
}
