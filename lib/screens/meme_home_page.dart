import 'package:api_integration/models/meme_model.dart';
import 'package:api_integration/widgets/meme_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:api_integration/services/meme_service.dart';
import 'package:api_integration/services/favorites_service.dart';
import 'package:api_integration/screens/favorites_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:api_integration/utils/page_transitions.dart';
import 'dart:math';

class AnimatedHexBackground extends StatefulWidget {
  final Widget? child;
  const AnimatedHexBackground({Key? key, this.child}) : super(key: key);

  @override
  State<AnimatedHexBackground> createState() => _AnimatedHexBackgroundState();
}

class _AnimatedHexBackgroundState extends State<AnimatedHexBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: HexagonPatternPainter(_controller.value),
          child: widget.child,
        );
      },
    );
  }
}

class HexagonPatternPainter extends CustomPainter {
  final double progress;
  HexagonPatternPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint hexPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1;
    final Paint dotPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.10)
          ..style = PaintingStyle.fill;
    final double hexSize = 32;
    final double dotRadius = 2.2;
    final double dx = hexSize * 0.87;
    final double dy = hexSize * 0.5;
    final double offset = progress * hexSize * 2;
    for (double y = -hexSize; y < size.height + hexSize; y += dy * 1.5) {
      for (double x = -hexSize; x < size.width + hexSize; x += dx) {
        final evenRow = ((y / dy) % 2).abs() < 1e-6;
        final px = x + (evenRow ? 0 : dx / 2) + offset;
        final py = y + offset * 0.5;
        // Draw hexagon
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = pi / 3 * i;
          final hx = px + hexSize * cos(angle);
          final hy = py + hexSize * sin(angle);
          if (i == 0) {
            path.moveTo(hx, hy);
          } else {
            path.lineTo(hx, hy);
          }
        }
        path.close();
        canvas.drawPath(path, hexPaint);
        // Draw dot at center
        canvas.drawCircle(Offset(px, py), dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HexagonPatternPainter oldDelegate) => true;
}

class DottedTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.07)
          ..style = PaintingStyle.fill;
    final darkDotPaint =
        Paint()
          ..color = const Color(0xFF1E293B).withOpacity(0.10)
          ..style = PaintingStyle.fill;
    const double spacing = 7.0;
    const double radius = 1.1;
    for (double y = 0; y < size.height; y += spacing) {
      for (
        double x = (y ~/ spacing) % 2 == 0 ? 0 : spacing / 2;
        x < size.width;
        x += spacing
      ) {
        // Alternate between light and dark dots for more depth
        final isDark = ((x + y) ~/ spacing) % 3 == 0;
        canvas.drawCircle(
          Offset(x, y),
          radius,
          isDark ? darkDotPaint : dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MemeHomePage extends StatefulWidget {
  final bool isDarkMode;
  final void Function(bool) onToggleDarkMode;
  final String themeColor;
  final void Function(String) onThemeColorChanged;
  const MemeHomePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.themeColor,
    required this.onThemeColorChanged,
  });

  @override
  State<MemeHomePage> createState() => _MemeHomePageState();
}

class _MemeHomePageState extends State<MemeHomePage>
    with TickerProviderStateMixin {
  List<Meme> memes = [];
  List<Meme> favoriteMemes = [];
  bool isLoading = true;
  bool isError = false;
  bool isLoadingMore = false;
  int currentPage = 1;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Add emoji state
  final List<String> _emojis = [
    '😎',
    '😂',
    '🤣',
    '🥳',
    '🤓',
    '😜',
    '😇',
    '🤩',
    '😏',
    '😺',
    '👾',
    '😬',
    '😅',
    '😈',
    '🤠',
    '😃',
    '😆',
    '😋',
    '😱',
    '😻',
    '🙃',
    '😛',
    '😝',
    '😸',
    '😹',
    '😺',
    '😻',
    '😼',
    '😽',
    '🙀',
    '😿',
    '😾',
    '👻',
    '👽',
    '🤖',
    '🤑',
    '🥸',
    '😎',
    '😺',
    '😹',
    '😻',
    '😼',
    '😽',
    '🙀',
    '😿',
    '😾',
    '👻',
    '👽',
    '🤖',
    '🤑',
    '🥸',
  ];
  String _currentEmoji = '😎';

  void _changeEmoji() {
    setState(() {
      _currentEmoji = (_emojis..shuffle()).first;
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    fetchMemes();
    _loadFavorites();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await FavoritesService.getFavorites();
      if (mounted) {
        setState(() {
          favoriteMemes = favorites;
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !isLoadingMore &&
        !isLoading &&
        !isError) {
      loadMoreMemes();
    }
  }

  Future<void> loadMoreMemes() async {
    if (isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final newMemes = await MemeService.fetchMemes(
        context,
        page: currentPage + 1,
      );
      if (!mounted) return;

      if (newMemes != null && newMemes.isNotEmpty) {
        setState(() {
          memes.addAll(newMemes);
          currentPage++;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<void> fetchMemes() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isError = false;
      currentPage = 1;
    });

    try {
      final fetchedMemes = await MemeService.fetchMemes(context);
      if (!mounted) return;

      setState(() {
        memes = fetchedMemes ?? [];
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colorScheme.surfaceContainerLowest,
      drawer: _buildDrawer(colorScheme),
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 60.0,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4C6EF5), // Arc browser primary blue
                Color(0xFF364FC7), // Arc browser darker blue
                Color(0xFF3B82F6), // Arc browser bright blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.6, 1.0],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF4C6EF5).withOpacity(0.4),
                blurRadius: 25,
                offset: Offset(0, 10),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Color(0xFF364FC7).withOpacity(0.2),
                blurRadius: 40,
                offset: Offset(0, 20),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Dotted texture pattern using CustomPaint
              CustomPaint(
                painter: DottedTexturePainter(),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                ),
              ),
              // Light radial gradient overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.2,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                      Color(0xFF1E293B).withOpacity(0.08),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Top glass reflection
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 35,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Meme Explorer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Mixed feed from all categories',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Builder(
              builder:
                  (context) => IconButton(
                    icon: Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Scaffold.of(context).openDrawer();
                    },
                  ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed:
                    isLoading
                        ? null
                        : () async {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            memes.clear();
                            currentPage = 1;
                          });
                          _changeEmoji();
                          await fetchMemes();
                        },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showSettings(context);
                },
              ),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedHexBackground(
        child: Builder(
          builder: (BuildContext scaffoldContext) {
            return GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 500) {
                  try {
                    final scaffold = Scaffold.maybeOf(scaffoldContext);
                    if (scaffold != null && !scaffold.isDrawerOpen) {
                      scaffold.openDrawer();
                    }
                  } catch (e) {
                    debugPrint('Drawer gesture ignored: $e');
                  }
                }
              },
              child: RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    memes.clear();
                    currentPage = 1;
                  });
                  _changeEmoji();
                  await fetchMemes();
                },
                backgroundColor: colorScheme.surface,
                color: colorScheme.primary,
                child: _buildBody(colorScheme),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(colorScheme),
    );
  }

  Widget _buildFloatingActionButton(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        // Show/hide FAB based on scroll position
        final showFab =
            _scrollController.hasClients && _scrollController.offset > 500;

        return AnimatedScale(
          scale: showFab ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: showFab ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                );
              },
              icon: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * 0.1,
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 24,
                    ),
                  );
                },
              ),
              label: const Text(
                "Top",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 16,
              hoverElevation: 20,
              focusElevation: 20,
              heroTag: "scrollToTop",
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE91E63).withAlpha(20),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE91E63).withAlpha(20),
                    const Color(0xFF2196F3).withAlpha(20),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                '✨ Loading awesome memes...',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF5722).withAlpha(16),
                  const Color(0xFFFF9800).withAlpha(16),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFF5722).withAlpha(48),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Oops! Couldn't load memes",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Check your internet connection and try again",
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE91E63).withAlpha(80),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: fetchMemes,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Try Again"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (memes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF9800).withAlpha(32),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No memes found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try refreshing to load some fresh content",
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final meme = memes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: MemeCard(
                    title: meme.title ?? '',
                    imageUrl: meme.url ?? '',
                    ups: meme.ups ?? 0,
                    postLink: meme.postLink ?? '',
                    index: index,
                    subreddit: meme.subreddit ?? '',
                    onAddToFavorites: addToFavorites,
                  ),
                );
              }, childCount: memes.length),
            ),
          ),
          if (isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF2196F3).withAlpha(48),
                          Colors.transparent,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
        physics: const BouncingScrollPhysics(),
      ),
    );
  }

  Widget _buildDrawer(ColorScheme colorScheme) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE91E63).withAlpha(16),
              const Color(0xFF2196F3).withAlpha(12),
              const Color(0xFFFF9800).withAlpha(8),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE91E63).withAlpha(24),
                    const Color(0xFF2196F3).withAlpha(18),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withAlpha(64),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Meme Explorer",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      foreground:
                          Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFFE91E63), Color(0xFF2196F3)],
                            ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Your favorite memes",
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: "Home",
                    subtitle: "Discover new memes",
                    color: const Color(0xFFE91E63),
                    onTap: () {
                      Navigator.pop(context);
                    },
                    colorScheme: colorScheme,
                  ),
                  _buildDrawerItem(
                    icon: Icons.favorite_rounded,
                    title: "Favorites",
                    subtitle: "${favoriteMemes.length} saved memes",
                    color: const Color(0xFFFF5722),
                    onTap: () async {
                      Navigator.pop(context);
                      await _loadFavorites(); // Refresh favorites before showing screen
                      _showFavorites(context);
                    },
                    colorScheme: colorScheme,
                  ),
                  _buildDrawerItem(
                    icon: Icons.trending_up_rounded,
                    title: "Trending",
                    subtitle: "Popular memes",
                    color: const Color(0xFF2196F3),
                    onTap: () {
                      Navigator.pop(context);
                      _showTrending(context);
                    },
                    colorScheme: colorScheme,
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: "Settings",
                    subtitle: "App preferences",
                    color: const Color(0xFF9C27B0),
                    onTap: () {
                      Navigator.pop(context);
                      _showSettings(context);
                    },
                    colorScheme: colorScheme,
                  ),

                  const Divider(height: 32, thickness: 1),

                  // Favorites Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Recent Favorites",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5722), Color(0xFFE91E63)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${favoriteMemes.length}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actual favorite memes
                  if (favoriteMemes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFFF5722).withAlpha(32),
                                  Colors.transparent,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_border_rounded,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No favorites yet",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap the heart icon on memes to add them here",
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...favoriteMemes
                        .take(3)
                        .map(
                          (meme) => _buildFavoriteMemeItem(
                            title: meme.title ?? 'Untitled Meme',
                            imageUrl: meme.url ?? '',
                            color: const Color(0xFFE91E63),
                            onTap: () {
                              Navigator.pop(context);
                              _showFavorites(context);
                            },
                            onLongPress: () async {
                              await removeFromFavorites(meme);
                              await _loadFavorites(); // Refresh the list
                            },
                            colorScheme: colorScheme,
                          ),
                        ),
                  if (favoriteMemes.length > 3)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          "And ${favoriteMemes.length - 3} more favorites...",
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Drawer Footer
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE91E63).withAlpha(24),
                          const Color(0xFF2196F3).withAlpha(18),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Meme Explorer v1.0",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                final url = Uri.parse(
                                  'https://www.linkedin.com/in/shouryagupta13/',
                                );
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              child: Icon(
                                FontAwesomeIcons.linkedin,
                                color: Color(0xFF0A66C2),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Made with ❤️ by Shourya",
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withAlpha(112),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withAlpha(64), color.withAlpha(32)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      onTap: onTap,
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildFavoriteMemeItem({
    required String title,
    required String imageUrl,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withAlpha(192), color.withAlpha(128)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) =>
                    Icon(Icons.image_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        "Tap to view",
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  void _showFavorites(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const FavoritesScreen()));
  }

  void _showTrending(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => _TrendingMemesScreen()));
  }

  void _showSettings(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => _SettingsScreen(
              isDarkMode: widget.isDarkMode,
              onToggleDarkMode: widget.onToggleDarkMode,
              themeColor: widget.themeColor,
              onThemeColorChanged: widget.onThemeColorChanged,
            ),
      ),
    );
  }

  void _showMemeDetails(BuildContext context, Meme meme) {
    // Implement the logic to show meme details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening meme details'),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Add meme to favorites
  Future<void> addToFavorites(Meme meme) async {
    // The MemeCard now handles the actual favorite toggle and feedback
    // This method is called to refresh the parent's favorites list
    await _loadFavorites(); // Reload favorites from storage
  }

  // Remove meme from favorites
  Future<void> removeFromFavorites(Meme meme) async {
    final success = await FavoritesService.removeFromFavorites(meme);
    if (success && mounted) {
      await _loadFavorites(); // Reload favorites from storage
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites 💔'),
          backgroundColor: Color(0xFF9C27B0),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _TrendingMemesScreen extends StatefulWidget {
  @override
  State<_TrendingMemesScreen> createState() => _TrendingMemesScreenState();
}

class _TrendingMemesScreenState extends State<_TrendingMemesScreen> {
  List<Meme> trendingMemes = [];
  bool isLoading = true;
  bool isError = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchTrendingMemes();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchTrendingMemes() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final fetchedMemes = await MemeService.fetchTrendingMemes(context);
      if (!mounted) return;

      setState(() {
        trendingMemes = fetchedMemes ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Memes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2196F3).withAlpha(16),
              const Color(0xFFFF9800).withAlpha(12),
              const Color(0xFF9C27B0).withAlpha(8),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: fetchTrendingMemes,
          backgroundColor: colorScheme.surface,
          color: colorScheme.primary,
          child: _buildBody(colorScheme),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text("Back"),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 12,
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2196F3).withAlpha(32),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2196F3).withAlpha(32),
                    const Color(0xFFFF9800).withAlpha(32),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                '🔥 Loading trending memes...',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF5722).withAlpha(16),
                  const Color(0xFFFF9800).withAlpha(16),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFF5722).withAlpha(48),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Oops! Couldn't load trending memes",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Check your internet connection and try again",
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withAlpha(64),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: fetchTrendingMemes,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Try Again"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (trendingMemes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF9800).withAlpha(32),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No trending memes found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try refreshing to load some fresh content",
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 0.75,
              mainAxisSpacing: 20,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final meme = trendingMemes[index];
              return MemeCard(
                title: meme.title ?? '',
                imageUrl: meme.url ?? '',
                ups: meme.ups ?? 0,
                postLink: meme.postLink ?? '',
                index: index,
                subreddit: meme.subreddit ?? '',
              );
            }, childCount: trendingMemes.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
      physics: const BouncingScrollPhysics(),
    );
  }
}

class _SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final void Function(bool) onToggleDarkMode;
  final String themeColor;
  final void Function(String) onThemeColorChanged;
  const _SettingsScreen({
    Key? key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.themeColor,
    required this.onThemeColorChanged,
  }) : super(key: key);
  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  late bool _darkMode;
  bool _notificationsEnabled = true;
  bool _autoPlayVideos = true;
  late String _selectedTheme;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.isDarkMode;
    _selectedTheme = widget.themeColor;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF9C27B0).withAlpha(5),
              const Color(0xFF2196F3).withAlpha(3),
              const Color(0xFFE91E63).withAlpha(2),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Appearance', Icons.palette_outlined),
            _buildSettingCard(
              title: 'Dark Mode',
              subtitle: 'Enable dark theme for the app',
              icon: Icons.dark_mode_outlined,
              trailing: Switch(
                value: _darkMode,
                onChanged: (value) {
                  setState(() {
                    _darkMode = value;
                  });
                  widget.onToggleDarkMode(value);
                },
                activeColor: const Color(0xFF9C27B0),
              ),
            ),
            _buildSettingCard(
              title: 'App Theme',
              subtitle: 'Choose your preferred theme color',
              icon: Icons.color_lens_outlined,
              trailing: DropdownButton<String>(
                value: _selectedTheme,
                items:
                    ['Default', 'Blue', 'Green', 'Orange']
                        .map(
                          (theme) => DropdownMenuItem(
                            value: theme,
                            child: Text(theme),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTheme = value;
                    });
                    widget.onThemeColorChanged(value);
                  }
                },
                underline: Container(),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Notifications', Icons.notifications_outlined),
            _buildSettingCard(
              title: 'Push Notifications',
              subtitle: 'Get notified about new trending memes',
              icon: Icons.notifications_active_outlined,
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Notifications enabled'
                            : 'Notifications disabled',
                      ),
                      backgroundColor: const Color(0xFF9C27B0),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                activeColor: const Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Content', Icons.image_outlined),
            _buildSettingCard(
              title: 'Auto-play Videos',
              subtitle: 'Automatically play video content',
              icon: Icons.play_circle_outline,
              trailing: Switch(
                value: _autoPlayVideos,
                onChanged: (value) {
                  setState(() {
                    _autoPlayVideos = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Videos will auto-play'
                            : 'Videos will not auto-play',
                      ),
                      backgroundColor: const Color(0xFF9C27B0),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                activeColor: const Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Account', Icons.account_circle_outlined),
            _buildSettingCard(
              title: 'Logout',
              subtitle: 'Sign out of your account',
              icon: Icons.logout_rounded,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text(
                          'Are you sure you want to logout? You will need to sign in again to access your account.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5722),
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                );

                if (confirmed == true) {
                  try {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully logged out 👋'),
                          backgroundColor: Color(0xFF4CAF50),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.of(context).pop(); // Close settings screen
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error logging out: ${e.toString()}'),
                          backgroundColor: const Color(0xFFFF5722),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('About', Icons.info_outline),
            _buildSettingCard(
              title: 'App Version',
              subtitle: 'Meme Explorer v1.0',
              icon: Icons.android_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You are using the latest version!'),
                    backgroundColor: Color(0xFF9C27B0),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _buildSettingCard(
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              icon: Icons.privacy_tip_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Privacy policy coming soon!'),
                    backgroundColor: Color(0xFF9C27B0),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _buildSettingCard(
              title: 'Terms of Service',
              subtitle: 'Read our terms of service',
              icon: Icons.description_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terms of service coming soon!'),
                    backgroundColor: Color(0xFF9C27B0),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withAlpha(80),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text("Save Settings"),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9C27B0), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9C27B0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      shadowColor: Colors.black.withAlpha(32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withAlpha(64),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF9C27B0)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
