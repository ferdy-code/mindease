import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/api_client.dart';
import '../models/mood_entry.dart';
import 'auth_provider.dart';

const _boxName = 'mood_cache';
const _cacheKey = 'entries';

class MoodNotifier extends AsyncNotifier<List<MoodEntry>> {
  @override
  Future<List<MoodEntry>> build() async {
    final authState = ref.watch(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      return [];
    }
    return _loadEntries();
  }

  Future<List<MoodEntry>> _loadEntries() async {
    final box = await Hive.openBox<String>(_boxName);
    final cached = box.get(_cacheKey);
    List<MoodEntry> initial = [];
    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List;
        initial = list
            .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    _fetchFromApi();
    return initial;
  }

  Future<void> _fetchFromApi() async {
    try {
      final response = await ApiClient().dio.get('/moods');

      // Handle both array response and wrapped { data: [...] } response
      final raw = response.data;
      final rawList = raw is List
          ? raw
          : (raw as Map<String, dynamic>)['data'] as List;

      final list = rawList
          .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncData(list);
      await _writeCache(list);
    } catch (e) {}
  }

  Future<void> _writeCache(List<MoodEntry> entries) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(
      _cacheKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addEntry({
    required MoodLevel mood,
    String? note,
    List<String> tags = const [],
  }) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final current = state.valueOrNull ?? [];
    final cleanNote = note?.trim().isEmpty == true ? null : note?.trim();

    // Optimistic update
    final optimistic = MoodEntry(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      mood: mood,
      note: cleanNote,
      tags: tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = AsyncData([optimistic, ...current]);
    try {
      final response = await ApiClient().dio.post(
        '/moods',
        data: {
          'moodScore': mood.index + 1,
          if (cleanNote != null) 'note': cleanNote,
          'activities': tags,
        },
      );
      final saved = MoodEntry.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
      final updated = [saved, ...current];
      state = AsyncData(updated);
      await _writeCache(updated);
    } catch (_) {
      state = AsyncData(current); // revert on failure
      rethrow;
    }
  }

  Future<void> updateEntry(
    String id, {
    required MoodLevel mood,
    String? note,
    List<String> tags = const [],
  }) async {
    final current = state.valueOrNull ?? [];
    final cleanNote = note?.trim().isEmpty == true ? null : note?.trim();

    // Optimistic update
    final optimistic = current.map((e) {
      if (e.id != id) return e;
      return MoodEntry(
        id: e.id,
        userId: e.userId,
        mood: mood,
        note: cleanNote,
        tags: tags,
        createdAt: e.createdAt,
        updatedAt: DateTime.now(),
      );
    }).toList();
    state = AsyncData(optimistic);

    try {
      final response = await ApiClient().dio.put(
        '/moods/$id',
        data: {
          'moodScore': mood.index + 1,
          if (cleanNote != null) 'note': cleanNote,
          'activities': tags,
        },
      );
      final saved = MoodEntry.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
      final updated = current.map((e) => e.id == id ? saved : e).toList();
      state = AsyncData(updated);
      await _writeCache(updated);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> deleteEntry(String id) async {
    final current = state.valueOrNull ?? [];

    // Optimistic remove
    final optimistic = current.where((e) => e.id != id).toList();
    state = AsyncData(optimistic);

    try {
      await ApiClient().dio.delete('/moods/$id');
      await _writeCache(optimistic);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final moodProvider = AsyncNotifierProvider<MoodNotifier, List<MoodEntry>>(
  MoodNotifier.new,
);

/// Most recent entry today, or null.
final todayMoodProvider = Provider<MoodEntry?>((ref) {
  final entries = ref.watch(moodProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return entries
      .where(
        (e) =>
            e.createdAt.year == now.year &&
            e.createdAt.month == now.month &&
            e.createdAt.day == now.day,
      )
      .firstOrNull;
});

/// Last 7 days oldest-first; null means no entry that day.
final weekMoodProvider = Provider<List<MoodEntry?>>((ref) {
  final entries = ref.watch(moodProvider).valueOrNull ?? [];
  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  return List.generate(7, (i) {
    final day = today.subtract(Duration(days: 6 - i));
    return entries
        .where(
          (e) =>
              e.createdAt.year == day.year &&
              e.createdAt.month == day.month &&
              e.createdAt.day == day.day,
        )
        .firstOrNull;
  });
});

/// Consecutive days with at least one entry, ending today or yesterday.
final streakProvider = Provider<int>((ref) {
  final entries = ref.watch(moodProvider).valueOrNull ?? [];
  if (entries.isEmpty) return 0;

  final dates =
      entries
          .map(
            (e) =>
                DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day),
          )
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final yesterday = today.subtract(const Duration(days: 1));
  if (dates.first != today && dates.first != yesterday) return 0;

  int streak = 1;
  for (int i = 1; i < dates.length; i++) {
    if (dates[i - 1].difference(dates[i]).inDays == 1) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
});
