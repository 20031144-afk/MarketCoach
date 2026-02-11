import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/news_item.dart';
import '../../widgets/glass_card.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  Color _sentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'bullish':
        return const Color(0xFF0C9E6A);
      case 'bearish':
        return const Color(0xFFCF3B2E);
      default:
        return const Color(0xFF4D5BD6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market news',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Curated headlines with quick sentiment labels.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList.builder(
              itemCount: mockNews.length,
              itemBuilder: (context, index) {
                final NewsItem item = mockNews[index];
                final sentimentColor = _sentimentColor(item.sentiment);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(
                            children: [
                              Text(
                                item.source,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.timeAgo,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: ShapeDecoration(
                                  color: sentimentColor.withOpacity(0.12),
                                  shape: const StadiumBorder(),
                                ),
                                child: Text(
                                  item.sentiment,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: sentimentColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.summary,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ],
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
