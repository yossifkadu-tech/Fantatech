import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../l10n/strings.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AC mode/fan option mappers — shared by every screen that renders climate
// mode chips (device detail sheet, room climate section). Maps a raw HVAC
// mode value (local or HA-reported) to a localized (value, label, icon)
// record. Unknown modes fall back to a prettified raw name so new firmware
// modes still render instead of breaking.
// ─────────────────────────────────────────────────────────────────────────────

(String, String, IconData) acModeOption(S s, String m) => switch (m) {
      'cool'                => (m, s.modeCool, Symbols.ac_unit),
      'heat'                => (m, s.modeHeat, Symbols.wb_sunny),
      'fan' || 'fan_only'   => (m, s.modeFan, Symbols.air),
      'dry'                 => (m, s.modeDry, Symbols.water_drop),
      'auto' || 'heat_cool' => (m, s.modeAuto, Symbols.autorenew),
      _                     => (m, prettyMode(m), Symbols.tune),
    };

(String, String, IconData) acFanOption(S s, String m) => switch (m) {
      'low'             => (m, s.fanLow, Symbols.signal_cellular_alt_1_bar),
      'med' || 'medium' => (m, s.fanMed, Symbols.signal_cellular_alt_2_bar),
      'high'            => (m, s.fanHigh, Symbols.signal_cellular_alt),
      'auto'            => (m, s.modeAuto, Symbols.autorenew),
      _                 => (m, prettyMode(m), Symbols.air),
    };

/// "fan_only" → "Fan Only" — readable fallback for mode names the app has
/// no translation for.
String prettyMode(String raw) => raw
    .replaceAll('_', ' ')
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');
