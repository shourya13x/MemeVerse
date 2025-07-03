import 'package:flutter/material.dart';

/// Premium page transitions for smooth navigation
class PremiumPageTransitions {
  /// Slide transition from right to left
  static Route<T> slideFromRight<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Slide transition from bottom to top
  static Route<T> slideFromBottom<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutExpo;

        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: Curves.easeInExpo,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  /// Scale transition with fade
  static Route<T> scaleTransition<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutBack;

        final scaleAnimation = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }

  /// Custom hero-like transition
  static Route<T> heroTransition<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.3, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        final scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
          ),
        );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(opacity: fadeAnimation, child: child),
          ),
        );
      },
    );
  }

  /// Fluid page transition with blur effect
  static Route<T> fluidTransition<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 550),
      reverseTransitionDuration: const Duration(milliseconds: 450),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child_) {
            final slideValue = Curves.easeOutCubic.transform(animation.value);
            final fadeValue = Curves.easeOut.transform(animation.value);

            return Transform.translate(
              offset: Offset(50 * (1 - slideValue), 0),
              child: Opacity(
                opacity: fadeValue,
                child: Transform.scale(
                  scale: 0.95 + (0.05 * slideValue),
                  child: child,
                ),
              ),
            );
          },
          child: child,
        );
      },
    );
  }
}

/// Extension method for easy navigation with transitions
extension NavigationExtensions on BuildContext {
  /// Navigate with slide from right transition
  Future<T?> pushSlideFromRight<T extends Object?>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(PremiumPageTransitions.slideFromRight<T>(page));
  }

  /// Navigate with slide from bottom transition
  Future<T?> pushSlideFromBottom<T extends Object?>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(PremiumPageTransitions.slideFromBottom<T>(page));
  }

  /// Navigate with scale transition
  Future<T?> pushScaleTransition<T extends Object?>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(PremiumPageTransitions.scaleTransition<T>(page));
  }

  /// Navigate with hero transition
  Future<T?> pushHeroTransition<T extends Object?>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(PremiumPageTransitions.heroTransition<T>(page));
  }

  /// Navigate with fluid transition
  Future<T?> pushFluidTransition<T extends Object?>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(PremiumPageTransitions.fluidTransition<T>(page));
  }
}
