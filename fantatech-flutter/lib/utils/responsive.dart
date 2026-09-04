import 'package:flutter/widgets.dart';

/// Scales a grid's column count to the available width instead of a fixed
/// phone-portrait number, so tablets and landscape don't end up with a
/// couple of stretched cards and a wall of empty space.
///
/// [phoneColumns] is what the grid already used for a normal phone in
/// portrait (kept as the floor). Width is measured against 180px per
/// column as a rough "comfortable card width" — every extra ~180px of
/// screen width earns one more column, capped at [maxColumns].
int responsiveColumns(
  BuildContext context, {
  required int phoneColumns,
  int maxColumns = 6,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final byWidth = (width / 180).floor();
  return byWidth.clamp(phoneColumns, maxColumns);
}
