import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/health_tips_provider.dart';
import '../services/health_tips_service.dart';
import '../services/auth_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:ui';

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _favKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();
  Timer? _debounce;
  bool _shouldShowMainTutorial = false;
  bool _shouldShowBottomSheetTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shouldShowMainTutorial = !(prefs.getBool('hasShownHealthTipsMainTutorial') ?? false);
      _shouldShowBottomSheetTutorial = !(prefs.getBool('hasShownHealthTipsSheetTutorial') ?? false);
    });
  }

  Future<void> _markTutorialShown(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ShowCaseWidget(
      builder: (context) {
        final provider = Provider.of<HealthTipsProvider>(context);
        if (_shouldShowMainTutorial && provider.state == HealthTipsState.loaded && provider.tips.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ShowCaseWidget.of(context).startShowCase([_searchKey, _cardKey]);
            _markTutorialShown('hasShownHealthTipsMainTutorial');
            setState(() => _shouldShowMainTutorial = false);
          });
        }

        return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A192F) : Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Consumer<HealthTipsProvider>(
              builder: (context, provider, child) {
                switch (provider.state) {
                  case HealthTipsState.loading:
                    return _buildShimmerSkeleton();
                  case HealthTipsState.error:
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 140.0, left: 24.0, right: 24.0, bottom: 24.0),
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
                      child: Padding(
                        padding: EdgeInsets.only(top: 140.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No health tips found for that keyword.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  case HealthTipsState.loaded:
                  case HealthTipsState.initial:
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 230, left: 16, right: 16, bottom: 16),
                        child: Column(
                          children: [
                            StaggeredGrid.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              children: List.generate(provider.tips.length, (index) {
                                final tip = provider.tips[index];
                                final color = _cardColors[index % _cardColors.length];
                                
                                final isFeatured = index % 3 == 0;
                                
                                final cardWidget = isFeatured
                                    ? _buildFeaturedTipCard(tip, color)
                                    : _buildGridTipCard(tip, color);

                                Widget wrappedCard = cardWidget;
                                if (index == 0) {
                                  wrappedCard = Showcase(
                                    key: _cardKey,
                                    title: 'Read & Save',
                                    description: 'Tap any card to read the full article, or tap the heart to save it offline.',
                                    tooltipBackgroundColor: const Color(0xFFFFA726),
                                    textColor: Colors.white,
                                    titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                    descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
                                    tooltipBorderRadius: BorderRadius.circular(12),
                                    child: cardWidget,
                                  );
                                }

                                return StaggeredGridTile.count(
                                  crossAxisCellCount: isFeatured ? 2 : 1,
                                  mainAxisCellCount: isFeatured ? 1.5 : 1,
                                  child: wrappedCard,
                                );
                              }),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0),
                              child: InkWell(
                                onTap: () => launchUrl(Uri.parse('https://health.gov')),
                                child: const Text(
                                  'Source: MyHealthfinder (health.gov)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                }
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: isDark ? const Color(0xFF0A192F).withOpacity(0.95) : Colors.white.withOpacity(0.95),
              child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              Text(
                                'Health Tips',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
                          child: Showcase(
                            key: _searchKey,
                            title: 'Search Tips',
                            description: 'Type here to find specific health advice or keywords.',
                            tooltipBackgroundColor: const Color(0xFF1A73E8),
                            textColor: Colors.white,
                            titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                            descTextStyle: TextStyle(fontSize: 14, color: Colors.white70),
                            tooltipBorderRadius: BorderRadius.circular(12),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              onSubmitted: (_) => _onSearchSubmitted(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                hintText: 'Search health tips...',
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchSubmitted();
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      _buildTagChips(context),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildTagChips(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HealthTipsProvider>();
    final authService = context.watch<AuthService>();
    final userInterests = authService.currentUser?.interests;
    
    List<String> dynamicTags = ['Fitness', 'Nutrition', 'Sleep', 'Mental Health'];
    if (userInterests != null && userInterests.isNotEmpty) {
      dynamicTags = userInterests;
    }
    
    final tags = ['Favorites', 'Recent', 'Trending', ...dynamicTags];
    
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
              showCheckmark: false,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
              selectedColor: isDark ? const Color(0xFF1A73E8) : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
                side: BorderSide.none,
              ),
              onSelected: (selected) {
                if (selected) {
                  _searchController.clear();
                  provider.fetchTipsByTag(tag);
                }
              },
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[800]),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 230, left: 16, right: 16, bottom: 16),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: List.generate(6, (index) {
          final isFeatured = index % 3 == 0;
          
          return StaggeredGridTile.count(
            crossAxisCellCount: isFeatured ? 2 : 1,
            mainAxisCellCount: isFeatured ? 1.5 : 1,
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        }),
      ),
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
          builder: (context, scrollController) {
          // Trigger showcase for the buttons inside the bottom sheet ONLY once
          if (_shouldShowBottomSheetTutorial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ShowCaseWidget.of(context).startShowCase([_favKey, _shareKey]);
              _markTutorialShown('hasShownHealthTipsSheetTutorial');
              setState(() => _shouldShowBottomSheetTutorial = false);
            });
          }
          
          return Stack(
            children: [
              Column(
                children: [
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tip.imageUrl != null && tip.imageUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: tip.imageUrl!,
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 240,
                          color: color.withOpacity(0.1),
                          child: Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const SizedBox(),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              tip.description.toUpperCase(),
                              style: TextStyle(color: color.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tip.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 24),
                          tip.content.isNotEmpty
                              ? HtmlWidget(
                                  tip.content,
                                  textStyle: TextStyle(
                                    fontSize: 17,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[850],
                                    height: 1.7,
                                  ),
                                )
                              : Text(
                                  'Follow this health tip to improve your overall wellness and maintain a healthy lifestyle.',
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[850],
                                    height: 1.7,
                                  ),
                                ),
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => launchUrl(Uri.parse('https://health.gov')),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Data Source:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'MyHealthfinder API (health.gov)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: color,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Information provided by the Office of Disease Prevention and Health Promotion, U.S. Department of Health and Human Services.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40),
                        ],
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
                        return Showcase(
                          key: _favKey,
                          title: 'Save Offline',
                          description: 'Tap the heart to save this article to your Favorites for offline reading.',
                          tooltipBackgroundColor: Colors.redAccent,
                          textColor: Colors.white,
                          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                          descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
                          tooltipBorderRadius: BorderRadius.circular(12),
                          child: IconButton(
                            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                            color: Colors.redAccent,
                            iconSize: 28,
                            onPressed: () {
                              provider.toggleFavorite(tip);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isFav ? 'Removed from Favorites' : 'Saved to Favorites!')),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    Showcase(
                      key: _shareKey,
                      title: 'Spread the Word',
                      description: 'Share this helpful health tip with your friends and family.',
                      tooltipBackgroundColor: Colors.blueAccent,
                      textColor: Colors.white,
                      titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
                      tooltipBorderRadius: BorderRadius.circular(12),
                      child: IconButton(
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
                    ),
                  ],
                ),
              ),
            ),
                ],
              ),
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: (tip.imageUrl != null && tip.imageUrl!.isNotEmpty) 
                          ? Colors.white.withOpacity(0.8) 
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
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

  Widget _buildFeaturedTipCard(HealthTip tip, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20.0,
            offset: const Offset(0, 8.0),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
        onTap: () => _showTipDetail(tip, color),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (tip.imageUrl != null && tip.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: tip.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: color.withOpacity(0.1)),
                errorWidget: (context, url, error) => _buildImageFallback(color),
              )
            else
              _buildImageFallback(color),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF0A2A3F).withOpacity(0.9) : Colors.white.withOpacity(0.9)),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        tip.description,
                        style: TextStyle(color: color.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildGridTipCard(HealthTip tip, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20.0,
            offset: const Offset(0, 8.0),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
        onTap: () => _showTipDetail(tip, color),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (tip.imageUrl != null && tip.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: tip.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: color.withOpacity(0.1)),
                errorWidget: (context, url, error) => _buildImageFallback(color),
              )
            else
              _buildImageFallback(color),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF0A2A3F).withOpacity(0.9) : Colors.white.withOpacity(0.9)),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        tip.description,
                        style: TextStyle(color: color.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildImageFallback(Color color) {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
      child: Center(
        child: Icon(
          Icons.health_and_safety_outlined,
          color: color.withOpacity(0.5),
          size: 40,
        ),
      ),
    );
  }
}
