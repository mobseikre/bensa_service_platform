import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Skeleton loading widget for initial data fetch
class SkeletonLoadingWidget extends StatefulWidget {
  const SkeletonLoadingWidget({super.key});

  @override
  State<SkeletonLoadingWidget> createState() => _SkeletonLoadingWidgetState();
}

class _SkeletonLoadingWidgetState extends State<SkeletonLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      itemCount: 5,
      itemBuilder: (context, index) {
        return FadeTransition(
          opacity: _animation,
          child: Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFF374151),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60.w,
                            height: 2.h,
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.light
                                  ? const Color(0xFFE5E7EB)
                                  : const Color(0xFF374151),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Container(
                            width: 30.w,
                            height: 1.5.h,
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.light
                                  ? const Color(0xFFE5E7EB)
                                  : const Color(0xFF374151),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 20.w,
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFF374151),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
