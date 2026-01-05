import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Modern animated service category card with simple clean design
class ServiceCategoryCardWidget extends StatefulWidget {
  final String name;
  final String iconName;
  final Color color;
  final bool isPopular;
  final VoidCallback onTap;

  const ServiceCategoryCardWidget({
    super.key,
    required this.name,
    required this.iconName,
    required this.color,
    required this.isPopular,
    required this.onTap,
  });

  @override
  State<ServiceCategoryCardWidget> createState() =>
      _ServiceCategoryCardWidgetState();
}

class _ServiceCategoryCardWidgetState extends State<ServiceCategoryCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconBounceAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _iconBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 25),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.reverse();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!mounted) return;
    setState(() => _isPressed = false);
    _controller.forward();
    HapticFeedback.lightImpact();

    // Add a small delay for animation to show feedback before navigating
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        widget.onTap();
      }
    });
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * (_isPressed ? 0.95 : 1.0),
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Decorative indicator (replaces selection radio)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name
                  Expanded(
                    child: Text(
                      widget.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        fontSize: 10.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Icon with bounce animation
                  Transform.translate(
                    offset: Offset(0, _iconBounceAnimation.value),
                    child: CustomIconWidget(
                      iconName: widget.iconName,
                      color: widget.color,
                      size: 34, // Enlarged as requested
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
