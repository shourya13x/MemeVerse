import 'package:api_integration/main.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:api_integration/models/meme_model.dart';
import 'package:api_integration/services/favorites_service.dart';
import 'package:api_integration/screens/favorites_screen.dart';
import 'package:share_plus/share_plus.dart';

class MemeCard extends StatefulWidget {
  final String title;
  final String imageUrl;
  final int ups;
  final String postLink;
  final int index;
  final String subreddit;
  final Function(Meme)? onAddToFavorites;

  const MemeCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.ups,
    required this.postLink,
    required this.index,
    required this.subreddit,
    this.onAddToFavorites,
  });

  @override
  State<MemeCard> createState() => _MemeCardState();
}

class _MemeCardState extends State<MemeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800 + (widget.index * 100)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final meme = Meme(
      title: widget.title,
      url: widget.imageUrl,
      ups: widget.ups,
      postLink: widget.postLink,
      subreddit: widget.subreddit,
    );

    final isFavorite = await FavoritesService.isFavorite(meme);
    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;

    print('Toggling favorite for: ${widget.title}');
    print('Current favorite status: $_isFavorite');

    setState(() {
      _isLoadingFavorite = true;
    });

    final meme = Meme(
      title: widget.title,
      url: widget.imageUrl,
      ups: widget.ups,
      postLink: widget.postLink,
      subreddit: widget.subreddit,
    );

    bool success = false;
    if (_isFavorite) {
      // Remove from favorites
      print('Removing from favorites...');
      success = await FavoritesService.removeFromFavorites(meme);
      print('Remove result: $success');
      if (success && mounted) {
        setState(() {
          _isFavorite = false;
        });

        // Show feedback
        if (mounted) {
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
    } else {
      // Add to favorites
      print('Adding to favorites...');
      success = await FavoritesService.addToFavorites(meme);
      print('Add result: $success');
      if (success && mounted) {
        setState(() {
          _isFavorite = true;
        });

        // Show feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('❤️ Added to favorites!'),
              backgroundColor: const Color(0xFFE91E63),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'View Favorites',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to favorites screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FavoritesScreen(),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    }

    // Call the parent callback if provided and operation was successful
    if (success && widget.onAddToFavorites != null) {
      print('Calling parent callback...');
      widget.onAddToFavorites!(meme);
    }

    if (mounted) {
      setState(() {
        _isLoadingFavorite = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isHovered ? 1.02 : _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade400, Colors.green.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withAlpha(18),
                      blurRadius: _isHovered ? 30 : 20,
                      offset: Offset(0, _isHovered ? 15 : 10),
                      spreadRadius: _isHovered ? 3 : 0,
                    ),
                    BoxShadow(
                      color: Colors.green.withAlpha(14),
                      blurRadius: _isHovered ? 25 : 15,
                      offset: Offset(0, _isHovered ? 10 : 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showMemeDetails(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Section with Gradient Overlay
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                // Background Image
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF6C5CE7).withAlpha(16),
                                        const Color(0xFF00B4D8).withAlpha(16),
                                      ],
                                    ),
                                  ),
                                  child: Hero(
                                    tag: 'meme_${widget.imageUrl}',
                                    child: CachedNetworkImage(
                                      imageUrl: getImageUrl(widget.imageUrl),
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(
                                                    0xFF6C5CE7,
                                                  ).withAlpha(16),
                                                  const Color(
                                                    0xFF00B4D8,
                                                  ).withAlpha(16),
                                                ],
                                              ),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const RadialGradient(
                                                            colors: [
                                                              Color(0xFF6C5CE7),
                                                              Color(0xFF8B5CF6),
                                                            ],
                                                          ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const CircularProgressIndicator(
                                                      strokeWidth: 3,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          const Color(
                                                            0xFF6C5CE7,
                                                          ).withAlpha(32),
                                                          const Color(
                                                            0xFF00B4D8,
                                                          ).withAlpha(32),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Loading meme...',
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                            color: const Color(
                                                              0xFF6C5CE7,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.red.withAlpha(16),
                                                  Colors.orange.withAlpha(16),
                                                ],
                                              ),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const RadialGradient(
                                                            colors: [
                                                              Colors.red,
                                                              Colors.orange,
                                                            ],
                                                          ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      size: 32,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Failed to load image',
                                                    style: textTheme.bodySmall
                                                        ?.copyWith(
                                                          color: Colors.red,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                ),

                                // Gradient Overlay
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withAlpha(16),
                                        ],
                                        stops: const [0.7, 1.0],
                                      ),
                                    ),
                                  ),
                                ),

                                // Floating Action Button
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    decoration:
                                        _isFavorite
                                            ? BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFFF5722),
                                                  Color(0xFFE91E63),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFFFF5722,
                                                  ).withAlpha(64),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            )
                                            : const BoxDecoration(
                                              color: Colors.transparent,
                                            ),
                                    child: IconButton(
                                      icon:
                                          _isLoadingFavorite
                                              ? SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                              : Icon(
                                                _isFavorite
                                                    ? Icons.favorite_rounded
                                                    : Icons
                                                        .favorite_border_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                      onPressed:
                                          _isLoadingFavorite
                                              ? null
                                              : () {
                                                if (widget.onAddToFavorites !=
                                                    null) {
                                                  _toggleFavorite();
                                                } else {
                                                  _toggleFavorite();
                                                }
                                              },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Content Section
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShaderMask(
                                      shaderCallback:
                                          (bounds) => const LinearGradient(
                                            colors: [
                                              Color(0xFF6C5CE7),
                                              Color(0xFF00B4D8),
                                            ],
                                          ).createShader(bounds),
                                      child: Text(
                                        widget.title,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.3,
                                          fontSize: 15,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Flexible(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Upvotes with animated container
                                          Flexible(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade600,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.blue.shade600
                                                        .withAlpha(48),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.arrow_upward_rounded,
                                                    size: 18,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _formatNumber(widget.ups),
                                                    style: textTheme.labelLarge
                                                        ?.copyWith(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // View Post Button with glassmorphism
                                          Flexible(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade600,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green.shade600
                                                        .withAlpha(48),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap:
                                                      () => _showMemeDetails(
                                                        context,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 12,
                                                        ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .open_in_new_rounded,
                                                          size: 18,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          'View',
                                                          style: textTheme
                                                              .labelLarge
                                                              ?.copyWith(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Share Button
                                          Flexible(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.purple.shade600,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors
                                                        .purple
                                                        .shade600
                                                        .withAlpha(48),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () async {
                                                    // Share meme using share_plus
                                                    final shareText =
                                                        '${widget.title}\n${widget.imageUrl}';
                                                    await Share.share(
                                                      shareText,
                                                    );
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 12,
                                                        ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.share_rounded,
                                                          size: 18,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          'Share',
                                                          style: textTheme
                                                              .labelLarge
                                                              ?.copyWith(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _showMemeDetails(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              appBar: AppBar(
                title: Text(
                  'Meme Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Hero(
                        tag: 'meme_${widget.imageUrl}',
                        child: CachedNetworkImage(
                          imageUrl: getImageUrl(widget.imageUrl),
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  size: 64,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      widget.title,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatNumber(widget.ups)} upvotes',
                            style: textTheme.titleMedium?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Link Section
                    Text(
                      'Original Post Link',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withAlpha(32),
                        ),
                      ),
                      child: SelectableText(
                        widget.postLink,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          // TODO: Add functionality to open link in browser
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Link copied to clipboard!'),
                              backgroundColor:
                                  Theme.of(context).colorScheme.inverseSurface,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy Link'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      ),
    );
  }
}
