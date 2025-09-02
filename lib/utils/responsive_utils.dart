import 'package:flutter/material.dart';

/// Utility class for responsive design helpers
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

  /// Get responsive maximum width for content
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 800;
    return double.infinity;
  }

  /// Get screen size
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Get responsive padding
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

  /// Get responsive spacing
  static double getSpacing(
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