import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme.dart';
import '../../../providers/stock_provider.dart';
import '../../../services/api_client.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/shimmer_loading.dart';

/// News tab — list of news articles related to this stock.
class NewsTab extends ConsumerStatefulWidget {
  const NewsTab({super.key, required this.symbol});
  final String symbol;

  @override
  ConsumerState<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends ConsumerState<NewsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _refreshNews() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getStockNews(widget.symbol);
      if (response.data['success'] == true) {
        // The stockProvider stores news as List<Map<String, dynamic>>
        // We can rebuild the provider or just trigger a full reload
        ref
            .read(stockProvider(widget.symbol).notifier)
            .loadStock(widget.symbol);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final stockState = ref.watch(stockProvider(widget.symbol));
    final news = stockState.news;
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;

    if (stockState.isLoading && news.isEmpty) {
      return const ShimmerStockList(itemCount: 6);
    }

    if (news.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.article_outlined,
                  size: 48, color: colorScheme.onSurface.withValues(alpha: 0.38)),
              const SizedBox(height: 12),
              Text(
                'No news available',
                style: TextStyle(color: colorScheme.secondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _refreshNews,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNews,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: news.length,
        separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: appColors.surfaceHover),
        itemBuilder: (context, index) {
          final article = news[index];
          final title = article['title'] as String? ?? '';
          final source = article['source'] as String? ?? '';
          final url = article['url'] as String? ?? '';
          final publishedAt = article['publishedAt'] as DateTime?;

          return InkWell(
            onTap: () => _openUrl(url),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.article_outlined,
                        size: 18, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (source.isNotEmpty)
                              Text(
                                source,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.primary),
                              ),
                            if (source.isNotEmpty && publishedAt != null)
                              const SizedBox(width: 8),
                            if (publishedAt != null)
                              Text(
                                timeAgo(publishedAt),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurface.withValues(alpha: 0.38)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (url.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Icon(Icons.open_in_new,
                          size: 14, color: colorScheme.onSurface.withValues(alpha: 0.38)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
