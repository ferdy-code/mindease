import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../../models/mood_entry.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/mood_selector.dart';

class MoodHistoryScreen extends ConsumerWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodAsync = ref.watch(moodProvider);
    final week = ref.watch(weekMoodProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Riwayat Mood')),
      body: moodAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Gagal memuat data',
            style: GoogleFonts.poppins(color: AppTheme.textSecondary),
          ),
        ),
        data: (entries) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _WeeklyChart(week: week)),
            if (entries.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Belum ada mood yang dicatat',
                    style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = entries[index];
                    // TODO: aktifkan kembali fitur hapus mood
                    // return Dismissible(
                    //   key: ValueKey(entry.id),
                    //   direction: DismissDirection.endToStart,
                    //   onDismissed: (_) async {
                    //     try {
                    //       await ref
                    //           .read(moodProvider.notifier)
                    //           .deleteEntry(entry.id);
                    //       if (context.mounted) {
                    //         ScaffoldMessenger.of(context).showSnackBar(
                    //           SnackBar(
                    //             content: Text(
                    //               'Mood "${entry.mood.label}" dihapus',
                    //               style: GoogleFonts.poppins(
                    //                   color: Colors.white),
                    //             ),
                    //           ),
                    //         );
                    //       }
                    //     } catch (_) {
                    //       if (context.mounted) {
                    //         ScaffoldMessenger.of(context).showSnackBar(
                    //           SnackBar(
                    //             content: Text(
                    //               'Gagal menghapus mood',
                    //               style: GoogleFonts.poppins(
                    //                   color: Colors.white),
                    //             ),
                    //             backgroundColor: AppTheme.error,
                    //           ),
                    //         );
                    //       }
                    //     }
                    //   },
                    //   background: Container(
                    //     margin: const EdgeInsets.only(bottom: 10),
                    //     decoration: BoxDecoration(
                    //       color: AppTheme.error,
                    //       borderRadius:
                    //           BorderRadius.circular(AppTheme.cardRadius),
                    //     ),
                    //     alignment: Alignment.centerRight,
                    //     padding: const EdgeInsets.only(right: 20),
                    //     child: const Icon(
                    //       Icons.delete_outline_rounded,
                    //       color: Colors.white,
                    //       size: 24,
                    //     ),
                    //   ),
                    //   child: _MoodEntryTile(entry: entry),
                    // );
                    return _MoodEntryTile(entry: entry);
                  }, childCount: entries.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<MoodEntry?> week;

  const _WeeklyChart({required this.week});

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final groups = List.generate(7, (i) {
      final entry = week[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: entry != null ? (entry.mood.index + 1).toDouble() : 0.0,
            color: entry != null
                ? MoodSelector.colorFor(entry.mood)
                : AppTheme.divider,
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood 7 Hari Terakhir',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: 5,
                minY: 0,
                barGroups: groups,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.textPrimary,
                    getTooltipItem: (group, _, rod, __) {
                      final entry = week[group.x];
                      if (entry == null) return null;
                      return BarTooltipItem(
                        entry.mood.label,
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final day = today.subtract(
                          Duration(days: 6 - value.toInt()),
                        );
                        final label = _dayLabels[day.weekday - 1];
                        final isToday = value.toInt() == 6;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isToday
                                  ? AppTheme.primary
                                  : AppTheme.textHint,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodEntryTile extends StatelessWidget {
  final MoodEntry entry;

  const _MoodEntryTile({required this.entry});

  DateTime _toWib(DateTime dt) => dt.toUtc().add(const Duration(hours: 7));

  String _formatDate(DateTime dt) {
    final wib = _toWib(dt);
    final now = _toWib(DateTime.now());
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(wib.year, wib.month, wib.day);
    final diff = today.difference(entryDay).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return '${wib.day}/${wib.month}/${wib.year}';
  }

  String _formatTime(DateTime dt) {
    final wib = _toWib(dt);
    return '${wib.hour.toString().padLeft(2, '0')}:${wib.minute.toString().padLeft(2, '0')} WIB';
  }

  @override
  Widget build(BuildContext context) {
    final color = MoodSelector.colorFor(entry.mood);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                entry.mood.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.mood.label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.note!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: entry.tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t,
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
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(entry.updatedAt),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textHint,
                ),
              ),
              Text(
                _formatTime(entry.updatedAt),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
