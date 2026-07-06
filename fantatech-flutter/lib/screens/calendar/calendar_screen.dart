import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// Jewish holiday data (Gregorian dates for year 5786 / 2025-26)
// ─────────────────────────────────────────────────────────────
class _JewishHoliday {
  final DateTime date;
  final String Function(S s) name;
  final bool isMinor;

  const _JewishHoliday({
    required this.date,
    required this.name,
    this.isMinor = false,
  });
}

final _holidays5786 = <_JewishHoliday>[
  // Tishrei 5786
  _JewishHoliday(date: DateTime(2025, 9, 22), name: (s) => s.holidayRoshHashana),
  _JewishHoliday(date: DateTime(2025, 9, 23), name: (s) => s.holidayRoshHashana),
  _JewishHoliday(date: DateTime(2025, 10, 1), name: (s) => s.holidayYomKippur),
  _JewishHoliday(date: DateTime(2025, 10, 6), name: (s) => s.holidaySukkot),
  _JewishHoliday(date: DateTime(2025, 10, 7), name: (s) => s.holidaySukkot, isMinor: true),
  _JewishHoliday(date: DateTime(2025, 10, 12), name: (s) => '${s.holidaySukkot} — הושענא רבה', isMinor: true),
  _JewishHoliday(date: DateTime(2025, 10, 13), name: (s) => s.holidaySheminiAtzeret),
  _JewishHoliday(date: DateTime(2025, 10, 14), name: (s) => 'שמחת תורה'),
  // Hanukkah 5786
  _JewishHoliday(date: DateTime(2025, 12, 14), name: (s) => s.holidayHanukkah),
  _JewishHoliday(date: DateTime(2025, 12, 15), name: (s) => s.holidayHanukkah, isMinor: true),
  _JewishHoliday(date: DateTime(2025, 12, 16), name: (s) => s.holidayHanukkah, isMinor: true),
  _JewishHoliday(date: DateTime(2025, 12, 17), name: (s) => s.holidayHanukkah, isMinor: true),
  _JewishHoliday(date: DateTime(2025, 12, 18), name: (s) => s.holidayHanukkah, isMinor: true),
  _JewishHoliday(date: DateTime(2025, 12, 19), name: (s) => s.holidayHanukkah, isMinor: true),
  _JewishHoliday(date: DateTime(2025, 12, 20), name: (s) => s.holidayHanukkah, isMinor: true),
  _JewishHoliday(date: DateTime(2025, 12, 21), name: (s) => s.holidayHanukkah, isMinor: true),
  // Shvat / Adar
  _JewishHoliday(date: DateTime(2026, 1, 13), name: (s) => s.holidayTuBishvat, isMinor: true),
  _JewishHoliday(date: DateTime(2026, 2, 13), name: (s) => 'תענית אסתר', isMinor: true),
  _JewishHoliday(date: DateTime(2026, 3, 3), name: (s) => s.holidayPurim),
  _JewishHoliday(date: DateTime(2026, 3, 4), name: (s) => 'שושן פורים', isMinor: true),
  // Pesach
  _JewishHoliday(date: DateTime(2026, 4, 1), name: (s) => s.holidayPesach),
  _JewishHoliday(date: DateTime(2026, 4, 2), name: (s) => s.holidayPesach, isMinor: true),
  _JewishHoliday(date: DateTime(2026, 4, 7), name: (s) => '${s.holidayPesach} — חול המועד', isMinor: true),
  _JewishHoliday(date: DateTime(2026, 4, 8), name: (s) => '${s.holidayPesach} — שביעי של פסח'),
  // Yom HaZikaron + Yom HaAtzmaut
  _JewishHoliday(date: DateTime(2026, 4, 20), name: (s) => 'יום הזיכרון', isMinor: true),
  _JewishHoliday(date: DateTime(2026, 4, 21), name: (s) => s.holidayYomHaatzmaut, isMinor: true),
  // Lag BaOmer
  _JewishHoliday(date: DateTime(2026, 5, 5), name: (s) => s.holidayLagBaomer, isMinor: true),
  // Shavuot
  _JewishHoliday(date: DateTime(2026, 5, 20), name: (s) => s.holidayShavuot),
  _JewishHoliday(date: DateTime(2026, 5, 21), name: (s) => s.holidayShavuot, isMinor: true),
  // Tisha BeAv
  _JewishHoliday(date: DateTime(2026, 7, 22), name: (s) => 'יז בתמוז', isMinor: true),
  _JewishHoliday(date: DateTime(2026, 8, 12), name: (s) => s.holidayTishaBeav, isMinor: true),
];

// ─────────────────────────────────────────────────────────────
// Hebrew calendar conversion (Dershowitz-Reingold algorithm)
// ─────────────────────────────────────────────────────────────

class _HDate {
  final int day, month, year;
  const _HDate(this.day, this.month, this.year);

  // Nisan=1 ordering month names
  static const _names = [
    '', 'ניסן', 'אייר', 'סיוון', 'תמוז', 'אב', 'אלול',
    'תשרי', 'חשוון', 'כסלו', 'טבת', 'שבט', 'אדר', 'אדר ב׳',
  ];
  String get monthName => _names[month < _names.length ? month : 0];
}

int _toJDN(int y, int m, int d) {
  final a = (14 - m) ~/ 12;
  final yr = y + 4800 - a;
  final mo = m + 12 * a - 3;
  return d + (153 * mo + 2) ~/ 5 + 365 * yr + yr ~/ 4 - yr ~/ 100 + yr ~/ 400 - 32045;
}

bool _hLeap(int y) => (7 * y + 1) % 19 < 7;

int _hElapsedDays(int y) {
  final m = (235 * y - 234) ~/ 19;
  final p = 12084 + 13753 * m;
  var d = m * 29 + p ~/ 25920;
  if ((3 * (d + 1)) % 7 < 3) d++;
  return d;
}

int _hNewYear(int y) {
  const kEpoch = 347997;
  final d0 = _hElapsedDays(y - 1);
  final d1 = _hElapsedDays(y);
  final d2 = _hElapsedDays(y + 1);
  var jdn = kEpoch + d1;
  if (d2 - d1 == 356) jdn += 2;
  else if (d1 - d0 == 382) jdn++;
  return jdn;
}

int _hMonthDays(int m, int y) {
  final yLen = _hNewYear(y + 1) - _hNewYear(y);
  if (m == 2 || m == 4 || m == 6 || m == 10 || m == 13) return 29;
  if (m == 12) return _hLeap(y) ? 30 : 29;
  if (m == 8) return yLen % 10 == 5 ? 30 : 29; // Cheshvan
  if (m == 9) return yLen % 10 == 3 ? 29 : 30; // Kislev
  return 30;
}

_HDate _hFromJDN(int jdn) {
  var y = ((jdn - 347997) * 98496.0 / 35975351.0).floor() + 1;
  while (_hNewYear(y) <= jdn) y++;
  y--;
  final monthOrder = _hLeap(y)
      ? [7, 8, 9, 10, 11, 12, 13, 1, 2, 3, 4, 5, 6]
      : [7, 8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6];
  var jdnStart = _hNewYear(y);
  for (final m in monthOrder) {
    final mDays = _hMonthDays(m, y);
    if (jdn < jdnStart + mDays) return _HDate(jdn - jdnStart + 1, m, y);
    jdnStart += mDays;
  }
  return _HDate(1, 7, y + 1);
}

_HDate hebrewDate(DateTime date) =>
    _hFromJDN(_toJDN(date.year, date.month, date.day));

String _hDayLabel(int d) {
  const ones = ['', 'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט'];
  const tens = ['', 'י', 'כ', 'ל'];
  if (d == 15) return 'ט״ו';
  if (d == 16) return 'ט״ז';
  final t = d ~/ 10, o = d % 10;
  final letters = '${tens[t]}${ones[o]}';
  if (letters.isEmpty) return '';
  if (letters.length == 1) return '$letters׳';
  return '${letters.substring(0, letters.length - 1)}״${letters.substring(letters.length - 1)}';
}

String _hYearLabel(int y) {
  var n = y % 1000;
  const vals =  [400, 300, 200, 100, 90, 80, 70, 60, 50, 40, 30, 20, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1];
  const chars = ['ת',  'ש',  'ר',  'ק',  'צ', 'פ', 'ע', 'ס', 'נ', 'מ', 'ל', 'כ', 'י','ט','ח','ז','ו','ה','ד','ג','ב','א'];
  var s = '';
  for (var i = 0; i < vals.length; i++) {
    while (n >= vals[i]) { s += chars[i]; n -= vals[i]; }
  }
  if (s.isEmpty) return '';
  if (s.length == 1) return '$s׳';
  return '${s.substring(0, s.length - 1)}״${s.substring(s.length - 1)}';
}

// ─────────────────────────────────────────────────────────────
// Shabbat candle lighting times for Israel (approximate, 18 min before sunset)
String _candleLightingTime(DateTime friday) {
  final m = friday.month;
  if (m == 12 || m == 1)  return '16:20';
  if (m == 2)             return '17:00';
  if (m == 11)            return '16:40';
  if (m == 3 || m == 10) return '17:50';
  if (m == 4 || m == 9)  return '18:30';
  if (m == 5 || m == 8)  return '19:00';
  if (m == 6 || m == 7)  return '19:15';
  return '18:00';
}

String _havdalahTime(DateTime saturday) {
  final m = saturday.month;
  if (m == 12 || m == 1)  return '17:40';
  if (m == 2)             return '18:20';
  if (m == 11)            return '18:00';
  if (m == 3 || m == 10) return '19:10';
  if (m == 4 || m == 9)  return '19:50';
  if (m == 5 || m == 8)  return '20:20';
  if (m == 6 || m == 7)  return '20:35';
  return '19:20';
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isShabbatStart(DateTime day) => day.weekday == DateTime.friday;
  bool _isShabbatEnd(DateTime day)   => day.weekday == DateTime.saturday;

  void _prevMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final isHebrew     = appState.locale == AppLocale.hebrew;
    final shabbatOn    = appState.keepShabbat;
    final activeHolidays = shabbatOn ? _holidays5786 : const <_JewishHoliday>[];

    bool isHolidayFor(DateTime day) => activeHolidays.any((h) =>
        h.date.year == day.year &&
        h.date.month == day.month &&
        h.date.day == day.day);

    _JewishHoliday? getHolidayFor(DateTime day) {
      try {
        return activeHolidays.firstWhere((h) =>
            h.date.year == day.year &&
            h.date.month == day.month &&
            h.date.day == day.day);
      } catch (_) {
        return null;
      }
    }

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: s.calendarTitle),
            // Tab bar
            Expanded(
              child: (isHebrew && shabbatOn)
                  ? _HebrewCalendarTab(
                      focusedDay: _focusedDay,
                      selectedDay: _selectedDay,
                      holidays: activeHolidays,
                      onDaySelected: (d) => setState(() => _selectedDay = d),
                      onPrevMonth: _prevMonth,
                      onNextMonth: _nextMonth,
                      isHoliday: isHolidayFor,
                      getHoliday: getHolidayFor,
                      isSameDay: _isSameDay,
                      isShabbatStart: _isShabbatStart,
                      isShabbatEnd: _isShabbatEnd,
                      strings: s,
                    )
                  : _GregorianCalendarTab(
                      focusedDay: _focusedDay,
                      selectedDay: _selectedDay,
                      holidays: shabbatOn ? activeHolidays : const [],
                      onDaySelected: (d) => setState(() => _selectedDay = d),
                      onPrevMonth: _prevMonth,
                      onNextMonth: _nextMonth,
                      isHoliday: (_) => false,
                      getHoliday: (_) => null,
                      isSameDay: _isSameDay,
                      isShabbatStart: (_) => false,
                      isShabbatEnd: (_) => false,
                      strings: s,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hebrew calendar tab
// ─────────────────────────────────────────────────────────────
class _HebrewCalendarTab extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<_JewishHoliday> holidays;
  final void Function(DateTime) onDaySelected;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final bool Function(DateTime) isHoliday;
  final _JewishHoliday? Function(DateTime) getHoliday;
  final bool Function(DateTime, DateTime) isSameDay;
  final bool Function(DateTime) isShabbatStart;
  final bool Function(DateTime) isShabbatEnd;
  final S strings;

  const _HebrewCalendarTab({
    required this.focusedDay,
    required this.selectedDay,
    required this.holidays,
    required this.onDaySelected,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.isHoliday,
    required this.getHoliday,
    required this.isSameDay,
    required this.isShabbatStart,
    required this.isShabbatEnd,
    required this.strings,
  });

  // Accurate Hebrew month/year from mid-month of the focused Gregorian month
  String _hebrewMonthYear(DateTime dt) {
    final mid = DateTime(dt.year, dt.month, 15);
    final hd = hebrewDate(mid);
    return '${hd.monthName} ${_hYearLabel(hd.year)}';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Upcoming holidays (next 4 from today)
    final upcoming = holidays
        .where((h) => !h.date.isBefore(today))
        .take(4)
        .toList();

    // Next Shabbat start
    DateTime nextFriday = today;
    while (nextFriday.weekday != DateTime.friday) {
      nextFriday = nextFriday.add(const Duration(days: 1));
    }
    final nextSaturday = nextFriday.add(const Duration(days: 1));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          _CalendarGrid(
            focusedDay: focusedDay,
            selectedDay: selectedDay,
            onDaySelected: onDaySelected,
            onPrevMonth: onPrevMonth,
            onNextMonth: onNextMonth,
            isHoliday: isHoliday,
            getHoliday: getHoliday,
            isSameDay: isSameDay,
            isShabbatStart: isShabbatStart,
            isShabbatEnd: isShabbatEnd,
            monthLabel: _hebrewMonthYear(focusedDay),
            todayLabel: strings.calendarToday,
            shabbatCandlesLabel: strings.shabbatCandles,
            shabbatHavdalahLabel: strings.shabbatHavdalah,
            rtlDayLabels: true,
            showHebrewDates: true,
          ),
          const SizedBox(height: 16),

          // Next Shabbat card
          _ShabbatCard(
            friday: nextFriday,
            saturday: nextSaturday,
            candlesLabel: strings.shabbatCandles,
            havdalahLabel: strings.shabbatHavdalah,
          ),
          const SizedBox(height: 16),

          _HolidayList(
            title: strings.calendarHoliday,
            holidays: upcoming,
            strings: strings,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Gregorian calendar tab
// ─────────────────────────────────────────────────────────────
class _GregorianCalendarTab extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<_JewishHoliday> holidays;
  final void Function(DateTime) onDaySelected;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final bool Function(DateTime) isHoliday;
  final _JewishHoliday? Function(DateTime) getHoliday;
  final bool Function(DateTime, DateTime) isSameDay;
  final bool Function(DateTime) isShabbatStart;
  final bool Function(DateTime) isShabbatEnd;
  final S strings;

  const _GregorianCalendarTab({
    required this.focusedDay,
    required this.selectedDay,
    required this.holidays,
    required this.onDaySelected,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.isHoliday,
    required this.getHoliday,
    required this.isSameDay,
    required this.isShabbatStart,
    required this.isShabbatEnd,
    required this.strings,
  });

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final upcoming = holidays
        .where((h) => !h.date.isBefore(today))
        .take(4)
        .toList();

    final monthLabel =
        '${_monthNames[focusedDay.month - 1]} ${focusedDay.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          _CalendarGrid(
            focusedDay: focusedDay,
            selectedDay: selectedDay,
            onDaySelected: onDaySelected,
            onPrevMonth: onPrevMonth,
            onNextMonth: onNextMonth,
            isHoliday: isHoliday,
            getHoliday: getHoliday,
            isSameDay: isSameDay,
            isShabbatStart: isShabbatStart,
            isShabbatEnd: isShabbatEnd,
            monthLabel: monthLabel,
            todayLabel: strings.calendarToday,
            shabbatCandlesLabel: strings.shabbatCandles,
            shabbatHavdalahLabel: strings.shabbatHavdalah,
            rtlDayLabels: false,
          ),
          const SizedBox(height: 20),
          _HolidayList(
            title: strings.calendarHoliday,
            holidays: upcoming,
            strings: strings,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Calendar grid (shared by both tabs)
// ─────────────────────────────────────────────────────────────
class _CalendarGrid extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime) onDaySelected;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final bool Function(DateTime) isHoliday;
  final _JewishHoliday? Function(DateTime) getHoliday;
  final bool Function(DateTime, DateTime) isSameDay;
  final bool Function(DateTime) isShabbatStart;
  final bool Function(DateTime) isShabbatEnd;
  final String monthLabel;
  final String todayLabel;
  final String shabbatCandlesLabel;
  final String shabbatHavdalahLabel;
  final bool rtlDayLabels;
  final bool showHebrewDates;

  const _CalendarGrid({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.isHoliday,
    required this.getHoliday,
    required this.isSameDay,
    required this.isShabbatStart,
    required this.isShabbatEnd,
    required this.monthLabel,
    required this.todayLabel,
    required this.shabbatCandlesLabel,
    required this.shabbatHavdalahLabel,
    required this.rtlDayLabels,
    this.showHebrewDates = false,
  });

  List<DateTime?> _buildDays() {
    final firstDay = DateTime(focusedDay.year, focusedDay.month, 1);
    // weekday: 1=Mon..7=Sun → we want Sun=0
    int startOffset = (firstDay.weekday % 7);
    final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final days = <DateTime?>[];
    for (int i = 0; i < startOffset; i++) {
      days.add(null);
    }
    for (int d = 1; d <= lastDay.day; d++) {
      days.add(DateTime(focusedDay.year, focusedDay.month, d));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = _buildDays();
    final dayLabels = rtlDayLabels
        ? ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש']
        : ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.tText2(0.07)),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            children: [
              IconButton(
                onPressed: onPrevMonth,
                icon: Icon(Symbols.chevron_left, color: context.tText2(0.7)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.tText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: Icon(Symbols.chevron_right, color: context.tText2(0.7)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Day labels
          Row(
            children: dayLabels.map((d) {
              return Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.tText2(0.35),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),

          // Days grid
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: days.length + (7 - days.length % 7) % 7,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 0,
              childAspectRatio: showHebrewDates ? 0.72 : 1.0,
            ),
            itemBuilder: (ctx, i) {
              if (i >= days.length || days[i] == null) {
                return const SizedBox.shrink();
              }
              final day = days[i]!;
              final isToday = isSameDay(day, today);
              final isSelected =
                  selectedDay != null && isSameDay(day, selectedDay!);
              final holiday = getHoliday(day);
              final hasHoliday = holiday != null;
              final isFriday   = isShabbatStart(day);
              final isSaturday = isShabbatEnd(day);
              const shabbatFriColor  = Color(0xFFF5A623);
              const shabbatSatColor  = Color(0xFF9B8CF5);
              final hDate = showHebrewDates ? hebrewDate(day) : null;

              final dayColor = isSelected
                  ? context.tText
                  : hasHoliday
                      ? const Color(0xFFFFD700)
                      : isToday
                          ? AppColors.primary
                          : isFriday
                              ? shabbatFriColor
                              : isSaturday
                                  ? shabbatSatColor
                                  : context.tText2(0.8);

              return GestureDetector(
                onTap: () => onDaySelected(day),
                child: Container(
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : hasHoliday
                                ? const Color(0xFFFFD700).withValues(alpha: 0.1)
                                : isFriday
                                    ? shabbatFriColor.withValues(alpha: 0.08)
                                    : isSaturday
                                        ? shabbatSatColor.withValues(alpha: 0.08)
                                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5))
                        : hasHoliday && !isSelected
                            ? Border.all(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.4))
                            : (isFriday || isSaturday) && !isSelected
                                ? Border.all(
                                    color: (isFriday
                                            ? shabbatFriColor
                                            : shabbatSatColor)
                                        .withValues(alpha: 0.25))
                                : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color: dayColor,
                          fontSize: showHebrewDates ? 11 : 12,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (hDate != null)
                        Text(
                          _hDayLabel(hDate.day),
                          style: TextStyle(
                            color: isSelected
                                ? context.tText.withValues(alpha: 0.75)
                                : context.tText2(0.38),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                      if (hasHoliday)
                        Container(
                          width: 4, height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD700),
                            shape: BoxShape.circle,
                          ),
                        )
                      else if (isFriday)
                        const Text('🕯', style: TextStyle(fontSize: 6))
                      else if (isSaturday)
                        Container(
                          width: 4, height: 4,
                          decoration: BoxDecoration(
                            color: shabbatSatColor.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Selected day holiday / Shabbat banner
          if (selectedDay != null) ...[
            const SizedBox(height: 12),
            Builder(builder: (ctx) {
              final h = getHoliday(selectedDay!);
              if (h == null) {
                // Shabbat candle lighting (Friday)
                if (isShabbatStart(selectedDay!)) {
                  final timeStr = _candleLightingTime(selectedDay!);
                  return _SelectedDayBadge(
                    label: '$shabbatCandlesLabel  $timeStr',
                    color: const Color(0xFFF5A623),
                    icon: Symbols.local_fire_department,
                  );
                }
                // Havdalah (Saturday)
                if (isShabbatEnd(selectedDay!)) {
                  final timeStr = _havdalahTime(selectedDay!);
                  return _SelectedDayBadge(
                    label: '$shabbatHavdalahLabel  $timeStr',
                    color: const Color(0xFF9B8CF5),
                    icon: Symbols.nights_stay,
                  );
                }
                // Today badge
                if (isSameDay(selectedDay!, today)) {
                  return _SelectedDayBadge(
                    label: todayLabel,
                    color: AppColors.primary,
                    icon: Symbols.today,
                  );
                }
                return const SizedBox.shrink();
              }
              return _SelectedDayBadge(
                label: h.name(
                    context.select((AppState st) => st.strings)),
                color: const Color(0xFFFFD700),
                icon: Symbols.star,
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _SelectedDayBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SelectedDayBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shabbat card — shows next candle lighting + havdalah times
// ─────────────────────────────────────────────────────────────
class _ShabbatCard extends StatelessWidget {
  final DateTime friday;
  final DateTime saturday;
  final String candlesLabel;
  final String havdalahLabel;

  const _ShabbatCard({
    required this.friday,
    required this.saturday,
    required this.candlesLabel,
    required this.havdalahLabel,
  });

  @override
  Widget build(BuildContext context) {
    final candlesTime  = _candleLightingTime(friday);
    final havdalahTime = _havdalahTime(saturday);
    const friColor     = Color(0xFFF5A623);
    const satColor     = Color(0xFF9B8CF5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tText2(0.07)),
      ),
      child: Row(
        children: [
          // Candle lighting block
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: friColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: friColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('🕯', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        candlesLabel,
                        style: TextStyle(
                          color: friColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    candlesTime,
                    style: TextStyle(
                      color: context.tText,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${friday.day}/${friday.month}',
                    style: TextStyle(
                      color: context.tText2(0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Havdalah block
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: satColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: satColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Symbols.nights_stay, color: satColor, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        havdalahLabel,
                        style: TextStyle(
                          color: satColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    havdalahTime,
                    style: TextStyle(
                      color: context.tText,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${saturday.day}/${saturday.month}',
                    style: TextStyle(
                      color: context.tText2(0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Holiday list
// ─────────────────────────────────────────────────────────────
class _HolidayList extends StatelessWidget {
  final String title;
  final List<_JewishHoliday> holidays;
  final S strings;

  const _HolidayList({
    required this.title,
    required this.holidays,
    required this.strings,
  });

  static const _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    if (holidays.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: context.tText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ...holidays.map((h) {
          final d = h.date;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.tCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: h.isMinor
                    ? context.tText2(0.07)
                    : const Color(0xFFFFD700).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                // Date circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: h.isMinor
                        ? context.tText2(0.06)
                        : const Color(0xFFFFD700).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          color: h.isMinor
                              ? context.tText2(0.7)
                              : const Color(0xFFFFD700),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        _monthNames[d.month],
                        style: TextStyle(
                          color: h.isMinor
                              ? context.tText2(0.38)
                              : const Color(0xFFFFD700).withValues(alpha: 0.7),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.name(strings),
                        style: TextStyle(
                          color: h.isMinor ? context.tText2(0.7) : context.tText,
                          fontSize: 14,
                          fontWeight: h.isMinor
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.day}/${d.month}/${d.year}',
                        style: TextStyle(
                          color: context.tText2(0.3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!h.isMinor)
                  Icon(Symbols.star,
                      color: Color(0xFFFFD700), size: 16),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.tText2(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Symbols.chevron_right,
                  color: context.tText, size: 22),
            ),
          ),
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
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}
