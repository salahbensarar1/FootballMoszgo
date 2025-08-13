import 'package:flutter/material.dart';

/// Responsive design utility for consistent UI across all devices
class ResponsiveDesign {
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

  /// Get safe area bottom padding
  static double getSafeAreaBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Get keyboard height if visible
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }
}

/// Extension methods for easier responsive design
extension ResponsiveExtensions on BuildContext {
  bool get isMobile => ResponsiveDesign.isMobile(this);
  bool get isTablet => ResponsiveDesign.isTablet(this);
  bool get isDesktop => ResponsiveDesign.isDesktop(this);
  
  EdgeInsets get responsivePadding => ResponsiveDesign.getResponsivePadding(this);
  EdgeInsets get responsiveHorizontalPadding => ResponsiveDesign.getResponsiveHorizontalPadding(this);
  
  double get titleFontSize => ResponsiveDesign.getTitleFontSize(this);
  double get bodyFontSize => ResponsiveDesign.getBodyFontSize(this);
  double get captionFontSize => ResponsiveDesign.getCaptionFontSize(this);
  
  double get iconSize => ResponsiveDesign.getIconSize(this);
  double get buttonHeight => ResponsiveDesign.getButtonHeight(this);
  double get borderRadius => ResponsiveDesign.getBorderRadius(this);
  double get maxContentWidth => ResponsiveDesign.getMaxContentWidth(this);
  
  double spacing({double factor = 1.0}) => ResponsiveDesign.getSpacing(this, factor: factor);
}