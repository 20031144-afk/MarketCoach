import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/lesson.dart';
import '../../models/lesson_progress.dart';
import '../../providers/lesson_progress_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../utils/auth_helper.dart';
import '../../widgets/glass_card.dart';
import '../lesson_detail/lesson_detail_screen.dart';

enum ProgressFilter { all, completed, inProgress, notStarted, bookmarked }

enum LevelFilter { all, beginner, intermediate, advanced }

// Order mapping for lesson levels
const _levelOrder = {
  'beginner': 0,
  'intermediate': 1,
  'advanced': 2,
};

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  ProgressFilter _progressFilter = ProgressFilter.all;
  LevelFilter _levelFilter = LevelFilter.beginner; // Default to Beginner
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allProgressAsync = ref.watch(allProgressProvider);
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final connectivityAsync = ref.watch(connectivityProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0F1E), // Deep navy
              const Color(0xFF1E293B), // Navy blue
              const Color(0xFF1E3A8A), // Deep blue
              const Color(0xFF1E293B).withOpacity(0.95), // Navy with opacity
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Offline indicator banner
            connectivityAsync.maybeWhen(
              data: (isConnected) {
                if (!isConnected) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.shade700.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Offline - showing cached lessons',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              orElse: () => const SizedBox.shrink(),
            ),
            Expanded(
              child: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lessons')
              .orderBy('published_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            // Build slivers based on snapshot state
            final List<Widget> slivers = [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learn the basics',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Build your market knowledge with bite-sized lessons.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white60,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // AI Coach Card
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('AI Coach coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary.withOpacity(0.2),
                                colorScheme.primary.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colorScheme.primary.withOpacity(0.4),
                                      colorScheme.primary.withOpacity(0.3),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.psychology_rounded,
                                  color: colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ask AI Coach',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Get personalized explanations and guidance',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withOpacity(0.7),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search lessons...',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white38,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 22,
                              color: colorScheme.primary.withOpacity(0.7),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: 20,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFF1A2332).withOpacity(0.7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: colorScheme.primary.withOpacity(0.6),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filter dropdowns
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STATUS',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withOpacity(0.5),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildStatusDropdown(theme, colorScheme),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LEVEL',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withOpacity(0.5),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildLevelDropdown(theme, colorScheme),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ];

            // Add content slivers based on snapshot state
            if (snapshot.hasError) {
              slivers.add(
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.red.withOpacity(0.15),
                            Colors.red.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red.shade300,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading lessons',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.red.shade300,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              slivers.add(
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Loading lessons...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              slivers.add(
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A2332).withOpacity(0.6),
                            const Color(0xFF1A2332).withOpacity(0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.school_outlined,
                              size: 48,
                              color: colorScheme.primary.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No lessons yet',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back soon for new content!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else {
              final lessons = snapshot.data!.docs
                  .map(
                    (doc) => Lesson.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList();

              // Sort lessons: Beginner first, then by published date
              lessons.sort((a, b) {
                final aLevel = _levelOrder[a.level.toLowerCase()] ?? 999;
                final bLevel = _levelOrder[b.level.toLowerCase()] ?? 999;
                if (aLevel != bLevel) return aLevel.compareTo(bLevel);

                // Within same level, sort by published date (newest first)
                if (a.publishedAt != null && b.publishedAt != null) {
                  return b.publishedAt!.compareTo(a.publishedAt!);
                }
                return 0;
              });

              // Filter lessons based on level, search, progress and bookmarks
              final filteredLessons = allProgressAsync.maybeWhen(
                data: (progresses) {
                  return bookmarksAsync.maybeWhen(
                    data: (bookmarks) => _filterLessons(lessons, progresses, bookmarks),
                    orElse: () => _filterLessons(lessons, progresses, []),
                  );
                },
                // Even without progress data, apply level and search filters
                orElse: () => _filterLessons(lessons, [], []),
              );

              if (filteredLessons.isEmpty) {
                slivers.add(
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1A2332).withOpacity(0.6),
                              const Color(0xFF1A2332).withOpacity(0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.filter_list_off,
                                size: 40,
                                color: colorScheme.primary.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No lessons match this filter',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different filter option',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                slivers.add(
                  SliverList.builder(
                    itemCount: filteredLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = filteredLessons[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: allProgressAsync.maybeWhen(
                          data: (progresses) {
                            final progress = progresses
                                .cast<LessonProgress?>()
                                .firstWhere(
                                  (p) => p?.lessonId == lesson.id,
                                  orElse: () => null,
                                );
                            return LessonCard(
                              lesson: lesson,
                              progress: progress,
                            );
                          },
                          orElse: () => LessonCard(lesson: lesson),
                        ),
                      );
                    },
                  ),
                );
              }
            }

            // Add bottom padding
            slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 20)));

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: slivers,
            );
          },
        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProgressFilter>(
          value: _progressFilter,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A2332),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.primary,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          items: [
            _buildDropdownItem('All', ProgressFilter.all, Icons.grid_view_rounded),
            _buildDropdownItem('Bookmarked', ProgressFilter.bookmarked, Icons.bookmark),
            _buildDropdownItem('Completed', ProgressFilter.completed, Icons.check_circle),
            _buildDropdownItem('In Progress', ProgressFilter.inProgress, Icons.pending),
            _buildDropdownItem('Not Started', ProgressFilter.notStarted, Icons.play_circle_outline),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _progressFilter = value);
            }
          },
        ),
      ),
    );
  }

  DropdownMenuItem<ProgressFilter> _buildDropdownItem(
    String label,
    ProgressFilter value,
    IconData icon,
  ) {
    return DropdownMenuItem<ProgressFilter>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: _progressFilter == value
                ? Theme.of(context).colorScheme.primary
                : Colors.white70,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: _progressFilter == value
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white70,
              fontWeight: _progressFilter == value
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelDropdown(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LevelFilter>(
          value: _levelFilter,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A2332),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.primary,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          items: [
            _buildLevelDropdownItem('All Levels', LevelFilter.all),
            _buildLevelDropdownItem('Beginner', LevelFilter.beginner),
            _buildLevelDropdownItem('Intermediate', LevelFilter.intermediate),
            _buildLevelDropdownItem('Advanced', LevelFilter.advanced),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _levelFilter = value);
            }
          },
        ),
      ),
    );
  }

  DropdownMenuItem<LevelFilter> _buildLevelDropdownItem(
    String label,
    LevelFilter value,
  ) {
    return DropdownMenuItem<LevelFilter>(
      value: value,
      child: Text(
        label,
        style: TextStyle(
          color: _levelFilter == value
              ? Theme.of(context).colorScheme.primary
              : Colors.white70,
          fontWeight: _levelFilter == value
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }

  List<Lesson> _filterLessons(
    List<Lesson> lessons,
    List<LessonProgress> progresses,
    List<String> bookmarks,
  ) {
    final filtered = lessons.where((lesson) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = lesson.title.toLowerCase().contains(query);
        final matchesSubtitle = lesson.subtitle.toLowerCase().contains(query);
        if (!matchesTitle && !matchesSubtitle) {
          return false;
        }
      }

      // Level filter
      if (_levelFilter != LevelFilter.all) {
        final levelMatch = switch (_levelFilter) {
          LevelFilter.beginner => lesson.level.toLowerCase() == 'beginner',
          LevelFilter.intermediate => lesson.level.toLowerCase() == 'intermediate',
          LevelFilter.advanced => lesson.level.toLowerCase() == 'advanced',
          LevelFilter.all => true,
        };
        if (!levelMatch) {
          return false;
        }
      }

      // Progress filter
      if (_progressFilter != ProgressFilter.all) {
        final progress = progresses
            .cast<LessonProgress?>()
            .firstWhere((p) => p?.lessonId == lesson.id, orElse: () => null);

        final progressMatch = switch (_progressFilter) {
          ProgressFilter.bookmarked => bookmarks.contains(lesson.id),
          ProgressFilter.completed => progress?.completed == true,
          ProgressFilter.inProgress => progress?.isInProgress == true,
          ProgressFilter.notStarted => progress == null || progress.isNotStarted,
          ProgressFilter.all => true,
        };
        if (!progressMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort lessons: first by level (beginner, intermediate, advanced), then by published date
    filtered.sort((a, b) {
      // Get level order (0=beginner, 1=intermediate, 2=advanced)
      final aLevelOrder = _levelOrder[a.level.toLowerCase()] ?? 999;
      final bLevelOrder = _levelOrder[b.level.toLowerCase()] ?? 999;

      // First sort by level
      if (aLevelOrder != bLevelOrder) {
        return aLevelOrder.compareTo(bLevelOrder);
      }

      // If same level, sort by published date (newest first)
      if (a.publishedAt != null && b.publishedAt != null) {
        return b.publishedAt!.compareTo(a.publishedAt!);
      }

      // Fallback to title if no published date
      return a.title.compareTo(b.title);
    });

    return filtered;
  }
}

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final LessonProgress? progress;

  const LessonCard({
    super.key,
    required this.lesson,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () async {
        // TODO: Add authentication check for advanced lessons
        // For now, all lessons are accessible

        // Navigate to lesson
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonDetailScreen(lessonId: lesson.id),
            ),
          );
        }
      },
      child: Row(
        children: [
          // Icon container with gradient
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withOpacity(0.25),
                  colorScheme.primary.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  lesson.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.65),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${lesson.minutes} min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        lesson.level,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Show progress percentage if in progress
                    if (progress != null && progress!.isInProgress) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress!.progressPercentage * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Completion indicator or progress
          if (progress?.completed == true)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF059669),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 18,
                color: Colors.white,
              ),
            )
          else if (progress != null && progress!.isInProgress)
            SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress!.progressPercentage,
                    strokeWidth: 3,
                    color: colorScheme.primary,
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                  Text(
                    '${(progress!.progressPercentage * 100).toInt()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else if (AuthHelper.requiresAuthentication(lesson.level) &&
                  !AuthHelper.isUserAuthenticated())
            // Show lock icon for premium content
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.3),
                    Colors.amber.withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 18,
                color: Colors.amber,
              ),
            )
          else
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.white.withOpacity(0.3),
            ),
        ],
      ),
    );
  }
}
