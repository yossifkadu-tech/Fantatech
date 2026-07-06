enum PlanTier { free, pro }

class SubscriptionPlan {
  final PlanTier tier;
  final DateTime? renewsAt;

  const SubscriptionPlan({required this.tier, this.renewsAt});

  /// Pro hides all advertising / recommendation slots.
  bool get adsEnabled => tier == PlanTier.free;
  bool get isPro => tier == PlanTier.pro;

  static const free = SubscriptionPlan(tier: PlanTier.free);

  factory SubscriptionPlan.fromJson(Map<String, dynamic> j) => SubscriptionPlan(
        tier: PlanTier.values
            .firstWhere((e) => e.name == j['tier'], orElse: () => PlanTier.free),
        renewsAt: j['renewsAt'] != null
            ? DateTime.tryParse(j['renewsAt'] as String)
            : null,
      );
}
