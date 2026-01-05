import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Service information card with category, description, and photos
class ServiceInfoCardWidget extends StatelessWidget {
  final Map<String, dynamic> requestData;

  const ServiceInfoCardWidget({
    super.key,
    required this.requestData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos = (requestData['photos'] as List?) ?? [];

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
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: _getCategoryIcon(
                        requestData['category'] as String? ?? ''),
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requestData['category'] as String? ?? 'خدمة عامة',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDateTime(requestData['created_at'] as String?),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: _getPriorityColor(
                          requestData['priority'] as String? ?? 'normal')
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPriorityLabel(
                      requestData['priority'] as String? ?? 'normal'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getPriorityColor(
                        requestData['priority'] as String? ?? 'normal'),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'الوصف',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            requestData['description'] as String? ?? 'لا يوجد وصف',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (photos.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              'الصور المرفقة',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            SizedBox(
              height: 20.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index] as Map<String, dynamic>;
                  return GestureDetector(
                    onTap: () => _showPhotoGallery(context, photos, index),
                    child: Container(
                      width: 30.w,
                      margin: EdgeInsets.only(left: 2.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomImageWidget(
                          imageUrl: photo['url'] as String,
                          width: 30.w,
                          height: 20.h,
                          fit: BoxFit.cover,
                          semanticLabel: photo['semanticLabel'] as String? ??
                              'صورة الخدمة',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'سباكة':
        return 'plumbing';
      case 'كهرباء':
        return 'electrical_services';
      case 'نجارة':
        return 'carpenter';
      case 'تكييف':
        return 'ac_unit';
      default:
        return 'home_repair_service';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 'عاجل';
      case 'high':
        return 'عالي';
      default:
        return 'عادي';
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  void _showPhotoGallery(BuildContext context, List photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PhotoGalleryScreen(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _PhotoGalleryScreen extends StatefulWidget {
  final List photos;
  final int initialIndex;

  const _PhotoGalleryScreen({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<_PhotoGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final photo = widget.photos[index] as Map<String, dynamic>;
          return Center(
            child: CustomImageWidget(
              imageUrl: photo['url'] as String,
              width: 100.w,
              height: 80.h,
              fit: BoxFit.contain,
              semanticLabel: photo['semanticLabel'] as String? ?? 'صورة الخدمة',
            ),
          );
        },
      ),
    );
  }
}
