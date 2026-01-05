import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Greeting header widget displaying user name
class GreetingHeaderWidget extends StatelessWidget {
  final String userName;
  final String currentLocation;

  const GreetingHeaderWidget({
    super.key,
    required this.userName,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0),
      child: Text(
        'مرحبا، $userName 👋',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
          fontSize: 18.sp,
        ),
      ),
    );
  }
}
