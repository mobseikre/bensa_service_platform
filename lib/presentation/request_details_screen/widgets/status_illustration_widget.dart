import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatusIllustrationWidget extends StatelessWidget {
  final String status;

  const StatusIllustrationWidget({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Container(
      width: double.infinity,
      height: 28.h, // Slightly taller for more impact
      margin: EdgeInsets.symmetric(vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.transparent, // Fully transparent to blend
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background patterns/glow - moved and enlarged for better blending
          Positioned(
            top: 0,
            child: _buildBackground(primaryColor),
          ),

          // Dynamic Scene
          Center(
            child: _buildScene(status, primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
        begin: const Offset(1, 1),
        end: const Offset(1.2, 1.2),
        duration: 2.seconds);
  }

  Widget _buildScene(String status, Color color) {
    switch (status) {
      case 'pending':
        return _PendingScene(color: color);
      case 'assigned':
      case 'on_the_way':
        return _TravelingScene(color: color);
      case 'arrived':
        return _ArrivedScene(color: color);
      case 'started':
        return _WorkingScene(color: color);
      case 'work_done':
      case 'completed':
        return _CompletedScene(color: color);
      case 'cancelled':
        return _CancelledScene(color: color);
      default:
        return _PendingScene(color: color);
    }
  }
}

class _PendingScene extends StatelessWidget {
  final Color color;
  const _PendingScene({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Radar waves
        ...List.generate(3, (index) {
          return Container(
            width: 15.h,
            height: 15.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                  begin: Offset.zero,
                  end: const Offset(1.5, 1.5),
                  duration: 2.seconds,
                  delay: (index * 600).ms)
              .fadeOut(duration: 2.seconds);
        }),
        Icon(Icons.person_search_rounded, size: 8.h, color: color)
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 800.ms),
      ],
    );
  }
}

class _TravelingScene extends StatelessWidget {
  final Color color;
  const _TravelingScene({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.moped_rounded, size: 9.h, color: color)
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveY(begin: -5, end: 5, duration: 600.ms, curve: Curves.easeInOut)
            .slideX(begin: -0.1, end: 0.1, duration: 1.seconds),
        SizedBox(height: 1.h),
        // Dashed road animation
        Container(
          width: 20.h,
          height: 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
                10,
                (index) => Container(
                        width: 10,
                        height: 2,
                        color: color.withValues(alpha: 0.3))
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeOut(duration: 500.ms, delay: (index * 100).ms)),
          ),
        ),
      ],
    );
  }
}

class _ArrivedScene extends StatelessWidget {
  final Color color;
  const _ArrivedScene({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Icon(Icons.location_on_rounded, size: 10.h, color: color)
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 0.9),
                duration: 500.ms,
                curve: Curves.elasticOut),
        Container(
          width: 4.h,
          height: 1.h,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scaleX(begin: 1, end: 1.5, duration: 500.ms),
      ],
    );
  }
}

class _WorkingScene extends StatelessWidget {
  final Color color;
  const _WorkingScene({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.settings_rounded, size: 8.h, color: color)
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 3.seconds),
        Icon(Icons.build_rounded, size: 6.h, color: Colors.blueGrey)
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveY(begin: -10, end: 10, duration: 1.seconds)
            .rotate(begin: -0.2, end: 0.2, duration: 1.seconds),
      ],
    );
  }
}

class _CompletedScene extends StatelessWidget {
  final Color color;
  const _CompletedScene({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Sparkles
        ...List.generate(8, (index) {
          final angle = (index * 45) * math.pi / 180;
          return Transform.translate(
            offset: Offset(40 * math.cos(angle), 40 * math.sin(angle)),
            child: Container(width: 4, height: 4, color: Colors.amber),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                  begin: Offset.zero,
                  end: const Offset(1.5, 1.5),
                  duration: 1.seconds,
                  delay: (index * 100).ms)
              .fadeOut();
        }),
        Icon(Icons.check_circle_rounded, size: 12.h, color: Colors.green)
            .animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack)
            .shimmer(duration: 2.seconds),
      ],
    );
  }
}

class _CancelledScene extends StatelessWidget {
  final Color color;
  const _CancelledScene({required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.cancel_rounded, size: 10.h, color: Colors.redAccent)
        .animate()
        .shake(duration: 500.ms)
        .scale(
            begin: const Offset(1.2, 1.2),
            end: const Offset(1, 1),
            duration: 300.ms);
  }
}
