import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScreenConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeH;
  static late double blockSizeV;
  static late double safeAreaH;
  static late double safeAreaV;
  static late bool isSmallPhone;
  static late bool isMediumPhone;
  static late bool isLargePhone;
  static late bool isTablet;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeH = screenWidth / 100;
    blockSizeV = screenHeight / 100;
    safeAreaH = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaV = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;

    // Phone size categories
    isSmallPhone = screenWidth <= 375;   // iPhone SE, small Android
    isMediumPhone = screenWidth > 375 && screenWidth <= 414; // iPhone 14, Pixel
    isLargePhone = screenWidth > 414 && screenWidth < 768;   // Pro Max, large Android
    isTablet = screenWidth >= 768;       // iPad, Android tablet
  }

  // Responsive spacing
  static double get spaceXS => isSmallPhone ? 4 : isTablet ? 8 : 6;
  static double get spaceS => isSmallPhone ? 8 : isTablet ? 16 : 12;
  static double get spaceM => isSmallPhone ? 12 : isTablet ? 24 : 16;
  static double get spaceL => isSmallPhone ? 16 : isTablet ? 32 : 24;
  static double get spaceXL => isSmallPhone ? 20 : isTablet ? 48 : 32;
  static double get spaceXXL => isSmallPhone ? 24 : isTablet ? 64 : 40;

  // Responsive font sizes
  static double get fontXS => isSmallPhone ? 10 : isTablet ? 14 : 12;
  static double get fontS => isSmallPhone ? 12 : isTablet ? 16 : 14;
  static double get fontM => isSmallPhone ? 14 : isTablet ? 18 : 16;
  static double get fontL => isSmallPhone ? 16 : isTablet ? 22 : 18;
  static double get fontXL => isSmallPhone ? 18 : isTablet ? 28 : 22;
  static double get fontXXL => isSmallPhone ? 22 : isTablet ? 36 : 28;
  static double get fontDisplay => isSmallPhone ? 26 : isTablet ? 44 : 32;

  // Responsive icon sizes
  static double get iconS => isSmallPhone ? 16 : isTablet ? 24 : 20;
  static double get iconM => isSmallPhone ? 20 : isTablet ? 32 : 24;
  static double get iconL => isSmallPhone ? 28 : isTablet ? 44 : 36;
  static double get iconXL => isSmallPhone ? 36 : isTablet ? 56 : 48;

  // Responsive border radius
  static double get radiusS => isSmallPhone ? 8 : isTablet ? 14 : 10;
  static double get radiusM => isSmallPhone ? 12 : isTablet ? 20 : 16;
  static double get radiusL => isSmallPhone ? 16 : isTablet ? 28 : 20;
  static double get radiusXL => isSmallPhone ? 20 : isTablet ? 36 : 28;

  // Responsive button heights
  static double get buttonHeight => isSmallPhone ? 46 : isTablet ? 60 : 52;
  static double get buttonHeightSmall => isSmallPhone ? 36 : isTablet ? 48 : 42;

  // Responsive card padding
  static EdgeInsets get cardPadding => EdgeInsets.all(
    isSmallPhone ? 12 : isTablet ? 24 : 16
  );
  static EdgeInsets get screenPadding => EdgeInsets.symmetric(
    horizontal: isSmallPhone ? 12 : isTablet ? 32 : 16,
    vertical: isSmallPhone ? 8 : isTablet ? 16 : 12,
  );

  // Responsive avatar sizes
  static double get avatarS => isSmallPhone ? 32 : isTablet ? 52 : 40;
  static double get avatarM => isSmallPhone ? 44 : isTablet ? 64 : 52;
  static double get avatarL => isSmallPhone ? 56 : isTablet ? 80 : 64;

  // Grid columns
  static int get gridColumns => isTablet ? 3 : 2;
  static int get trainingTypeColumns => isTablet ? 4 : 4;
}

class AppTheme {
  // === CORE PALETTE ===
  static const Color background   = Color(0xFF1B2632); // Abyssal Navy
  static const Color surface      = Color(0xFF2C3B4D); // Blue Fantastic
  static const Color surface2     = Color(0xFF243040); // Mid layer
  static const Color surfaceHigh  = Color(0xFF34495E); // Elevated elements
  static const Color primary      = Color(0xFFFFB162); // Burning Flame gold
  static const Color secondary    = Color(0xFFA35139); // Truffle brown
  static const Color textPrimary  = Color(0xFFEEE9DF); // Palladian warm white
  static const Color textSecondary= Color(0xFFC9C1B1); // Oatmeal
  static const Color textMuted    = Color(0xFF8A8070); // Muted warm grey
  static const Color success      = Color(0xFF4CAF50);
  static const Color error        = Color(0xFFEF5350);
  static const Color warning      = Color(0xFFFFB162); // same as primary
  static const Color border       = Color(0xFF34495E);
  static const Color borderSubtle = Color(0xFF2C3B4D);

  // === GRADIENTS ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFB162), Color(0xFFA35139)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF1B2632), Color(0xFF243040)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF2C3B4D), Color(0xFF243040)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFFFB162), Color(0xFFA35139), Color(0xFF1B2632)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.4, 1.0],
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === SHADOWS ===
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.3),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.1),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: primary.withValues(alpha:0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: primary.withValues(alpha:0.2),
      blurRadius: 40,
      spreadRadius: 0,
      offset: Offset.zero,
    ),
  ];

  // === DECORATIONS ===
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: border, width: 1),
    boxShadow: cardShadow,
  );

  static BoxDecoration surfaceDecoration = BoxDecoration(
    color: surface2,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderSubtle, width: 1),
  );

  // === TYPOGRAPHY — Syne display + Poppins body ===
  static TextStyle display = GoogleFonts.syne(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -1.5,
  );
  static TextStyle heading1 = GoogleFonts.syne(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  static TextStyle heading2 = GoogleFonts.syne(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );
  static TextStyle heading3 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  static TextStyle label = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 1.2,
  );
  // Overline — uppercase tracking label
  static TextStyle overline = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: textMuted,
    letterSpacing: 2.0,
  );
  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.3,
  );
  static TextStyle statNumber = GoogleFonts.syne(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -1.0,
  );

  // === FULL THEME ===
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: background,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.poppins(
          color: textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: textSecondary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB162), Color(0xFFA35139)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: background,
        unselectedLabelColor: textSecondary,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withValues(alpha:0.3)
              : border,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(background),
        side: const BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}