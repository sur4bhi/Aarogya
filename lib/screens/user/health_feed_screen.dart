import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/health_content_model.dart';
import '../../providers/health_feed_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user/health_article_card.dart';
import '../../core/constants.dart';
import '../../l10n/app_localizations.dart';

class HealthFeedScreen extends StatefulWidget {
  const HealthFeedScreen({super.key});

  @override
  State<HealthFeedScreen> createState() => _HealthFeedScreenState();
}

class _HealthFeedScreenState extends State<HealthFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  Future<void> _initializeProvider() async {
    final user = context.read<UserProvider>().currentUser;
    await context.read<HealthFeedProvider>().initialize(user: user);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: _isSearching ? _buildSearchAppBar() : _buildMainAppBar(l10n),
      body: Consumer<HealthFeedProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return _buildErrorState(provider.error!);
          }

          return Column(
            children: [
              _buildFilterSection(provider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllContent(provider),
                    _buildRecommendedContent(provider),
                    _buildPopularContent(provider),
                    _buildBookmarkedContent(provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildMainAppBar(AppLocalizations? l10n) {
    return AppBar(
      title: Text(l10n?.healthFeed ?? 'Health Feed'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearching = true),
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterBottomSheet,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: [
          Tab(text: l10n?.seeAll ?? 'All'),
          const Tab(text: 'For You'),
          const Tab(text: 'Popular'),
          const Tab(text: 'Bookmarked'),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() => _isSearching = false);
          _searchController.clear();
          context.read<HealthFeedProvider>().setSearchQuery('');
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search health content...',
          border: InputBorder.none,
        ),
        onChanged: (query) {
          context.read<HealthFeedProvider>().setSearchQuery(query);
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            context.read<HealthFeedProvider>().setSearchQuery('');
          },
        ),
      ],
    );
  }

  Widget _buildFilterSection(HealthFeedProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        children: [
          // Category filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.availableCategories.length,
              itemBuilder: (context, index) {
                final category = provider.availableCategories[index];
                final isSelected = provider.selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getCategoryDisplayName(category)),
                    selected: isSelected,
                    onSelected: (selected) {
                      provider.setCategory(category);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: AppColors.primary.withOpacity(0.2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Content type filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.availableTypes.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All Types'),
                      selected: provider.selectedType == null,
                      onSelected: (selected) {
                        provider.setContentType(null);
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppColors.primary.withOpacity(0.2),
                    ),
                  );
                }
                final type = provider.availableTypes[index - 1];
                final isSelected = provider.selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Text(type.icon),
                    label: Text(type.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      provider.setContentType(selected ? type : null);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: AppColors.primary.withOpacity(0.2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllContent(HealthFeedProvider provider) {
    final content = _isSearching ? provider.filteredContent : provider.filteredContent;
    return _buildContentList(content, provider);
  }

  Widget _buildRecommendedContent(HealthFeedProvider provider) {
    final content = provider.recommendedContent;
    return _buildContentList(content, provider);
  }

  Widget _buildPopularContent(HealthFeedProvider provider) {
    final content = provider.popularContent;
    return _buildContentList(content, provider);
  }

  Widget _buildBookmarkedContent(HealthFeedProvider provider) {
    final content = provider.bookmarkedContent;
    return _buildContentList(content, provider);
  }

  Widget _buildContentList(List<HealthContentModel> content, HealthFeedProvider provider) {
    if (content.isEmpty) {
      return _buildEmptyState();
    }

    final languageCode = context.watch<LanguageProvider>().languageCode;
    
    return RefreshIndicator(
      onRefresh: () => provider.refreshContent(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: content.length,
        itemBuilder: (context, index) {
          final item = content[index];
          return HealthArticleCard(
            content: item,
            languageCode: languageCode,
            isBookmarked: provider.isBookmarked(item.id),
            onTap: () => _openContentDetail(item),
            onBookmark: () => provider.toggleBookmark(item.id),
            onLike: () => provider.likeContent(item.id),
            onShare: () => _shareContent(item),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No content available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters or check back later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _initializeProvider(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Consumer<HealthFeedProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Content',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      provider.clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ContentSortBy.values.map((sortBy) {
                  return ChoiceChip(
                    label: Text(sortBy.displayName),
                    selected: provider.sortBy == sortBy,
                    onSelected: (selected) {
                      if (selected) provider.setSortBy(sortBy);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply Filters'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _openContentDetail(HealthContentModel content) {
    // Mark as read
    context.read<HealthFeedProvider>().markAsRead(content.id);
    
    // Navigate to content detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ContentDetailScreen(content: content),
      ),
    );
  }

  void _shareContent(HealthContentModel content) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: ${content.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return 'All';
      case 'diabetes':
        return 'Diabetes';
      case 'hypertension':
        return 'Blood Pressure';
      case 'heart_health':
        return 'Heart';
      case 'nutrition':
        return 'Nutrition';
      case 'exercise':
        return 'Exercise';
      case 'mental_health':
        return 'Mental Health';
      case 'medication':
        return 'Medication';
      case 'prevention':
        return 'Prevention';
      default:
        return category;
    }
  }
}

// Content Detail Screen
class _ContentDetailScreen extends StatelessWidget {
  final HealthContentModel content;

  const _ContentDetailScreen({required this.content});

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<LanguageProvider>().languageCode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(content.getLocalizedTitle(languageCode)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareContent(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image
            if (content.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    content.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 48),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Title
            Text(
              content.getLocalizedTitle(languageCode),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            // Metadata
            Row(
              children: [
                Text(
                  'By ${content.author}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  content.readTime,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    content.categoryDisplayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Description
            Text(
              content.getLocalizedDescription(languageCode),
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            // Content
            Text(
              content.getLocalizedContent(languageCode),
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareContent(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: ${content.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
