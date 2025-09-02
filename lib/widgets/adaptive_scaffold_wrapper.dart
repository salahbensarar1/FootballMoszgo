import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../config/environment.dart';

/// Adaptive scaffold wrapper that ensures proper content layout across all screen sizes
class AdaptiveScaffoldWrapper extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool showDebugBanner;
  final double maxContentWidth;
  final EdgeInsets? padding;

  const AdaptiveScaffoldWrapper({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.showDebugBanner = false,
    this.maxContentWidth = 1200.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveUtils.isMobile(context);
    final effectivePadding = padding ?? 
        EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 8 : 16,
        );

    Widget scaffoldBody = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: effectivePadding,
            child: body,
          ),
        ),
      ),
    );

    // Add debug banner if enabled
    if (showDebugBanner && Environment.isDevelopment) {
      scaffoldBody = Banner(
        message: 'DEBUG',
        location: BannerLocation.topEnd,
        child: scaffoldBody,
      );
    }

    // Add demo banner if this is a demo organization
    scaffoldBody = _wrapWithDemoBanner(context, scaffoldBody);

    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.grey.shade50,
      appBar: appBar,
      body: scaffoldBody,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
    );
  }

  Widget _wrapWithDemoBanner(BuildContext context, Widget child) {
    // Check if this is a demo organization
    try {
      if (!Environment.isDemo) {
        return child;
      }
    } catch (e) {
      // Environment not initialized (likely in tests) - skip demo banner
      return child;
    }

    return Banner(
      message: 'DEMO',
      location: BannerLocation.topStart,
      color: Colors.orange.shade700,
      child: child,
    );
  }
}

/// Mixin for making dialogs scrollable and adaptive
mixin AdaptiveDialogMixin {
  Widget buildAdaptiveDialog({
    required BuildContext context,
    required Widget content,
    List<Widget>? actions,
    String? title,
    Widget? titleWidget,
    EdgeInsetsGeometry? contentPadding,
    double maxHeightFactor = 0.8,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * maxHeightFactor;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: titleWidget ?? (title != null ? Text(title) : null),
      contentPadding: contentPadding ?? const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: 600, // Max width for desktop
        ),
        child: SingleChildScrollView(
          child: content,
        ),
      ),
      actions: actions,
    );
  }
}

/// Adaptive button bar that scrolls horizontally on small screens
class AdaptiveButtonBar extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment alignment;
  final double spacing;

  const AdaptiveButtonBar({
    super.key,
    required this.children,
    this.alignment = MainAxisAlignment.end,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveUtils.isMobile(context);
    
    if (isSmallScreen && children.length > 2) {
      // Use horizontal scroll for small screens with many buttons
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: alignment,
          children: children
              .expand((child) => [child, SizedBox(width: spacing)])
              .toList()
            ..removeLast(), // Remove last spacing
        ),
      );
    }

    return Row(
      mainAxisAlignment: alignment,
      children: children
          .expand((child) => [child, SizedBox(width: spacing)])
          .toList()
        ..removeLast(), // Remove last spacing
    );
  }
}

/// Adaptive text that handles overflow gracefully
class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign textAlign;
  final double? scaleFactor;

  const AdaptiveText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign = TextAlign.start,
    this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScale = mediaQuery.textScaler.scale(1.0);
    
    // Adjust text scale if it gets too large
    final effectiveScaleFactor = scaleFactor ?? 
        (textScale > 1.3 ? 1.3 : textScale);

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(effectiveScaleFactor),
      ),
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}