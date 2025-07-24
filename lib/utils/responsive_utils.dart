import 'package:flutter/material.dart';

/// Device type enumeration
enum DeviceType { mobile, tablet, desktop, largeDesktop }

/// Responsive design utility class for consistent layouts across devices
class ResponsiveUtils {
  static const double _tabletBreakpoint = 768.0;
  static const double _desktopBreakpoint = 1024.0;
  static const double _largeDesktopBreakpoint = 1440.0;

  /// Get current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= _largeDesktopBreakpoint) return DeviceType.largeDesktop;
    if (width >= _desktopBreakpoint) return DeviceType.desktop;
    if (width >= _tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  /// Check if current device is mobile
  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  /// Get responsive padding based on device type
  static EdgeInsets getPadding(BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    final deviceType = getDeviceType(context);
    double padding = mobile;
    
    switch (deviceType) {
      case DeviceType.mobile:
        padding = mobile;
        break;
      case DeviceType.tablet:
        padding = tablet;
        break;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        padding = desktop;
        break;
    }
    
    return EdgeInsets.all(padding);
  }

  /// Get responsive spacing based on device type
  static double getSpacing(BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktop;
    }
  }

  /// Get responsive grid columns
  static int getGridColumns(BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktop;
    }
  }

  /// Get responsive width as percentage of screen
  static double getWidthPercentage(BuildContext context, {
    double mobile = 1.0,
    double tablet = 0.8,
    double desktop = 0.7,
  }) {
    final deviceType = getDeviceType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    double percentage = mobile;
    switch (deviceType) {
      case DeviceType.mobile:
        percentage = mobile;
        break;
      case DeviceType.tablet:
        percentage = tablet;
        break;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        percentage = desktop;
        break;
    }
    
    return screenWidth * percentage;
  }

  /// Get responsive button height
  static double getButtonHeight(BuildContext context, {
    double mobile = 48.0,
    double tablet = 52.0,
    double desktop = 56.0,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktop;
    }
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, {
    double mobile = 24.0,
    double tablet = 28.0,
    double desktop = 32.0,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktop;
    }
  }

  /// Get responsive layout based on screen size
  static Widget responsiveLayout({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get screen dimensions
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Get responsive maximum width for content
  static double getMaxContentWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return double.infinity;
      case DeviceType.tablet:
        return 600.0;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return 1200.0;
    }
  }

  /// Get responsive border radius
  static BorderRadius getBorderRadius(BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    final deviceType = getDeviceType(context);
    
    double radius = mobile;
    switch (deviceType) {
      case DeviceType.mobile:
        radius = mobile;
        break;
      case DeviceType.tablet:
        radius = tablet;
        break;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        radius = desktop;
        break;
    }
    
    return BorderRadius.circular(radius);
  }
}