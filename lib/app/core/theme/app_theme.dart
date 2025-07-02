import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  // Light Theme Colors
  static Color backgroundColor = const Color(0xffF5F8FA);
  static Color blueColor = const Color(0xff1DA1F2);
  static Color blackColor = const Color(0xff14171A);
  static Color darkGrayColor = const Color(0xff657786);
  static Color lightGrayColor = const Color(0xffAAB8C2);
  static Color errorColor = const Color(0xffFB4747);
  static Color whiteColor = const Color(0xffffffff);

  // Dark Theme Colors
  static Color darkBackgroundColor = const Color(0xff1A1A2E);
  static Color darkPrimaryColor = const Color(0xff0F3460);
  static Color darkCardColor = const Color(0xff16213E);
  static Color darkTextColor = const Color(0xffE94560);
  static Color darkHintColor = const Color(0xff6B7280);

  // Define custom colors
  static const Color primaryColor = Color(0xFF036273);
  static const Color secondaryColor = Color(0xFFB7D3D7);
  static const Color surfaceColor = Color(0xFFF8FAFA);
  static const Color onPrimaryColor = Colors.white;

  // Light Theme Configuration
  static final lightTheme = ThemeData(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.light,
    backgroundColor: backgroundColor,
    primaryColor: primaryColor,
    hintColor: lightGrayColor,
    cardColor: whiteColor,
    errorColor: errorColor,
    textTheme: _lightTextTheme,
    colorScheme: _lightColorScheme,
    elevatedButtonTheme: _lightElevatedButtonTheme,
    inputDecorationTheme: _inputDecorationTheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
    ),
  );

  static final _lightTextTheme = TextTheme(
    button: GoogleFonts.poppins(
      fontSize: 14.sp,
      fontWeight: FontWeight.w700,
    ),
    caption: GoogleFonts.poppins(
      fontSize: 13.sp,
      fontWeight: FontWeight.w400,
      color: lightGrayColor,
    ),
  );

  static final _lightColorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
    background: backgroundColor,
    onBackground: blackColor,
    primary: primaryColor,
    onPrimary: backgroundColor,
    secondary: secondaryColor,
    onSecondary: backgroundColor,
    surface: surfaceColor,
  );

  static final _lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  static final _inputDecorationTheme = InputDecorationTheme(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    hintStyle: _lightTextTheme.caption,
    errorStyle: _lightTextTheme.caption?.copyWith(
      color: errorColor,
      fontSize: 10.sp,
    ),
    fillColor: whiteColor,
    filled: true,
    errorMaxLines: 3,
    counterStyle: _lightTextTheme.caption?.copyWith(fontSize: 10.sp),
    suffixIconColor: darkGrayColor,
    prefixIconColor: lightGrayColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: secondaryColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: secondaryColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
  );

  // Dark Theme Configuration
  static final darkTheme = ThemeData(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.dark,
    backgroundColor: darkBackgroundColor,
    primaryColor: primaryColor,
    hintColor: darkHintColor,
    cardColor: darkCardColor,
    errorColor: errorColor,
    textTheme: _darkTextTheme,
    colorScheme: _darkColorScheme,
    elevatedButtonTheme: _darkElevatedButtonTheme,
    inputDecorationTheme: _darkInputDecorationTheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Color(0xFF2C2C2C),
    ),
  );

  static final _darkTextTheme = TextTheme(
    button: GoogleFonts.poppins(
      fontSize: 14.sp,
      fontWeight: FontWeight.w700,
      color: darkTextColor,
    ),
    caption: GoogleFonts.poppins(
      fontSize: 13.sp,
      fontWeight: FontWeight.w400,
      color: darkHintColor,
    ),
  );

  static final _darkColorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.dark,
    background: darkBackgroundColor,
    onBackground: darkTextColor,
    primary: primaryColor,
    onPrimary: darkBackgroundColor,
    secondary: secondaryColor,
    onSecondary: darkBackgroundColor,
    surface: Color(0xFF1E1E1E),
  );

  static final _darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  static final _darkInputDecorationTheme = InputDecorationTheme(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    hintStyle: _darkTextTheme.caption,
    errorStyle: _darkTextTheme.caption?.copyWith(
      color: errorColor,
      fontSize: 10.sp,
    ),
    fillColor: darkCardColor,
    filled: true,
    errorMaxLines: 3,
    counterStyle: _darkTextTheme.caption?.copyWith(fontSize: 10.sp),
    suffixIconColor: darkHintColor,
    prefixIconColor: darkGrayColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: secondaryColor.withOpacity(0.5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: secondaryColor.withOpacity(0.5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
  );
}
