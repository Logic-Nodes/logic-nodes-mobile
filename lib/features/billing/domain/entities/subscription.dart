class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.limits,
    required this.price,
    required this.description,
  });

  final int id;
  final String name;
  final String limits;
  final double price;
  final String description;

  String get priceLabel => '\$${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}/month';
}

class Subscription {
  const Subscription({
    required this.id,
    required this.status,
    required this.renewal,
    required this.paymentMethod,
    required this.plan,
  });

  final int id;
  final String status;
  final String renewal;
  final String paymentMethod;
  final Plan plan;

  bool get isCanceled => status.toUpperCase() == 'CANCELED';
  bool get hasPaymentMethod => paymentMethod.trim().isNotEmpty;
}

class Payment {
  const Payment({
    required this.id,
    required this.status,
    required this.transactionId,
    required this.amount,
    required this.paymentDate,
    required this.receiptUrl,
  });

  final int id;
  final String status;
  final String transactionId;
  final double amount;
  final String paymentDate;
  final String receiptUrl;

  String get amountLabel => '\$${amount.toStringAsFixed(2)}';
}

/// Local-only draft for the Link Payment Method screen.
///
/// The backend billing contract does not expose a card-linking endpoint yet,
/// so this stays a client-side value object captured from the form.
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
