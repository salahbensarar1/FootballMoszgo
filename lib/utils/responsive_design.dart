import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// Legacy responsive design utility - now delegates to ResponsiveUtils
/// This file exists for backward compatibility during migration
class ResponsiveDesign {
  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return ResponsiveUtils.isMobile(context);
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    return ResponsiveUtils.isTablet(context);
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return ResponsiveUtils.isDesktop(context);
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return ResponsiveUtils.getPadding(context);
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
    return ResponsiveUtils.getMaxContentWidth(context);
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context, {double factor = 1.0}) {
    return ResponsiveUtils.getSpacing(context, factor: factor);
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

/// Extension methods for easier responsive design - delegates to ResponsiveUtils
extension ResponsiveExtensions on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  EdgeInsets get responsivePadding => ResponsiveUtils.getPadding(this);
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