import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Status progress indicator showing workflow stages
class StatusProgressWidget extends StatefulWidget {
  final String currentStatus;

  const StatusProgressWidget({
    super.key,
    required this.currentStatus,
  });

  @override
  State<StatusProgressWidget> createState() => _StatusProgressWidgetState();
}

class _StatusProgressWidgetState extends State<StatusProgressWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentStatus();
    });
  }

  @override
  void didUpdateWidget(covariant StatusProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus) {
      _scrollToCurrentStatus();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentStatus() {
    if (!_scrollController.hasClients) return;

    final List<Map<String, dynamic>> stages = [
      {'key': 'pending'},
      {'key': 'assigned'},
      {'key': 'on_the_way'},
      {'key': 'arrived'},
      {'key': 'started'},
      {'key': 'work_done'},
      {'key': 'completed'},
    ];

    final currentIndex =
        stages.indexWhere((s) => s['key'] == widget.currentStatus);

    if (currentIndex != -1) {
      // Each item (Column + Connector) is approximately 28.w (20.w for label container + 8.w for connector)
      // We use a small delay to ensure layout is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          final scrollOffset =
              (currentIndex * 28.w) - (10.w); // Center it a bit
          _scrollController.animateTo(
            scrollOffset.clamp(0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Map<String, dynamic>> stages = [
      {'key': 'pending', 'label': 'قيد الانتظار', 'icon': 'hourglass_empty'},
      {'key': 'assigned', 'label': 'تم التعيين', 'icon': 'person_add'},
      {'key': 'on_the_way', 'label': 'في الطريق', 'icon': 'directions_car'},
      {'key': 'arrived', 'label': 'وصل', 'icon': 'location_on'},
      {'key': 'started', 'label': 'بدأ العمل', 'icon': 'build'},
      {'key': 'work_done', 'label': 'انتهى العمل', 'icon': 'check_circle'},
      {'key': 'completed', 'label': 'مكتمل', 'icon': 'done_all'},
    ];

    final currentIndex =
        stages.indexWhere((s) => s['key'] == widget.currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 16.h, // Increased from 14.h to accommodate scaling and glow
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none, // Allow glow/scale to overflow container
            itemCount: stages.length,
            padding: EdgeInsets.symmetric(
                horizontal: 4.w, vertical: 1.h), // Added vertical padding
            itemBuilder: (context, index) {
              final stage = stages[index];
              final isActive = index <= currentIndex;
              final isCurrent = index == currentIndex;

              final nextStepIsActive = index < currentIndex;

              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildStepIcon(
                          context, stage, isActive, isCurrent, theme),
                      SizedBox(height: 1.5.h), // Slightly more spacing
                      SizedBox(
                        width: 25.w,
                        child: Text(
                          stage['label'] as String,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isCurrent
                                ? theme.colorScheme.primary
                                : isActive
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.8) // Subtler for done steps
                                    : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.w500,
                            fontSize: 10.sp,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (index < stages.length - 1)
                    Container(
                      width: 8.w,
                      height: 2,
                      margin: EdgeInsets.only(
                          top: 6.w + 1.h), // Adjusted margin for line
                      decoration: BoxDecoration(
                        color: nextStepIsActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStepIcon(BuildContext context, Map<String, dynamic> stage,
      bool isActive, bool isCurrent, ThemeData theme) {
    Widget icon = Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: isActive ? theme.colorScheme.primary : theme.colorScheme.surface,
        shape: BoxShape.circle,
        border: isActive
            ? null
            : Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 1.5),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: stage['icon'] as String,
          color: isActive
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          size: 22,
        ),
      ),
    );

    if (isCurrent) {
      return icon
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(duration: 2.seconds, color: Colors.white24)
          .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 1.seconds,
              curve: Curves.easeInOut)
          .then()
          .scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(1, 1),
              duration: 1.seconds,
              curve: Curves.easeInOut);
    }

    return icon;
  }
}
