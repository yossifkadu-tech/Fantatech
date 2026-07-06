import '../models/product.dart';
import '../models/coupon.dart';
import '../models/subscription_plan.dart';
import 'marketplace_repository.dart';

/// In-memory implementation used during development and for offline demos.
class MockMarketplaceRepository implements MarketplaceRepository {
  SubscriptionPlan _plan = SubscriptionPlan.free;

  static const _catalog = <Product>[
    Product(id: 'p_cam4k', sku: 'FT-CAM-4K', title: 'FT Camera 4K', vendorId: 'fantatech',
        category: 'camera', priceIls: 329, rating: 4.7, compatibility: ['onvif', 'rtsp']),
    Product(id: 'p_smoke', sku: 'FT-SMOKE', title: 'גלאי עשן חכם', vendorId: 'fantatech',
        category: 'sensor', priceIls: 119, rating: 4.6, compatibility: ['zigbee']),
    Product(id: 'p_hub', sku: 'FT-HUB', title: 'FantaTech Hub Pro', vendorId: 'fantatech',
        category: 'gateway', priceIls: 549, rating: 4.8, compatibility: ['matter', 'zigbee']),
    Product(id: 'p_lock', sku: 'FT-LOCK', title: 'מנעול חכם', vendorId: 'partner_yale',
        category: 'lock', priceIls: 899, rating: 4.5, compatibility: ['ble', 'wifi']),
    Product(id: 'p_leak', sku: 'FT-LEAK', title: 'חיישן הצפה', vendorId: 'fantatech',
        category: 'sensor', priceIls: 89, rating: 4.4, compatibility: ['zigbee']),
    Product(id: 'p_bulb', sku: 'FT-BULB', title: 'נורה חכמה RGB', vendorId: 'partner_wiz',
        category: 'light', priceIls: 69, rating: 4.6, compatibility: ['wiz', 'wifi']),
  ];

  static const _bundles = <Product>[
    Product(id: 'b_secure', sku: 'FT-KIT-SECURE', title: 'ערכת בית מאובטח',
        vendorId: 'fantatech', category: 'bundle', priceIls: 1299, rating: 4.9, isBundle: true),
  ];

  @override
  Future<List<Product>> fetchProducts({String? category, List<String>? compat}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _catalog.where((p) {
      if (category != null && p.category != category) {
        return false;
      }
      if (compat != null &&
          compat.isNotEmpty &&
          !p.compatibility.any(compat.contains)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<Product>> fetchBundles() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _bundles;
  }

  @override
  Future<Coupon?> validateCoupon(String code, {double cartIls = 0}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (code.toUpperCase() == 'FANTA10') {
      return const Coupon(code: 'FANTA10', type: CouponType.percent, value: 10);
    }
    return null;
  }

  @override
  Future<SubscriptionPlan> fetchSubscription() async => _plan;

  @override
  Future<SubscriptionPlan> upgradeToPro({required String paymentToken}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _plan = SubscriptionPlan(
        tier: PlanTier.pro, renewsAt: DateTime.now().add(const Duration(days: 30)));
    return _plan;
  }

  @override
  Future<void> trackAdEvent({
    required String creativeId,
    required String type,
    required String placement,
  }) async {
    // No-op in mock; a real impl POSTs to /v1/ads/{type}.
  }
}
