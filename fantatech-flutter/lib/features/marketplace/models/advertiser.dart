enum ContractType { cpc, cpm, cpa, affiliate, house }

enum AdvertiserTier { partner, premium, house }

/// A vendor / business partner that supplies products and runs campaigns.
class Advertiser {
  final String id;
  final String name;
  final ContractType contractType;
  final AdvertiserTier tier;
  final double balanceIls;
  final bool approved;

  const Advertiser({
    required this.id,
    required this.name,
    this.contractType = ContractType.affiliate,
    this.tier = AdvertiserTier.partner,
    this.balanceIls = 0,
    this.approved = false,
  });

  factory Advertiser.fromJson(Map<String, dynamic> j) => Advertiser(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        contractType: ContractType.values.firstWhere(
            (e) => e.name == j['contractType'],
            orElse: () => ContractType.affiliate),
        tier: AdvertiserTier.values.firstWhere((e) => e.name == j['tier'],
            orElse: () => AdvertiserTier.partner),
        balanceIls: (j['balanceIls'] as num?)?.toDouble() ?? 0,
        approved: j['approved'] as bool? ?? false,
      );
}
