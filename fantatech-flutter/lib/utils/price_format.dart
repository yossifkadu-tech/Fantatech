// ─────────────────────────────────────────────────────────────────────────────
// Price formatting.
//   • All languages  → USD  ($)
//   • Hebrew only     → ILS  (₪), converted from the USD base price.
// ─────────────────────────────────────────────────────────────────────────────

/// Approximate USD→ILS rate used for display only.
const double kUsdToIls = 3.7;

/// Format a USD base price. When [isHebrew] is true, convert to shekels.
String formatPrice(num usd, {required bool isHebrew}) {
  if (isHebrew) {
    return '₪${(usd * kUsdToIls).round()}';
  }
  return '\$${usd.round()}';
}
