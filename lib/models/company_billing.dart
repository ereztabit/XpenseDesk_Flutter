class CompanyBilling {
  final BillingSubscription? subscription;
  final BillingPaymentMethod? paymentMethod;
  final BillingInfo billingInfo;

  const CompanyBilling({
    required this.subscription,
    required this.paymentMethod,
    required this.billingInfo,
  });

  factory CompanyBilling.fromJson(Map<String, dynamic> json) {
    return CompanyBilling(
      subscription: json['subscription'] != null
          ? BillingSubscription.fromJson(
              json['subscription'] as Map<String, dynamic>)
          : null,
      paymentMethod: json['paymentMethod'] != null
          ? BillingPaymentMethod.fromJson(
              json['paymentMethod'] as Map<String, dynamic>)
          : null,
      billingInfo: BillingInfo.fromJson(
          json['billingInfo'] as Map<String, dynamic>),
    );
  }
}

class BillingSubscription {
  final int planId;
  final String planName;
  final int subscriptionStatusId;
  final String subscriptionStatusName;
  final DateTime? startDate;
  final DateTime endDate;
  final double nextChargeAmount;
  final int freeMonthsRemaining;
  final BillingFuturePlan? futurePlan;

  const BillingSubscription({
    required this.planId,
    required this.planName,
    required this.subscriptionStatusId,
    required this.subscriptionStatusName,
    this.startDate,
    required this.endDate,
    required this.nextChargeAmount,
    required this.freeMonthsRemaining,
    this.futurePlan,
  });

  bool get isCancelled => subscriptionStatusName == 'CancellationRequest';
  bool get isActive => subscriptionStatusName == 'Active';
  bool get hasFreeMonths => freeMonthsRemaining > 0;
  bool get hasPendingSwitch => futurePlan != null;

  factory BillingSubscription.fromJson(Map<String, dynamic> json) {
    return BillingSubscription(
      planId: json['planId'] as int,
      planName: json['planName'] as String,
      subscriptionStatusId: json['subscriptionStatusId'] as int,
      subscriptionStatusName: json['subscriptionStatusName'] as String,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: DateTime.parse(json['endDate'] as String),
      nextChargeAmount: (json['nextChargeAmount'] as num).toDouble(),
      freeMonthsRemaining: json['freeMonthsRemaining'] as int,
      futurePlan: json['futurePlan'] != null
          ? BillingFuturePlan.fromJson(
              json['futurePlan'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BillingFuturePlan {
  final int planId;
  final String planName;
  final DateTime startDate;
  final double chargeAmount;

  const BillingFuturePlan({
    required this.planId,
    required this.planName,
    required this.startDate,
    required this.chargeAmount,
  });

  factory BillingFuturePlan.fromJson(Map<String, dynamic> json) {
    return BillingFuturePlan(
      planId: json['planId'] as int,
      planName: json['planName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      chargeAmount: (json['chargeAmount'] as num).toDouble(),
    );
  }
}

class BillingPaymentMethod {
  final String brand;
  final String lastFourDigits;
  final int expiryMonth;
  final int expiryYear;
  final int paymentMethodStatusId;
  final String paymentMethodStatusName;
  final DateTime? lastTransactionDate;
  final int? lastBillingTransactionStatusId;
  final String? declineReason;
  final String? paymentProviderErrorCode;

  const BillingPaymentMethod({
    required this.brand,
    required this.lastFourDigits,
    required this.expiryMonth,
    required this.expiryYear,
    required this.paymentMethodStatusId,
    required this.paymentMethodStatusName,
    this.lastTransactionDate,
    this.lastBillingTransactionStatusId,
    this.declineReason,
    this.paymentProviderErrorCode,
  });

  // Status IDs: 1=Active, 2=Declined, 3=ExpiringSoon, 4=Expired
  bool get isActive => paymentMethodStatusId == 1;
  bool get isDeclined => paymentMethodStatusId == 2;
  bool get isExpiringSoon => paymentMethodStatusId == 3;
  bool get isExpired => paymentMethodStatusId == 4;

  /// Months remaining until card expiry (from today). 0 or negative = expired.
  int get monthsUntilExpiry {
    final now = DateTime.now();
    return (expiryYear - now.year) * 12 + (expiryMonth - now.month);
  }

  String get expiryDisplay {
    final m = expiryMonth.toString().padLeft(2, '0');
    return '$m/$expiryYear';
  }

  factory BillingPaymentMethod.fromJson(Map<String, dynamic> json) {
    return BillingPaymentMethod(
      brand: json['brand'] as String,
      lastFourDigits: json['lastFourDigits'] as String,
      expiryMonth: json['expiryMonth'] as int,
      expiryYear: json['expiryYear'] as int,
      paymentMethodStatusId: json['paymentMethodStatusId'] as int,
      paymentMethodStatusName: json['paymentMethodStatusName'] as String,
      lastTransactionDate: json['lastTransactionDate'] != null
          ? DateTime.parse(json['lastTransactionDate'] as String)
          : null,
      lastBillingTransactionStatusId:
          json['lastBillingTransactionStatusId'] as int?,
      declineReason: json['declineReason'] as String?,
      paymentProviderErrorCode: json['paymentProviderErrorCode'] as String?,
    );
  }
}

class BillingInfo {
  final String? billingName;
  final String? taxId;
  final String? countryCode;
  final String? countryName;
  final String? address;
  final String? phone;
  final String? accountantEmail;

  const BillingInfo({
    this.billingName,
    this.taxId,
    this.countryCode,
    this.countryName,
    this.address,
    this.phone,
    this.accountantEmail,
  });

  factory BillingInfo.fromJson(Map<String, dynamic> json) {
    return BillingInfo(
      billingName: json['billingName'] as String?,
      taxId: json['taxId'] as String?,
      countryCode: json['countryCode'] as String?,
      countryName: json['countryName'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      accountantEmail: json['accountantEmail'] as String?,
    );
  }
}
