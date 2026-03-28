import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';

class JournalListScreen extends ConsumerStatefulWidget {
  const JournalListScreen({super.key});

  @override
  ConsumerState<JournalListScreen> createState() =>
      _JournalListScreenState();
}

class _JournalListScreenState extends ConsumerState<JournalListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(journalProvider.notifier).fetchEntries();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(journalProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final journalState = ref.watch(journalProvider);
    final tags = ref.watch(journalTagsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Jurnal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/journal/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari jurnal...',
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: AppTheme.textHint),
                suffixIcon: journalState.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(journalProvider.notifier)
                              .setSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
          ),
          // Tag filter chips
          if (tags.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: tags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final isSelected =
                      journalState.selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () => ref
                        .read(journalProvider.notifier)
                        .toggleTag(tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.divider,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          // List / Loading / Empty
          Expanded(
            child: journalState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : journalState.entries.isEmpty
                    ? _EmptyState(
                        isFiltered: journalState.searchQuery.isNotEmpty ||
                            journalState.selectedTags.isNotEmpty,
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: journalState.entries.length +
                            (journalState.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index == journalState.entries.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final entry = journalState.entries[index];
                          return Dismissible(
                            key: ValueKey(entry.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(
                                    AppTheme.cardRadius),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus jurnal?'),
                                  content: Text(
                                    '"${entry.title}" akan dihapus permanen.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: Text(
                                        'Hapus',
                                        style: TextStyle(
                                            color: Colors.red[600]),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) async {
                              try {
                                await ref
                                    .read(journalProvider.notifier)
                                    .deleteEntry(entry.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Jurnal dihapus')),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Gagal menghapus jurnal')),
                                  );
                                }
                              }
                            },
                            child: _JournalCard(
                              entry: entry,
                              isFavorite: journalState.favoriteIds
                                  .contains(entry.id),
                              onTap: () =>
                                  context.push('/journal/${entry.id}'),
                              onFavorite: () => ref
                                  .read(journalProvider.notifier)
                                  .toggleFavorite(entry.id),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFiltered;

  const _EmptyState({this.isFiltered = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered
                    ? Icons.search_off_rounded
                    : Icons.book_outlined,
                size: 44,
                color: AppTheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'Tidak ada hasil' : 'Belum ada jurnal',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Coba kata kunci atau filter yang berbeda'
                  : 'Tuliskan pikiran dan perasaanmu\nuntuk memulai perjalanan ini',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/journal/new'),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Tulis Jurnal'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Journal card ───────────────────────────────────────────────────────────

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _JournalCard({
    required this.entry,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  String _formatDate(DateTime dt) {
    final wib = dt.toUtc().add(const Duration(hours: 7));
    final now =
        DateTime.now().toUtc().add(const Duration(hours: 7));
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(wib.year, wib.month, wib.day);
    final diff = today.difference(entryDay).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${wib.day} ${months[wib.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
              color: AppTheme.divider.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (entry.mood != null) ...[
                  Text(entry.mood!,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    entry.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(entry.updatedAt),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onFavorite,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(isFavorite),
                        size: 18,
                        color: isFavorite
                            ? const Color(0xFFE17055)
                            : AppTheme.textHint,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.content,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: entry.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
