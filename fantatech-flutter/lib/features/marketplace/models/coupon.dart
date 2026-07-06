enum CouponType { percent, fixed, bundle }

class Coupon {
  final String code;
  final CouponType type;
  final double value; // percent (0..100) or fixed ILS
  final String? vendorId;
  final double minCartIls;
  final DateTime? expiresAt;
  final int? usageLimit;
  final int perUser;

  const Coupon({
    required this.code,
    required this.type,
    required this.value,
    this.vendorId,
    this.minCartIls = 0,
    this.expiresAt,
    this.usageLimit,
    this.perUser = 1,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Returns the discount in ILS for a given cart subtotal.
  double discountFor(double cartIls) {
    if (isExpired || cartIls < minCartIls) return 0;
    switch (type) {
      case CouponType.percent:
        return cartIls * (value / 100);
      case CouponType.fixed:
      case CouponType.bundle:
        return value.clamp(0, cartIls);
    }
  }

  factory Coupon.fromJson(Map<String, dynamic> j) => Coupon(
        code: j['code'] as String,
        type: CouponType.values
            .firstWhere((e) => e.name == j['type'], orElse: () => CouponType.percent),
        value: (j['value'] as num?)?.toDouble() ?? 0,
        vendorId: j['vendorId'] as String?,
        minCartIls: (j['minCartIls'] as num?)?.toDouble() ?? 0,
        expiresAt: j['expiresAt'] != null
            ? DateTime.tryParse(j['expiresAt'] as String)
            : null,
        usageLimit: j['usageLimit'] as int?,
        perUser: j['perUser'] as int? ?? 1,
      );
}
