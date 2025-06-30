import 'package:flutter/material.dart';
import 'package:api_integration/models/meme_model.dart';
import 'package:api_integration/services/favorites_service.dart';
import 'package:api_integration/widgets/meme_card.dart';
import 'package:api_integration/main.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<Meme> favoriteMemes = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadFavorites();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadFavorites();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      isLoading = true;
    });

    try {
      final favorites = await FavoritesService.getFavorites();
      if (!mounted) return;

      setState(() {
        favoriteMemes = favorites;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavorites(Meme meme) async {
    final success = await FavoritesService.removeFromFavorites(meme);
    if (success && mounted) {
      setState(() {
        favoriteMemes.removeWhere((m) => m.url == meme.url);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites 💔'),
          backgroundColor: Color(0xFF9C27B0),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearAllFavorites() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Favorites'),
            content: const Text(
              'Are you sure you want to remove all your favorite memes? This action cannot be undone.',
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
                child: const Text('Clear All'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await FavoritesService.clearFavorites();
      if (success && mounted) {
        setState(() {
          favoriteMemes.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All favorites cleared 💔'),
            backgroundColor: Color(0xFFFF5722),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF5722).withAlpha(8),
              const Color(0xFFE91E63).withAlpha(6),
              const Color(0xFF9C27B0).withAlpha(4),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Column(
          children: [
            _buildAnimatedAppBar(colorScheme),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFavorites,
                backgroundColor: colorScheme.surface,
                color: colorScheme.primary,
                child: _buildBody(colorScheme),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          favoriteMemes.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: _clearAllFavorites,
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text("Clear All"),
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                elevation: 12,
              )
              : null,
    );
  }

  Widget _buildAnimatedAppBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF5722).withAlpha(32),
            const Color(0xFFE91E63).withAlpha(24),
            const Color(0xFF9C27B0).withAlpha(16),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5722).withAlpha(40),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5722), Color(0xFFE91E63)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withAlpha(64),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5722), Color(0xFFE91E63)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "My Favorites",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        foreground:
                            Paint()
                              ..shader = const LinearGradient(
                                colors: [Color(0xFFFF5722), Color(0xFFE91E63)],
                              ).createShader(
                                const Rect.fromLTWH(0, 0, 150, 60),
                              ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${favoriteMemes.length} saved memes",
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(112),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (favoriteMemes.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE91E63).withAlpha(48),
                        const Color(0xFF9C27B0).withAlpha(48),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    padding: const EdgeInsets.all(8),
                    icon: Icon(
                      Icons.delete_sweep_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: _clearAllFavorites,
                    tooltip: 'Clear all favorites',
                  ),
                ),
            ],
          ),
        ),
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
                    const Color(0xFFFF5722).withAlpha(32),
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
                    const Color(0xFFFF5722).withAlpha(32),
                    const Color(0xFFE91E63).withAlpha(32),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                '❤️ Loading your favorites...',
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

    if (favoriteMemes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF5722).withAlpha(32),
                      const Color(0xFFE91E63).withAlpha(16),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 80,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "No favorites yet",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Start exploring memes and tap the heart icon to add them to your favorites!",
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5722), Color(0xFFE91E63)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withAlpha(80),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text("Explore Memes"),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
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
                final meme = favoriteMemes[index];
                return MemeCard(
                  title: meme.title ?? '',
                  imageUrl: meme.url ?? '',
                  ups: meme.ups ?? 0,
                  postLink: meme.postLink ?? '',
                  index: index,
                  subreddit: meme.subreddit ?? '',
                  onAddToFavorites: (_) {
                    // Already in favorites, so remove it
                    _removeFromFavorites(meme);
                  },
                );
              }, childCount: favoriteMemes.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
