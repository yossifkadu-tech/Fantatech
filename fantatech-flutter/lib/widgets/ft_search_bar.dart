import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

/// Shared search field used across device-picker screens (brand lists,
/// device catalogs, etc.) so search look & feel stays consistent.
class FtSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  const FtSearchBar({super.key, required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tText2(0.09)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: context.tText, fontSize: 13),
        textDirection: context.select((AppState st) => st.isRtl)
            ? TextDirection.rtl : TextDirection.ltr,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
              color: context.tText2(0.30), fontSize: 13),
          prefixIcon: Icon(Symbols.search,
              color: context.tText2(0.35), size: 18),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () => controller.clear(),
                  child: Icon(Symbols.close,
                      color: context.tText2(0.35), size: 16))
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
