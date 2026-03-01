import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme.dart';
import '../../../widgets/common/shimmer_loading.dart';

/// Latest news section — news articles from Yahoo Finance.
class LatestNewsWidget extends StatelessWidget {
  const LatestNewsWidget({
    super.key,
    required this.news,
    this.isLoading = false,
  });

  final List<Map<String, dynamic>> news;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.newspaper_outlined, size: 18, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Latest News',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const ShimmerStockList(itemCount: 3)
        else if (news.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('No news available', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.38))),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: news.length > 5 ? 5 : news.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 16, endIndent: 16, color: appColors.surfaceHover),
            itemBuilder: (context, index) {
              final article = news[index];
              return _NewsItem(
                title: article['title'] as String? ?? '',
                source: article['source'] as String? ?? '',
                timeAgo: article['timeAgo'] as String? ?? '',
                thumbnailUrl: article['thumbnailUrl'] as String?,
                url: article['url'] as String?,
              );
            },
          ),
      ],
    );
  }
}

class _NewsItem extends StatelessWidget {
  const _NewsItem({
    required this.title,
    required this.source,
    required this.timeAgo,
    this.thumbnailUrl,
    this.url,
  });

  final String title;
  final String source;
  final String timeAgo;
  final String? thumbnailUrl;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: () {
        if (url != null) {
          launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.article_outlined, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.38)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$source · $timeAgo',
                    style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                  ),
                ],
              ),
            ),
            if (thumbnailUrl != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 48,
                  color: appColors.surfaceHover,
                  child: Image.network(
                    thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image_outlined,
                      color: colorScheme.onSurface.withValues(alpha: 0.38),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
