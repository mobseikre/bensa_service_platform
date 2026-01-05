import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PromoCarouselWidget extends StatefulWidget {
  const PromoCarouselWidget({super.key});

  @override
  State<PromoCarouselWidget> createState() => _PromoCarouselWidgetState();
}

class _PromoCarouselWidgetState extends State<PromoCarouselWidget> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentIndex = 0;
  Timer? _timer;

  final List<Map<String, String>> _promoData = [
    {
      'image': 'assets/images/promo_plumber.png',
      'title': 'أعمال السباكة المتكاملة',
      'subtitle': 'حلول سريعة لجميع مشاكل تسرب المياه والصرف الصحي',
    },
    {
      'image': 'assets/images/promo_electrician.png',
      'title': 'فنيو كهرباء محترفون',
      'subtitle': 'تركيب وصيانة جميع التوصيلات والأنظمة الكهربائية',
    },
    {
      'image': 'assets/images/promo_painter.png',
      'title': 'خدمات الطلاء والترميم',
      'subtitle': 'لمسات احترافية تجدد جمال منزلك بأفضل الخامات',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        if (_currentIndex < _promoData.length - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
        }
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 18.h,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _promoData.length,
            itemBuilder: (context, index) {
              final promo = _promoData[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image
                      Image.asset(
                        promo['image']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: theme.colorScheme.surfaceVariant,
                          child:
                              const Icon(Icons.broken_image_rounded, size: 40),
                        ),
                      ),

                      // Gradient Overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Text Content
                      Positioned(
                        bottom: 1.5.h,
                        right: 4.w,
                        left: 4.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promo['title']!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                            Text(
                              promo['subtitle']!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 1.h),
        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_promoData.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: EdgeInsets.symmetric(horizontal: 0.5.w),
              height: 0.6.h,
              width: _currentIndex == index ? 5.w : 1.5.w,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }
}
