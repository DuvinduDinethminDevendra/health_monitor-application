import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:showcaseview/showcaseview.dart';
import '../providers/health_tips_provider.dart';
import '../services/health_tips_service.dart';

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _cardKey = GlobalKey();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<HealthTipsProvider>().refreshCurrentList();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<HealthTipsProvider>().searchTips(query);
    });
  }

  void _onSearchSubmitted() {
    _debounce?.cancel();
    context.read<HealthTipsProvider>().searchTips(_searchController.text);
  }

  final List<Color> _cardColors = const [
    Color(0xFF1A73E8),
    Color(0xFF00BFA5),
    Color(0xFFFB8C00),
    Color(0xFFE53935),
    Color(0xFFAB47BC),
    Color(0xFF42A5F5),
    Color(0xFF26A69A),
    Color(0xFFFFA726),
  ];

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) {
        // Trigger the showcase automatically after the first frame
        // if the tips are loaded and we haven't shown it yet.
        final provider = Provider.of<HealthTipsProvider>(context);
        if (provider.state == HealthTipsState.loaded && provider.tips.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ShowCaseWidget.of(context).startShowCase([_cardKey]);
          });
        }

        return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tips'),
        backgroundColor: const Color(0xFFFFA726),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _onSearchSubmitted(),
              decoration: InputDecoration(
                hintText: 'Search health tips...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchSubmitted();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          _buildTagChips(context),
          Expanded(
            child: Consumer<HealthTipsProvider>(
              builder: (context, provider, child) {
                switch (provider.state) {
                  case HealthTipsState.loading:
                    return _buildShimmerSkeleton();
                  case HealthTipsState.error:
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                            const SizedBox(height: 16),
                            Text(
                              provider.errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: provider.loadFallbackTips,
                              icon: const Icon(Icons.offline_bolt),
                              label: const Text('Load Offline Tips'),
                            ),
                          ],
                        ),
                      ),
                    );
                  case HealthTipsState.empty:
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No health tips found for that keyword.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    );
                  case HealthTipsState.loaded:
                  case HealthTipsState.initial:
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.tips.length,
                        itemBuilder: (context, index) {
                          final tip = provider.tips[index];
                          final color = _cardColors[index % _cardColors.length];

                          final cardWidget = Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showTipDetail(tip, color),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: tip.imageUrl != null && tip.imageUrl!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: tip.imageUrl!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: color.withOpacity(0.1),
                                                ),
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(color),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => _buildImageFallback(color),
                                            )
                                          : _buildImageFallback(color),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              tip.description,
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            tip.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );

                          if (index == 0) {
                            return Showcase(
                              key: _cardKey,
                              title: 'Read & Save',
                              description: 'Tap any card to read the full article, or tap the heart to save it offline.',
                              child: cardWidget,
                            );
                          }
                          return cardWidget;
                        },
                      ),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildTagChips(BuildContext context) {
    final provider = context.watch<HealthTipsProvider>();
    final tags = ['Favorites', 'Recent', 'Trending', 'Fitness', 'Nutrition', 'Sleep', 'Mental Health'];
    
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final isSelected = provider.selectedTag == tag;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _searchController.clear();
                  provider.fetchTipsByTag(tag);
                }
              },
              selectedColor: const Color(0xFFFFA726).withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFE65100) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTipDetail(HealthTip tip, Color color) {
    context.read<HealthTipsProvider>().markAsRecent(tip);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tip.description,
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tip.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    tip.content.isNotEmpty
                        ? HtmlWidget(
                            tip.content,
                            textStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              height: 1.6,
                            ),
                          )
                        : Text(
                            'Follow this health tip to improve your overall wellness and maintain a healthy lifestyle.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Consumer<HealthTipsProvider>(
                      builder: (context, provider, child) {
                        final isFav = provider.isFavorite(tip.id);
                        return IconButton(
                          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                          color: Colors.redAccent,
                          iconSize: 28,
                          onPressed: () {
                            provider.toggleFavorite(tip);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isFav ? 'Removed from Favorites' : 'Saved to Favorites!')),
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      color: Colors.blueAccent,
                      iconSize: 28,
                      onPressed: () {
                        final String shareText = 
                          'Check out this health tip: ${tip.title}\n\n'
                          '${tip.description}\n\n'
                          'Read more at: ${tip.url.isNotEmpty ? tip.url : "https://health.gov"}';
                        
                        Share.share(shareText, subject: 'Health Tip: ${tip.title}');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback(Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
      ),
      child: Icon(
        Icons.health_and_safety_outlined,
        color: color.withOpacity(0.5),
        size: 30,
      ),
    );
  }
}
