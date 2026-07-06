import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/marketplace_repository.dart';
import '../data/mock_marketplace_repository.dart';
import '../models/product.dart';
import '../models/recommendation.dart';
import '../models/subscription_plan.dart';
import '../services/ad_targeting_service.dart';
import '../services/recommendation_engine.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

/// Swap this override in main() / tests to use a REST-backed repository.
final marketplaceRepositoryProvider = Provider<MarketplaceRepository>(
  (ref) => MockMarketplaceRepository(),
);

/// The categories of devices currently in the home. The host app overrides
/// this provider to feed real device data in (kept decoupled from AppState).
final ownedDeviceTypesProvider = Provider<List<String>>((ref) => const []);

// ── Subscription (Free / Pro) ─────────────────────────────────────────────────

class SubscriptionNotifier extends StateNotifier<SubscriptionPlan> {
  SubscriptionNotifier(this._repo) : super(SubscriptionPlan.free) {
    _load();
  }
  final MarketplaceRepository _repo;

  Future<void> _load() async => state = await _repo.fetchSubscription();

  Future<void> upgradeToPro(String paymentToken) async {
    state = await _repo.upgradeToPro(paymentToken: paymentToken);
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionPlan>(
  (ref) => SubscriptionNotifier(ref.watch(marketplaceRepositoryProvider)),
);

/// Single source of truth for "should we show ads at all".
final adsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(subscriptionProvider).adsEnabled,
);

// ── Catalog ───────────────────────────────────────────────────────────────────

final productCatalogProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(marketplaceRepositoryProvider).fetchProducts(),
);

final bundlesProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(marketplaceRepositoryProvider).fetchBundles(),
);

// ── Recommendations ─────────────────────────────────────────────────────────────

/// Categories the user dismissed (suppressed). In-memory; persist in prod.
final dismissedCategoriesProvider =
    StateProvider<Set<String>>((ref) => <String>{});

/// Final, ranked, Pro-aware recommendation feed.
final recommendationsProvider = FutureProvider<List<Recommendation>>((ref) async {
  // Pro users never see recommendations.
  if (!ref.watch(adsEnabledProvider)) return const [];

  final catalog = await ref.watch(productCatalogProvider.future);
  final targeting =
      AdTargetingService.fromDeviceTypes(ref.watch(ownedDeviceTypesProvider));
  final engine = RecommendationEngine(
    targeting: targeting,
    dismissedCategories: ref.watch(dismissedCategoriesProvider),
  );
  return engine.rank(catalog);
});
