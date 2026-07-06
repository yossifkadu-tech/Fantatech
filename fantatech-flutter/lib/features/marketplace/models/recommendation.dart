import 'product.dart';

enum RecoStatus { shown, clicked, dismissed }

/// A scored product recommendation produced by the RecommendationEngine.
class Recommendation {
  final Product product;
  final double score; // 0..1
  final String reason; // human-readable "why" shown in the card
  final RecoStatus status;

  const Recommendation({
    required this.product,
    required this.score,
    required this.reason,
    this.status = RecoStatus.shown,
  });

  Recommendation copyWith({RecoStatus? status}) => Recommendation(
        product: product,
        score: score,
        reason: reason,
        status: status ?? this.status,
      );
}
