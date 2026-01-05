import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Job status stepper widget showing workflow progression
class JobStatusStepperWidget extends StatefulWidget {
  final String currentStatus;

  const JobStatusStepperWidget({
    super.key,
    required this.currentStatus,
  });

  @override
  State<JobStatusStepperWidget> createState() => _JobStatusStepperWidgetState();
}

class _JobStatusStepperWidgetState extends State<JobStatusStepperWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentStep();
    });
  }

  @override
  void didUpdateWidget(covariant JobStatusStepperWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus) {
      _scrollToCurrentStep();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentStep() {
    if (!_scrollController.hasClients) return;

    final steps = _getSteps();

    // Treat 'completed' as identical to 'work_done' for technician stepper
    final effectiveStatus = widget.currentStatus.toLowerCase() == 'completed'
        ? 'work_done'
        : widget.currentStatus.toLowerCase();

    final currentIndex = steps.indexWhere(
      (step) => (step['status'] as String).toLowerCase() == effectiveStatus,
    );

    if (currentIndex != -1) {
      // Calculation: Each step is 15.w (label width) + 8.w (connector width - now fixed)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          final scrollOffset =
              (currentIndex * 23.w) - (10.w); // Center it a bit
          _scrollController.animateTo(
            scrollOffset.clamp(0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  List<Map<String, dynamic>> _getSteps() {
    return [
      {'label': 'مقبول', 'status': 'assigned', 'icon': 'check_circle'},
      {'label': 'في الطريق', 'status': 'on_the_way', 'icon': 'directions_car'},
      {'label': 'وصلت', 'status': 'arrived', 'icon': 'location_on'},
      {'label': 'بدأ العمل', 'status': 'started', 'icon': 'build'},
      {'label': 'منتهي', 'status': 'work_done', 'icon': 'done_all'},
    ];
  }

  int _getCurrentStepIndex() {
    final steps = _getSteps();

    // Treat 'completed' as identical to 'work_done' for technician stepper
    final effectiveStatus = widget.currentStatus.toLowerCase() == 'completed'
        ? 'work_done'
        : widget.currentStatus.toLowerCase();

    final index = steps.indexWhere(
      (step) => (step['status'] as String).toLowerCase() == effectiveStatus,
    );
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _getSteps();
    final currentIndex = _getCurrentStepIndex();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حالة الطلب',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                steps.length * 2 - 1,
                (index) {
                  if (index.isOdd) {
                    final stepIndex = index ~/ 2;
                    final isCompleted = stepIndex < currentIndex;
                    return Container(
                      width:
                          8.w, // Fixed width instead of Expanded for scrolling
                      height: 2,
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    );
                  } else {
                    final stepIndex = index ~/ 2;
                    final step = steps[stepIndex];
                    final isCompleted = stepIndex < currentIndex;
                    final isCurrent = stepIndex == currentIndex;

                    return Column(
                      children: [
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted || isCurrent
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                            border: Border.all(
                              color: isCompleted || isCurrent
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: CustomIconWidget(
                              iconName: step['icon'] as String,
                              color: isCompleted || isCurrent
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        SizedBox(
                          width: 15.w,
                          child: Text(
                            step['label'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight:
                                  isCurrent ? FontWeight.w600 : FontWeight.w400,
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
