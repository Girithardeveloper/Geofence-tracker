import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

class ResponsiveSize {
  /// Screen Breakpoints
  static const double largeDesktopWidth = 1920.0;
  static const double desktopWidth = 1024.0;
  static const double tabletWidth = 768.0;
  static const double mobileWidth = 480.0; // Adjusted for better separation

  /// Scale factors for different screen types
  static const double largeDesktopScale = 1.1;
  static const double desktopScale = 1.15;
  static const double tabletScale = 1.05;
  static const double mobileScale = 0.95;

  static double getSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    /// Determine scale factor
    double scaleFactor;
    if (screenWidth > largeDesktopWidth) {
      scaleFactor = (screenWidth / largeDesktopWidth) * largeDesktopScale;
    } else if (screenWidth > desktopWidth) {
      scaleFactor = (screenWidth / desktopWidth) * desktopScale;
    } else if (screenWidth > tabletWidth) {
      scaleFactor = (screenWidth / tabletWidth) * tabletScale;
    } else {
      scaleFactor = (screenWidth / mobileWidth) * mobileScale;
    }

    /// Apply constraints to prevent excessive scaling
    scaleFactor = scaleFactor.clamp(0.8, 1.6);

    /// Pixel density adjustment (improved)
    double adjustedPixelRatio = pixelRatio > 2 ? (pixelRatio * 0.65) : 1;

    /// Compute final size with adjustments
    return math.max((baseSize * scaleFactor) / adjustedPixelRatio, 8.0);
  }
}

