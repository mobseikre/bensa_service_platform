import 'package:flutter/material.dart';
import '../../../core/models/time_slot_model.dart';
import '../../../widgets/custom_icon_widget.dart';

class DateTimePickerSection extends StatelessWidget {
  final List<TimeSlotCandidate> selectedSlots;
  final Function(TimeSlotCandidate) onAddSlot;
  final Function(int) onRemoveSlot;

  const DateTimePickerSection({
    super.key,
    required this.selectedSlots,
    required this.onAddSlot,
    required this.onRemoveSlot,
  });

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TimeSlotPickerSheet(onAdd: onAddSlot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'الوقت المناسب للزيارة الأولى',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // List of selected slots
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: selectedSlots.length,
          itemBuilder: (context, index) {
            final slot = selectedSlots[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.formattedDate,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slot.formattedRange,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'delete',
                      color: theme.colorScheme.error,
                      size: 24,
                    ),
                    onPressed: () => onRemoveSlot(index),
                  ),
                ],
              ),
            );
          },
        ),

        // Add Slot Button
        InkWell(
          onTap: () => _showPicker(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  selectedSlots.isEmpty
                      ? 'اختر الوقت'
                      : 'إضافة فترة زمنية أخرى',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeSlotPickerSheet extends StatefulWidget {
  final Function(TimeSlotCandidate) onAdd;

  const _TimeSlotPickerSheet({required this.onAdd});

  @override
  State<_TimeSlotPickerSheet> createState() => _TimeSlotPickerSheetState();
}

class _TimeSlotPickerSheetState extends State<_TimeSlotPickerSheet> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _fromTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'الوقت المناسب للزيارة الأولى',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Date selection (Simplified for now - can use showDatePicker if needed)
          ListTile(
            title: const Text('اليوم'),
            trailing: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
          const Divider(),

          // Time Pickers
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('من'),
                    TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                            context: context, initialTime: _fromTime);
                        if (time != null) setState(() => _fromTime = time);
                      },
                      child: Text(
                        _formatTime(_fromTime),
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward),
              Expanded(
                child: Column(
                  children: [
                    const Text('إلى'),
                    TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                            context: context, initialTime: _toTime);
                        if (time != null) setState(() => _toTime = time);
                      },
                      child: Text(
                        _formatTime(_toTime),
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              widget.onAdd(TimeSlotCandidate(
                date: _selectedDate,
                from: _fromTime,
                to: _toTime,
              ));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('إضافة',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
