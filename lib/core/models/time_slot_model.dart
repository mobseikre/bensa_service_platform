import 'package:flutter/material.dart';

class TimeSlotCandidate {
  final DateTime date;
  final TimeOfDay from;
  final TimeOfDay to;

  TimeSlotCandidate({
    required this.date,
    required this.from,
    required this.to,
  });

  String get formattedDate {
    // Basic formatting for Arabic
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String get formattedRange => '${formatTime(from)} إلى ${formatTime(to)}';
}
