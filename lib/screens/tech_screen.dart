import 'package:flutter/material.dart';
import 'package:api_integration/services/news_service.dart';
import 'package:provider/provider.dart';
import 'package:api_integration/widgets/news_card.dart';
// TODO: Implement or import FullPageNewsScreen if needed
// import 'package:api_integration/screens/full_page_news_screen.dart';

class TechScreen extends StatefulWidget {
  final Function(VoidCallback)? onRefreshCallback;

  const TechScreen({super.key, this.onRefreshCallback});

  @override
  State<TechScreen> createState() => _TechScreenState();
}

class _TechScreenState extends State<TechScreen> {
  late TechNewsController newsController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    newsController = TechNewsController(context: context);
    newsController.fetchInitialNews();
    _scrollController.addListener(_onScroll);

    // Register refresh callback
    widget.onRefreshCallback?.call(refreshNews);
  }

  void refreshNews() {
    newsController.fetchInitialNews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    newsController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      if (!newsController.isLoadingMore && newsController.newsAfter != null) {
        newsController.fetchMoreNews();
      }
    }
  }

  void _navigateToFullPage() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              body: Center(child: Text('Full Page News Coming Soon')),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ChangeNotifierProvider.value(
      value: newsController,
      child: Consumer<TechNewsController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.isError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load news.',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: controller.fetchInitialNews,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              // Header Section with View Toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outline.withAlpha(204),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.newspaper_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Latest News',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Full Page Mode Button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: colorScheme.primary.withAlpha(30),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _navigateToFullPage,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fullscreen_rounded,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Full Page',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          onPressed: controller.fetchInitialNews,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // News Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    controller.fetchInitialNews();
                  },
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Stats
                          Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary.withAlpha(30),
                                  colorScheme.secondary.withAlpha(30),
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  icon: Icons.newspaper_rounded,
                                  label: 'Articles',
                                  value: '${controller.news.length}',
                                  color: colorScheme.primary,
                                ),
                                _buildStatItem(
                                  icon: Icons.source_rounded,
                                  label: 'Sources',
                                  value: '4',
                                  color: colorScheme.secondary,
                                ),
                                _buildStatItem(
                                  icon: Icons.trending_up_rounded,
                                  label: 'Trending',
                                  value:
                                      '${controller.news.where((n) => n.ups > 100).length}',
                                  color: colorScheme.tertiary,
                                ),
                              ],
                            ),
                          ),
                          // News Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  childAspectRatio: 0.75,
                                  mainAxisSpacing: 20,
                                ),
                            itemCount:
                                controller.news.length +
                                (controller.isLoadingMore ||
                                        controller.newsAfter != null
                                    ? 1
                                    : 0),
                            itemBuilder: (context, index) {
                              if (index < controller.news.length) {
                                final news = controller.news[index];
                                return NewsCard(
                                  title: news.title,
                                  imageUrl: news.url,
                                  ups: news.ups,
                                  postLink: news.postLink,
                                  subreddit: news.subreddit,
                                );
                              } else {
                                // Loading indicator at the end
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: colorScheme.surfaceContainer,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      height: 40,
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(60),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withAlpha(170)),
        ),
      ],
    );
  }
}
