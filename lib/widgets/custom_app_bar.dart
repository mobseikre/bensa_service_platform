import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App bar style variants for different contexts
enum CustomAppBarStyle {
  /// Standard app bar with title and actions
  standard,

  /// Minimal app bar with back button only
  minimal,

  /// Search-focused app bar with search field
  search,

  /// Profile app bar with avatar and settings
  profile,
}

/// Custom app bar widget for service marketplace
/// Implements clean, authoritative interface with clear visual hierarchy
/// Optimized for Arabic language and RTL support
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text to display
  final String? title;

  /// Leading widget (typically back button or menu)
  final Widget? leading;

  /// Action widgets displayed on the right
  final List<Widget>? actions;

  /// Style variant of the app bar
  final CustomAppBarStyle style;

  /// Whether to show back button automatically
  final bool automaticallyImplyLeading;

  /// Background color override
  final Color? backgroundColor;

  /// Foreground color override (text and icons)
  final Color? foregroundColor;

  /// Elevation of the app bar
  final double elevation;

  /// Whether to center the title
  final bool centerTitle;

  /// Custom title widget
  final Widget? titleWidget;

  /// Bottom widget (typically TabBar)
  final PreferredSizeWidget? bottom;

  /// Callback when back button is pressed
  final VoidCallback? onBackPressed;

  /// Search controller for search style
  final TextEditingController? searchController;

  /// Search hint text
  final String? searchHint;

  /// Search callback
  final ValueChanged<String>? onSearchChanged;

  /// Profile image URL for profile style
  final String? profileImageUrl;

  /// Notification badge count
  final int? notificationCount;

  /// Width of leading widget
  final double? leadingWidth;

  const CustomAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.style = CustomAppBarStyle.standard,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.centerTitle = true,
    this.titleWidget,
    this.bottom,
    this.onBackPressed,
    this.searchController,
    this.searchHint,
    this.onSearchChanged,
    this.profileImageUrl,
    this.notificationCount,
    this.leadingWidth,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = backgroundColor ??
        (theme.brightness == Brightness.light
            ? colorScheme.surface
            : colorScheme.surface);

    final fgColor = foregroundColor ??
        (theme.brightness == Brightness.light
            ? const Color(0xFF111827)
            : const Color(0xFFF9FAFB));

    switch (style) {
      case CustomAppBarStyle.search:
        return _buildSearchAppBar(context, bgColor, fgColor);
      case CustomAppBarStyle.profile:
        return _buildProfileAppBar(context, bgColor, fgColor);
      case CustomAppBarStyle.minimal:
        return _buildMinimalAppBar(context, bgColor, fgColor);
      case CustomAppBarStyle.standard:
        return _buildStandardAppBar(context, bgColor, fgColor);
    }
  }

  Widget _buildStandardAppBar(
    BuildContext context,
    Color bgColor,
    Color fgColor,
  ) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading ?? _buildLeading(context, fgColor),
      leadingWidth: leadingWidth,
      title: titleWidget ?? _buildTitle(context, fgColor),
      actions: actions ?? _buildActions(context, fgColor),
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }

  Widget _buildMinimalAppBar(
    BuildContext context,
    Color bgColor,
    Color fgColor,
  ) {
    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading ?? _buildLeading(context, fgColor),
      leadingWidth: leadingWidth,
      title: const SizedBox.shrink(),
      actions: actions,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Theme.of(context).brightness == Brightness.light
                ? Brightness.dark
                : Brightness.light,
      ),
    );
  }

  Widget _buildSearchAppBar(
    BuildContext context,
    Color bgColor,
    Color fgColor,
  ) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation,
      automaticallyImplyLeading: false,
      leading: leading ?? _buildLeading(context, fgColor),
      leadingWidth: leadingWidth,
      title: Container(
        height: 44,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light
              ? const Color(0xFFF9FAFB)
              : const Color(0xFF374151),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.brightness == Brightness.light
                ? const Color(0xFFE5E7EB)
                : const Color(0xFF4B5563),
            width: 1,
          ),
        ),
        child: TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: theme.textTheme.bodyMedium?.copyWith(color: fgColor),
          decoration: InputDecoration(
            hintText: searchHint ?? 'بحث...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.light
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: theme.brightness == Brightness.light
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF9CA3AF),
              size: 20,
            ),
            suffixIcon: searchController?.text.isNotEmpty ?? false
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    onPressed: () {
                      searchController?.clear();
                      onSearchChanged?.call('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
      actions: actions,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Theme.of(context).brightness == Brightness.light
                ? Brightness.dark
                : Brightness.light,
      ),
    );
  }

  Widget _buildProfileAppBar(
    BuildContext context,
    Color bgColor,
    Color fgColor,
  ) {
    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation,
      automaticallyImplyLeading: false,
      leadingWidth: leadingWidth,
      leading: profileImageUrl != null
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                backgroundImage: NetworkImage(profileImageUrl!),
              ),
            )
          : null,
      title: titleWidget ?? _buildTitle(context, fgColor),
      actions: [
        if (notificationCount != null && notificationCount! > 0)
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Handle notification tap
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    notificationCount! > 99 ? '99+' : '$notificationCount',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            Navigator.pushNamed(context, '/profile-screen');
          },
        ),
        const SizedBox(width: 8),
      ],
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Theme.of(context).brightness == Brightness.light
                ? Brightness.dark
                : Brightness.light,
      ),
    );
  }

  Widget? _buildLeading(BuildContext context, Color fgColor) {
    if (!automaticallyImplyLeading) return null;

    final canPop = Navigator.of(context).canPop();
    if (!canPop) return null;

    return IconButton(
      icon: const Icon(Icons.arrow_back),
      color: fgColor,
      onPressed: () {
        HapticFeedback.lightImpact();
        if (onBackPressed != null) {
          onBackPressed!();
        } else {
          Navigator.of(context).pop();
        }
      },
    );
  }

  Widget? _buildTitle(BuildContext context, Color fgColor) {
    if (title == null) return null;

    return Text(
      title!,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  List<Widget>? _buildActions(BuildContext context, Color fgColor) {
    if (actions != null) return actions;
    return null;
  }
}

/// Pre-configured app bar for customer screens
class CustomerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const CustomerAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: title,
      style: CustomAppBarStyle.standard,
      actions: actions,
      onBackPressed: onBackPressed,
    );
  }
}

/// Pre-configured app bar for technician screens
class TechnicianAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final int? notificationCount;

  const TechnicianAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.notificationCount,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: title,
      style: CustomAppBarStyle.standard,
      automaticallyImplyLeading: false, // إزالة زر الرجوع من صفحات الفني
      actions: actions ??
          [
            if (notificationCount != null && notificationCount! > 0)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications-screen');
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        notificationCount! > 99 ? '99+' : '$notificationCount',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
          ],
      onBackPressed: onBackPressed,
    );
  }
}
