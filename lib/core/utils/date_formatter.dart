class DateFormatter {
  static const List<String> banglaDigits = [
    '০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'
  ];

  static const List<String> banglaMonths = [
    '',
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];

  static const List<String> banglaShortMonths = [
    '',
    'জানু',
    'ফেব্রু',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টে',
    'অক্টো',
    'নভে',
    'ডিসে',
  ];

  static const List<String> banglaWeekdays = [
    '',
    'সোমবার',
    'মঙ্গলবার',
    'বুধবার',
    'বৃহস্পতিবার',
    'শুক্রবার',
    'শনিবার',
    'রবিবার',
  ];

  static String toBanglaDigits(dynamic number) {
    return number.toString().split('').map((char) {
      final digit = int.tryParse(char);
      return digit != null ? banglaDigits[digit] : char;
    }).join();
  }

  static String formatTodayDate({DateTime? date}) {
    final d = date ?? DateTime.now();
    final now = DateTime.now();
    final isToday = d.year == now.year && d.month == now.month && d.day == now.day;

    final dayStr = toBanglaDigits(d.day);
    final monthStr = banglaMonths[d.month];
    final yearStr = toBanglaDigits(d.year);

    if (isToday) {
      return 'আজ, $dayStr $monthStr $yearStr';
    } else {
      return '$dayStr $monthStr $yearStr';
    }
  }

  static String formatFullDateWithDay({DateTime? date}) {
    final d = date ?? DateTime.now();
    final dayStr = toBanglaDigits(d.day);
    final monthStr = banglaMonths[d.month];
    final yearStr = toBanglaDigits(d.year);
    final weekdayStr = banglaWeekdays[d.weekday];

    return '$dayStr $monthStr $yearStr, $weekdayStr';
  }

  static String formatDateTime({DateTime? date}) {
    final d = date ?? DateTime.now();
    final dayStr = toBanglaDigits(d.day);
    final monthStr = banglaMonths[d.month];
    final yearStr = toBanglaDigits(d.year);
    final hour = d.hour;
    final period = hour >= 12 ? (hour >= 16 ? 'বিকাল' : 'দুপুর') : (hour >= 6 ? 'সকাল' : 'রাত');
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final hourStr = toBanglaDigits(displayHour);
    final minuteStr = toBanglaDigits(d.minute.toString().padLeft(2, '0'));

    return '$dayStr $monthStr $yearStr, $period $hourStr:$minuteStr';
  }

  /// Formats date string (e.g. "2026-10-22") to Bangla (e.g. "২২ অক্টোবর ২০২৬")
  static String formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'আজ';
    if (dateStr == 'আজ') return 'আজ';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null && month != null && day != null && month >= 1 && month <= 12) {
          final now = DateTime.now();
          final isToday = (year == now.year && month == now.month && day == now.day);
          final dayBn = toBanglaDigits(day);
          final monthBn = banglaMonths[month];
          final yearBn = toBanglaDigits(year);
          return isToday ? 'আজ, $dayBn $monthBn $yearBn' : '$dayBn $monthBn $yearBn';
        }
      }
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        return formatTodayDate(date: parsed);
      }
    } catch (_) {}
    return dateStr;
  }

  /// Formats date string to short Bangla (e.g. "২২ অক্টো")
  static String formatShortDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'আজ';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (month != null && day != null && month >= 1 && month <= 12) {
          final dayBn = toBanglaDigits(day);
          final monthBn = banglaShortMonths[month];
          return '$dayBn $monthBn';
        }
      }
    } catch (_) {}
    return dateStr;
  }

  /// Formats time string (e.g. "08:00:00", "22:00") into Bangla 12-hour period (e.g. "সকাল ৮:০০")
  static String formatSingleTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return '';
    final trimmed = timeStr.trim();
    if (trimmed.contains(RegExp(r'[\u0980-\u09FF]'))) {
      return trimmed;
    }
    try {
      final parts = trimmed.split(':');
      if (parts.isNotEmpty) {
        final hour = int.tryParse(parts[0]);
        final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
        if (hour != null) {
          final period = hour >= 5 && hour < 12
              ? 'সকাল'
              : (hour >= 12 && hour < 15
                  ? 'দুপুর'
                  : (hour >= 15 && hour < 18
                      ? 'বিকাল'
                      : (hour >= 18 && hour < 20 ? 'সন্ধ্যা' : 'রাত')));
          final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          final hourBn = toBanglaDigits(displayHour);
          final minBn = toBanglaDigits(minute.toString().padLeft(2, '0'));
          return '$period $hourBn:$minBn';
        }
      }
    } catch (_) {}
    return trimmed;
  }

  /// Formats time range into Bengali format: e.g. "সকাল ৮:০০ – রাত ১০:০০"
  static String formatTimeRange(String? startTime, String? endTime) {
    final startBn = formatSingleTime(startTime);
    final endBn = formatSingleTime(endTime);

    if (startBn.isNotEmpty && endBn.isNotEmpty) {
      return '$startBn – $endBn';
    } else if (startBn.isNotEmpty) {
      return startBn;
    } else if (endBn.isNotEmpty) {
      return 'শেষ: $endBn';
    }
    return 'সারাদিন';
  }

  /// Converts an ISO 8601 or DateTime string to Bangla 12-hour format: e.g. "সকাল ৯:১৫", "সকাল ১০:৪৫"
  static String formatDateTimeToBanglaTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.trim().isEmpty) return '';
    final trimmed = dateTimeStr.trim();
    if (trimmed.contains(RegExp(r'[\u0980-\u09FF]'))) {
      return trimmed;
    }
    try {
      final dt = DateTime.parse(trimmed).toLocal();
      final hour = dt.hour;
      final minute = dt.minute;
      final period = hour >= 5 && hour < 12
          ? 'সকাল'
          : (hour >= 12 && hour < 15
              ? 'দুপুর'
              : (hour >= 15 && hour < 18
                  ? 'বিকাল'
                  : (hour >= 18 && hour < 20 ? 'সন্ধ্যা' : 'রাত')));
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final hourBn = toBanglaDigits(displayHour);
      final minBn = toBanglaDigits(minute.toString().padLeft(2, '0'));
      return '$period $hourBn:$minBn';
    } catch (_) {}
    return formatSingleTime(trimmed);
  }
}
