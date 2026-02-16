import 'package:flutter/material.dart';

/// Extension on BuildContext for responsive design utilities
/// 
/// Provides consistent breakpoints across the application:
/// - Narrow: < 600px (stacked layouts, simplified UI)
/// - Mobile: < 768px (reduced padding, mobile optimizations)
extension ResponsiveUtils on BuildContext {
  /// Returns the current screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Returns true if screen width is less than 600px
  /// Use for stacked layouts and major UI simplifications
  bool get isNarrow => screenWidth < 600;

  /// Returns true if screen width is less than 768px
  /// Use for reduced padding and mobile-specific optimizations
  bool get isMobile => screenWidth < 768;

  /// Returns true if screen width is 600px or greater
  bool get isWide => !isNarrow;

  /// Returns true if screen width is 768px or greater
  bool get isDesktop => !isMobile;
}
