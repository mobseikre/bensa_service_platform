import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navigation item configuration for bottom bar
class CustomBottomBarItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String route;
  final int? badgeCount;

  const CustomBottomBarItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.route,
    this.badgeCount,
  });
}

/// Bottom navigation bar style variants
enum CustomBottomBarStyle {
  /// Standard bottom bar with labels always visible
  standard,

  /// Floating bottom bar with rounded corners (24px) and elevation
  floating,

  /// Minimal bottom bar with icons only, labels on selection
  minimal,
}

/// Custom bottom navigation bar widget for service marketplace
/// Implements bottom-heavy interaction design with thumb-friendly zones
/// Supports role-specific navigation for customers and technicians
class CustomBottomBar extends StatefulWidget {
  /// List of navigation items to display
  final List<CustomBottomBarItem> items;

  /// Currently selected index
  final int currentIndex;

  /// Callback when navigation item is tapped
  final ValueChanged<int> onTap;

  /// Style variant of the bottom bar
  final CustomBottomBarStyle style;

  /// Whether to show labels for all items
  final bool showLabels;

  /// Whether to enable haptic feedback on tap
  final bool enableHapticFeedback;

  /// Background color override
  final Color? backgroundColor;

  /// Selected item color override
  final Color? selectedItemColor;

  /// Unselected item color override
  final Color? unselectedItemColor;

  /// Elevation of the bottom bar
  final double elevation;

  /// Height of the bottom bar
  final double height;

  const CustomBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.style = CustomBottomBarStyle.floating,
    this.showLabels = true,
    this.enableHapticFeedback = true,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 8.0,
    this.height = 72.0,
  }) : assert(items.length >= 2 && items.length <= 5,
            'Bottom bar must have between 2 and 5 items');

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimations = List.generate(
      widget.items.length,
      (index) => Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    // Trigger scale animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final backgroundColor = widget.backgroundColor ??
        Colors.white; // Force white to match phone frame

    final selectedColor = widget.selectedItemColor ?? colorScheme.primary;
    final unselectedColor = widget.unselectedItemColor ??
        (theme.brightness == Brightness.light
            ? const Color(0xFF6B7280)
            : const Color(0xFF9CA3AF));

    Widget bottomBar = Container(
      height: widget.height +
          bottomPadding +
          20, // Add 20px extra to prevent overflow
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            blurRadius: widget.elevation * 2,
            offset: Offset(0, -widget.elevation / 2),
          ),
        ],
        borderRadius: widget.style == CustomBottomBarStyle.floating
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(
            bottom: bottomPadding + 20), // Add 20px extra padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            widget.items.length,
            (index) => _buildNavigationItem(
              context,
              widget.items[index],
              index,
              selectedColor,
              unselectedColor,
            ),
          ),
        ),
      ),
    );

    if (widget.style == CustomBottomBarStyle.floating) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 5, // Add small bottom padding to prevent overflow
        ),
        child: bottomBar,
      );
    }

    return bottomBar;
  }

  Widget _buildNavigationItem(
    BuildContext context,
    CustomBottomBarItem item,
    int index,
    Color selectedColor,
    Color unselectedColor,
  ) {
    final isSelected = widget.currentIndex == index;
    final theme = Theme.of(context);

    return Expanded(
      child: AnimatedBuilder(
        animation: _scaleAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: widget.currentIndex == index
                ? _scaleAnimations[index].value
                : 1.0,
            child: child,
          );
        },
        child: InkWell(
          onTap: () => _handleTap(index),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 6), // Reduced from 8 to 6
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.all(6), // Reduced from 8 to 6
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColor.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSelected && item.activeIcon != null
                            ? item.activeIcon
                            : item.icon,
                        color: isSelected ? selectedColor : unselectedColor,
                        size: 22, // Reduced from 24 to 22
                      ),
                    ),
                    if (item.badgeCount != null && item.badgeCount! > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444), // Danger color
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            item.badgeCount! > 99
                                ? '99+'
                                : '${item.badgeCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
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
                if (widget.showLabels ||
                    (widget.style == CustomBottomBarStyle.minimal &&
                        isSelected))
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1.0 : 0.7,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 2), // Reduced from 4 to 2
                      child: Text(
                        item.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSelected ? selectedColor : unselectedColor,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 11, // Reduced from 12 to 11
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pre-configured bottom bar for customer role
class CustomerBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final CustomBottomBarStyle style;

  const CustomerBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.style = CustomBottomBarStyle.floating,
  });

  static final List<CustomBottomBarItem> _customerItems = [
    const CustomBottomBarItem(
      label: 'الرئيسية',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      route: '/customer-home-screen',
    ),
    const CustomBottomBarItem(
      label: 'الطلبات',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      route: '/my-requests-screen',
    ),
    const CustomBottomBarItem(
      label: 'المزيد',
      icon: Icons.widgets_outlined,
      activeIcon: Icons.widgets,
      route: '/profile-screen',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomBottomBar(
      items: _customerItems,
      currentIndex: currentIndex,
      onTap: (index) {
        // Call the parent onTap first (allows parent to prevent navigation)
        onTap(index);
        // Get user data from current route arguments to pass along
        final args = ModalRoute.of(context)?.settings.arguments;
        // Only navigate if not already on the target route
        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (currentRoute != _customerItems[index].route) {
          Navigator.pushNamed(
            context,
            _customerItems[index].route,
            arguments: args, // Pass along existing arguments
          );
        }
      },
      style: style,
    );
  }
}

/// Pre-configured bottom bar for technician role
class TechnicianBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final CustomBottomBarStyle style;
  final int? availableJobsCount;

  const TechnicianBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.style = CustomBottomBarStyle.floating,
    this.availableJobsCount,
  });

  @override
  Widget build(BuildContext context) {
    final List<CustomBottomBarItem> technicianItems = [
      const CustomBottomBarItem(
        label: 'الرئيسية',
        icon: Icons.work_outline,
        activeIcon: Icons.work,
        route: '/technician-home-screen',
      ),
      CustomBottomBarItem(
        label: 'الوظائف',
        icon: Icons.list_alt_outlined,
        activeIcon: Icons.list_alt,
        route: '/technician-jobs-screen',
        badgeCount: availableJobsCount,
      ),
      const CustomBottomBarItem(
        label: 'العهدة',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        route: '/earnings-screen',
      ),
      const CustomBottomBarItem(
        label: 'الملف الشخصي',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        route: '/profile-screen',
      ),
    ];

    return CustomBottomBar(
      items: technicianItems,
      currentIndex: currentIndex,
      onTap: (index) {
        // Call the parent onTap first
        onTap(index);

        // Only navigate if not already on the current route and not the home tab
        final currentRoute = ModalRoute.of(context)?.settings.name;
        final targetRoute = technicianItems[index].route;

        if (currentRoute != targetRoute) {
          // For technician home screen, use pushReplacementNamed to prevent back button
          if (targetRoute == '/technician-home-screen') {
            Navigator.pushReplacementNamed(context, targetRoute);
          } else {
            Navigator.pushNamed(context, targetRoute);
          }
        }
      },
      style: style,
    );
  }
}
