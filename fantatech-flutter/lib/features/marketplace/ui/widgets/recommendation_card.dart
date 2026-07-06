import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';

import '../../models/recommendation.dart';

/// Native, dismissible "professional recommendation" card — never a banner.
class RecommendationCard extends StatelessWidget {
  final Recommendation reco;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const RecommendationCard({
    super.key,
    required this.reco,
    required this.onTap,
    required this.onDismiss,
  });

  static const _orange = Color(0xFFFF6B00);

  @override
  Widget build(BuildContext context) {
    final p = reco.product;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconFor(p.category), color: _orange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFF1A1A2E),
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    _tag('מומלץ'),
                  ],
                ),
                const SizedBox(height: 2),
                Text(reco.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('₪${p.priceIls.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: _orange, fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    const Icon(Symbols.star, color: Color(0xFFFFB800), size: 14),
                    Text(' ${p.rating}',
                        style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                    const Spacer(),
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('פרטים',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Padding(
              padding: EdgeInsetsDirectional.only(start: 6),
              child: Icon(Symbols.close, color: Color(0xFFC7C7CC), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: const TextStyle(
                color: _orange, fontSize: 9, fontWeight: FontWeight.w700)),
      );

  static IconData _iconFor(String category) {
    switch (category) {
      case 'camera':
        return Symbols.videocam;
      case 'sensor':
        return Symbols.sensors;
      case 'lock':
        return Symbols.lock;
      case 'gateway':
        return Symbols.router;
      case 'light':
        return Symbols.lightbulb;
      case 'bundle':
        return Symbols.inventory_2;
      default:
        return Symbols.devices_other;
    }
  }
}
