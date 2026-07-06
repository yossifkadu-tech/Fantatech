import '../models/product.dart';
import '../models/coupon.dart';
import '../models/subscription_plan.dart';

/// Abstraction over the monetization backend. Swap the mock for a REST-backed
/// implementation without touching services / UI (Repository Pattern).
abstract class MarketplaceRepository {
  /// Full catalog, optionally filtered.
  Future<List<Product>> fetchProducts({String? category, List<String>? compat});

  /// Curated bundles ("secure-home kit", …).
  Future<List<Product>> fetchBundles();

  /// Validate a coupon against the server (returns null if invalid).
  Future<Coupon?> validateCoupon(String code, {double cartIls});

  /// Current user's subscription plan.
  Future<SubscriptionPlan> fetchSubscription();

  /// Upgrade to Pro. Returns the new plan on success.
  Future<SubscriptionPlan> upgradeToPro({required String paymentToken});

  /// Fire-and-forget ad telemetry (impression / click / convert).
  Future<void> trackAdEvent({
    required String creativeId,
    required String type,
    required String placement,
  });
}
