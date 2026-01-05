import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Rating and review section for completed requests
class RatingSectionWidget extends StatefulWidget {
  final int requestId;
  final Function(int rating, String comment) onSubmitRating;

  const RatingSectionWidget({
    super.key,
    required this.requestId,
    required this.onSubmitRating,
  });

  @override
  State<RatingSectionWidget> createState() => _RatingSectionWidgetState();
}

class _RatingSectionWidgetState extends State<RatingSectionWidget> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
            'تقييم الخدمة',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: CustomIconWidget(
                      iconName: index < _rating ? 'star' : 'star_border',
                      color: const Color(0xFFF59E0B),
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'اكتب تعليقك هنا...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_rating > 0 && !_isSubmitting) ? _submitRating : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Text('إرسال التقييم'),
            ),
          ),
        ],
      ),
    );
  }

  void _submitRating() {
    if (_rating == 0) return;
    setState(() => _isSubmitting = true);
    widget.onSubmitRating(_rating, _commentController.text);
  }
}
