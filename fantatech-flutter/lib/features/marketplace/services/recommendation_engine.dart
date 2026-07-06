import '../models/product.dart';
import '../models/recommendation.dart';
import 'ad_targeting_service.dart';

/// Scores catalog products against the home profile. Pure, on-device logic.
///
///   score = compatibility*0.4 + gap*0.3 + rating*0.2 + recency*0.1
class RecommendationEngine {
  final AdTargetingService targeting;

  /// Product categories the user explicitly dismissed (suppressed 30 days).
  final Set<String> dismissedCategories;

  const RecommendationEngine({
    required this.targeting,
    this.dismissedCategories = const {},
  });

  List<Recommendation> rank(List<Product> catalog) {
    final out = <Recommendation>[];

    for (final p in catalog) {
      if (dismissedCategories.contains(p.category)) continue;
      // Don't recommend a category the user already covers heavily, unless
      // it's an accessory cross-sell (rating-driven).
      final fillsGap = targeting.categoryGaps.contains(p.category);

      final compatScore = p.compatibility
              .any((c) => targeting.ownedCategories.contains(_compatToCategory(c)))
          ? 1.0
          : 0.4;
      final gapScore = fillsGap ? 1.0 : 0.2;
      final ratingScore = (p.rating / 5.0).clamp(0.0, 1.0);
      const recencyScore = 0.5; // placeholder until catalog carries timestamps

      final score = compatScore * 0.4 +
          gapScore * 0.3 +
          ratingScore * 0.2 +
          recencyScore * 0.1;

      out.add(Recommendation(
        product: p,
        score: double.parse(score.toStringAsFixed(3)),
        reason: _reasonFor(p, fillsGap),
      ));
    }

    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }

  String _reasonFor(Product p, bool fillsGap) {
    if (fillsGap) {
      switch (p.category) {
        case 'sensor':
          return 'הבית שלך חסר חיישן — מומלץ לאבטחה מלאה';
        case 'camera':
          return 'הוסף עיניים לבית — אין מצלמה מותקנת';
        case 'gateway':
          return 'גייטוויי ישפר את אמינות החיבור';
        case 'lock':
          return 'שדרג לנעילה חכמה';
        default:
          return 'מומלץ להשלמת המערכת';
      }
    }
    return 'תואם למכשירים שכבר יש לך';
  }

  static String _compatToCategory(String compat) {
    switch (compat) {
      case 'wiz':
      case 'wifi':
        return 'light';
      case 'rtsp':
      case 'onvif':
        return 'camera';
      case 'zigbee':
      case 'matter':
        return 'gateway';
      default:
        return compat;
    }
  }
}
