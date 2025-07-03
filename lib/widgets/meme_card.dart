import 'package:api_integration/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:api_integration/models/meme_model.dart';
import 'package:api_integration/services/favorites_service.dart';
import 'package:api_integration/screens/favorites_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';

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

  // Add like/dislike state
  int _likes = 0;
  int _dislikes = 0;
  bool _hasLiked = false;
  bool _hasDisliked = false;

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
    _initializeLikesData();
  }

  void _initializeLikesData() {
    // Initialize with some base values derived from ups
    _likes = (widget.ups * 0.85).round(); // 85% of ups as likes
    _dislikes = (widget.ups * 0.15).round(); // 15% of ups as dislikes
  }

  void _toggleLike() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_hasLiked) {
        // Remove like
        _hasLiked = false;
        _likes--;
      } else {
        // Add like and remove dislike if present
        _hasLiked = true;
        _likes++;
        if (_hasDisliked) {
          _hasDisliked = false;
          _dislikes--;
        }
      }
    });
  }

  void _toggleDislike() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_hasDisliked) {
        // Remove dislike
        _hasDisliked = false;
        _dislikes--;
      } else {
        // Add dislike and remove like if present
        _hasDisliked = true;
        _dislikes++;
        if (_hasLiked) {
          _hasLiked = false;
          _likes--;
        }
      }
    });
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
    HapticFeedback.lightImpact();
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
      print('Removing from favorites...');
      success = await FavoritesService.removeFromFavorites(meme);
      print('Remove result: $success');
      if (success && mounted) {
        setState(() {
          _isFavorite = false;
        });
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
      print('Adding to favorites...');
      success = await FavoritesService.addToFavorites(meme);
      print('Add result: $success');
      if (success && mounted) {
        setState(() {
          _isFavorite = true;
        });
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
        return Builder(
          builder: (scaffoldContext) {
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
                      color: Theme.of(context).colorScheme.surface,
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
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _showMemeDetails(context);
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min, // Card hugs content
                            children: [
                              // Image Section with True Adaptive Sizing
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                                child: Hero(
                                  tag: 'meme_${widget.imageUrl}',
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: AdaptiveImage(
                                          imageUrl: widget.imageUrl,
                                        ),
                                      ),
                                      // Optional: subtle gradient overlay for effect
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(
                                                  0.08,
                                                ), // subtle fade at bottom
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            style: textTheme.titleMedium
                                                ?.copyWith(
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
                                              // Like Button
                                              GestureDetector(
                                                onTap: _toggleLike,
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _hasLiked
                                                            ? Colors
                                                                .green
                                                                .shade600
                                                            : Colors
                                                                .grey
                                                                .shade600,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: (_hasLiked
                                                                ? Colors
                                                                    .green
                                                                    .shade600
                                                                : Colors
                                                                    .grey
                                                                    .shade600)
                                                            .withAlpha(48),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        _hasLiked
                                                            ? Icons
                                                                .thumb_up_rounded
                                                            : Icons
                                                                .thumb_up_outlined,
                                                        size: 16,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _formatNumber(_likes),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // Dislike Button
                                              GestureDetector(
                                                onTap: _toggleDislike,
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _hasDisliked
                                                            ? Colors
                                                                .red
                                                                .shade600
                                                            : Colors
                                                                .grey
                                                                .shade600,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: (_hasDisliked
                                                                ? Colors
                                                                    .red
                                                                    .shade600
                                                                : Colors
                                                                    .grey
                                                                    .shade600)
                                                            .withAlpha(48),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        _hasDisliked
                                                            ? Icons
                                                                .thumb_down_rounded
                                                            : Icons
                                                                .thumb_down_outlined,
                                                        size: 16,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _formatNumber(
                                                          _dislikes,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // View Post Button - Compact
                                              GestureDetector(
                                                onTap:
                                                    () => _showMemeDetails(
                                                      context,
                                                    ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade600,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors
                                                            .blue
                                                            .shade600
                                                            .withAlpha(48),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .open_in_new_rounded,
                                                        size: 16,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'View',
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // Share Button - Compact
                                              GestureDetector(
                                                onTap: () async {
                                                  HapticFeedback.lightImpact();
                                                  final shareText =
                                                      '${widget.title}\n${widget.imageUrl}';
                                                  await Share.share(shareText);
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.purple.shade600,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors
                                                            .purple
                                                            .shade600
                                                            .withAlpha(48),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.share_rounded,
                                                        size: 16,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Share',
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                      ),
                                                    ],
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 600),
                    child: Container(
                      width: double.infinity,
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
                              child: Center(
                                child: AdaptiveImage(imageUrl: widget.imageUrl),
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
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
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
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHigh,
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
                                    content: const Text(
                                      'Link copied to clipboard!',
                                    ),
                                    backgroundColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.inverseSurface,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Copy Link'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
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

// Custom widget for adaptive image sizing
class AdaptiveImage extends StatefulWidget {
  final String imageUrl;
  final double? maxHeight;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AdaptiveImage({
    super.key,
    required this.imageUrl,
    this.maxHeight,
    this.fit = BoxFit.fitWidth,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<AdaptiveImage> createState() => _AdaptiveImageState();
}

class _AdaptiveImageState extends State<AdaptiveImage>
    with SingleTickerProviderStateMixin {
  double? _aspectRatio;
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _loadImageInfo();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadImageInfo() async {
    try {
      final image = NetworkImage(getImageUrl(widget.imageUrl));
      final completer = Completer<Size>();

      image
          .resolve(const ImageConfiguration())
          .addListener(
            ImageStreamListener((info, _) {
              if (!completer.isCompleted) {
                if (info.image.width > 0 && info.image.height > 0) {
                  completer.complete(
                    Size(
                      info.image.width.toDouble(),
                      info.image.height.toDouble(),
                    ),
                  );
                } else {
                  completer.complete(const Size(1, 1));
                }
              }
            }),
          );

      final size = await completer.future;
      if (mounted) {
        setState(() {
          _aspectRatio = size.width / size.height;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aspectRatio = 1.0; // Default aspect ratio
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Use a fixed aspect ratio to prevent overflow
      return AspectRatio(
        aspectRatio: 16 / 9, // fallback aspect ratio
        child: Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: RotationTransition(
              turns: _rotationController,
              child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
            ),
          ),
        ),
      );
    }

    if (_hasError) {
      // Use a fixed aspect ratio to prevent overflow
      return AspectRatio(
        aspectRatio: 16 / 9, // fallback aspect ratio
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.withAlpha(16), Colors.orange.withAlpha(16)],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              size: 64,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: widget.maxHeight ?? 400, // Limit maximum height
      ),
      child: AspectRatio(
        aspectRatio: _aspectRatio ?? 1.0,
        child: CachedNetworkImage(
          imageUrl: getImageUrl(widget.imageUrl),
          fit: widget.fit,
          width: double.infinity,
          height: double.infinity,
          placeholder:
              (context, url) =>
                  widget.placeholder ??
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6C5CE7).withAlpha(16),
                          const Color(0xFF00B4D8).withAlpha(16),
                        ],
                      ),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
          errorWidget:
              (context, url, error) =>
                  widget.errorWidget ??
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withAlpha(16),
                          Colors.orange.withAlpha(16),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  ),
        ),
      ),
    );
  }
}
