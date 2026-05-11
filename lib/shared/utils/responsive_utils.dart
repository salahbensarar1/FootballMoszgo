import 'package:flutter/material.dart';

/// Comprehensive responsive design utility for consistent UI across all devices
class ResponsiveUtils {
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;
  static const double _desktopBreakpoint = 1200;

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _mobileBreakpoint && width < _desktopBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= _desktopBreakpoint;
  }

  /// Get responsive columns for grid layouts
  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  /// Get responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32);
    } else {
      return const EdgeInsets.symmetric(horizontal: 48);
    }
  }

  /// Get responsive padding with custom values
  static EdgeInsets getPadding(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? factor,
  }) {
    // Use specific values if provided
    double padding;
    if (isDesktop(context) && desktop != null) {
      padding = desktop;
    } else if (isTablet(context) && tablet != null) {
      padding = tablet;
    } else if (isMobile(context) && mobile != null) {
      padding = mobile;
    } else {
      // Fallback to factor-based padding
      final basePadding = isMobile(context) ? 16.0 : 24.0;
      final multiplier = factor ?? 1.0;
      padding = basePadding * multiplier;
    }

    return EdgeInsets.all(padding);
  }

  /// Get responsive font size for titles
  static double getTitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 24;
    } else if (isTablet(context)) {
      return 28;
    } else {
      return 32;
    }
  }

  /// Get responsive font size for body text
  static double getBodyFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 16;
    } else if (isTablet(context)) {
      return 18;
    } else {
      return 20;
    }
  }

  /// Get responsive font size for captions
  static double getCaptionFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 14;
    } else {
      return 16;
    }
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context) {
    if (isMobile(context)) {
      return 24;
    } else if (isTablet(context)) {
      return 32;
    } else {
      return 40;
    }
  }

  /// Get responsive button height
  static double getButtonHeight(BuildContext context) {
    if (isMobile(context)) {
      return 48;
    } else {
      return 56;
    }
  }

  /// Get responsive border radius
  static double getBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 8;
    } else {
      return 12;
    }
  }

  /// Get maximum width for content on large screens
  static double getMaxContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isDesktop(context)) {
      return screenWidth * 0.6; // 60% of screen width on desktop
    } else if (isTablet(context)) {
      return screenWidth * 0.8; // 80% on tablet
    } else {
      return screenWidth; // Full width on mobile
    }
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context, {double factor = 1.0}) {
    final baseSpacing = isMobile(context) ? 16.0 : 24.0;
    return baseSpacing * factor;
  }

  /// Get responsive spacing with custom values
  static double getCustomSpacing(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double factor = 1.0,
  }) {
    // Use specific values if provided
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    if (isMobile(context) && mobile != null) return mobile;

    // Fallback to factor-based spacing
    final baseSpacing = isMobile(context) ? 16.0 : 24.0;
    return baseSpacing * factor;
  }

  /// Get screen size
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Get width percentage of screen
  static double getWidthPercentage(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (isDesktop(context) && desktop != null) {
      return screenWidth * desktop;
    } else if (isTablet(context) && tablet != null) {
      return screenWidth * tablet;
    } else if (isMobile(context) && mobile != null) {
      return screenWidth * mobile;
    }

    // Default fallbacks
    if (isDesktop(context)) return screenWidth * 0.4;
    if (isTablet(context)) return screenWidth * 0.6;
    return screenWidth * 0.9;
  }

  /// Get safe area bottom padding
  static double getSafeAreaBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Get keyboard height if visible
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// Responsive layout builder
  static Widget responsiveLayout(
    BuildContext context, {
    Widget? mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else if (mobile != null) {
      return mobile;
    }

    // Fallback to mobile if provided, otherwise empty container
    return mobile ?? const SizedBox.shrink();
  }
}

/// Extension methods for easier responsive design
extension ResponsiveExtensions on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  EdgeInsets get responsivePadding => ResponsiveUtils.getResponsivePadding(this);
  EdgeInsets get responsiveHorizontalPadding =>
      ResponsiveUtils.getResponsiveHorizontalPadding(this);

  double get titleFontSize => ResponsiveUtils.getTitleFontSize(this);
  double get bodyFontSize => ResponsiveUtils.getBodyFontSize(this);
  double get captionFontSize => ResponsiveUtils.getCaptionFontSize(this);

  double get iconSize => ResponsiveUtils.getIconSize(this);
  double get buttonHeight => ResponsiveUtils.getButtonHeight(this);
  double get borderRadius => ResponsiveUtils.getBorderRadius(this);
  double get maxContentWidth => ResponsiveUtils.getMaxContentWidth(this);

  double spacing({double factor = 1.0}) =>
      ResponsiveUtils.getSpacing(this, factor: factor);
}
