import 'package:material_symbols_icons/symbols.dart';
// Shared navigation & modal widgets used across hub screens.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// FtBackButton
// Standard 38×38 back button. Respects app RTL setting.
// ─────────────────────────────────────────────────────────────
class FtBackButton extends StatelessWidget {
  const FtBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = context.select((AppState st) => st.isRtl);
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: context.tText2(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isRtl ? Symbols.chevron_right : Symbols.chevron_left,
          color: context.tText,
          size: 22,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FtModalHandle
// Drag handle shown at the top of every bottom sheet.
// ─────────────────────────────────────────────────────────────
class FtModalHandle extends StatelessWidget {
  const FtModalHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.tText2(0.24),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FtScreenHeader
// Standard screen top-bar: back button + centered title + optional trailing.
// ─────────────────────────────────────────────────────────────
class FtScreenHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const FtScreenHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          const FtBackButton(),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.tText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 38, child: trailing),
        ],
      ),
    );
  }
}
