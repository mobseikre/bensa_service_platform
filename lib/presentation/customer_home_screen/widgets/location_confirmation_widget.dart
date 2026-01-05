import 'package:flutter/material.dart';

class LocationConfirmationWidget extends StatelessWidget {
  final String addressLabel;
  final VoidCallback onConfirm;
  final VoidCallback onChange;

  const LocationConfirmationWidget({
    super.key,
    required this.addressLabel,
    required this.onConfirm,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),

          // Large Location Icon in a soft squircle container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(44),
            ),
            child: Center(
              child: Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 80, // Much larger icon
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Question Text
          Text(
            'هل أنت في \'$addressLabel\'؟',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontSize: 24, // Slightly larger and bold
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'هذا هو موقعك المحدد حالياً.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Confirm Button (Identity Color)
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: const Text(
                'نعم، أنا هنا',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Change Button
          SizedBox(
            width: double.infinity,
            height: 58,
            child: TextButton(
              onPressed: onChange,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'تغيير العنوان',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
