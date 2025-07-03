import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class GradientAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;
  final VoidCallback? onTitleTap;
  final Widget? titleWidget;

  const GradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.elevation = 0,
    this.onTitleTap,
    this.titleWidget,
  });

  @override
  State<GradientAppBar> createState() => _GradientAppBarState();

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (subtitle != null ? 20 : 8));
}

class _GradientAppBarState extends State<GradientAppBar>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late Animation<double> _gradientAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animated gradient controller
    _gradientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Floating elements controller
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Pulse effect controller
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _gradientAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.linear),
    );

    _floatingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double minHeight =
        kToolbarHeight + (widget.subtitle != null ? 28 : 0);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _gradientAnimation,
        _floatingAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          elevation: widget.elevation,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF3B82F6),
                    const Color(0xFF60A5FA),
                    0.7,
                  )!,
                  Color.lerp(
                    const Color(0xFF60A5FA),
                    const Color(0xFF2563EB),
                    0.5,
                  )!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Menu Icon
                    _GlassyIconButton(
                      icon: widget.leading != null ? null : Icons.menu_rounded,
                      child: widget.leading,
                      onPressed:
                          widget.leading == null
                              ? () => widget.onTitleTap?.call()
                              : null,
                      tooltip: 'Menu',
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            widget.title.isNotEmpty
                                ? widget.title
                                : 'Meme Explorer',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          if (widget.subtitle != null &&
                              widget.subtitle!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                widget.subtitle!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          widget.actions != null
                              ? widget.actions!
                                  .map(
                                    (action) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: _GlassyIconButton(
                                        icon: null,
                                        child: action,
                                      ),
                                    ),
                                  )
                                  .toList()
                              : [],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Glassy/circular icon button for app bar actions
class _GlassyIconButton extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _GlassyIconButton({
    this.icon,
    this.child,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.10),
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child:
              child ??
              (icon != null ? Icon(icon, color: Colors.white, size: 24) : null),
        ),
      ),
    );
  }
}

class GradientActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const GradientActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (backgroundColor ?? Colors.white).withOpacity(0.2),
            (backgroundColor ?? Colors.white).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (backgroundColor ?? Colors.white).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: foregroundColor ?? Colors.white, size: 24),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: foregroundColor ?? Colors.white,
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
