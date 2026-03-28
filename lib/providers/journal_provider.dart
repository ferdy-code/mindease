import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/api_client.dart';
import '../models/journal_entry.dart';
import 'auth_provider.dart';

const _cacheBox = 'journal_cache';
const _cacheKey = 'entries';
const _favBox = 'journal_favorites';
const _favKey = 'ids';
const _draftBox = 'journal_drafts';
const _pageSize = 10;

class JournalState {
  final List<JournalEntry> entries;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String searchQuery;
  final Set<String> selectedTags;
  final Set<String> favoriteIds;
  final String? error;

  const JournalState({
    this.entries = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.searchQuery = '',
    this.selectedTags = const {},
    this.favoriteIds = const {},
    this.error,
  });

  JournalState copyWith({
    List<JournalEntry>? entries,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? searchQuery,
    Set<String>? selectedTags,
    Set<String>? favoriteIds,
    String? error,
  }) => JournalState(
    entries: entries ?? this.entries,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    page: page ?? this.page,
    searchQuery: searchQuery ?? this.searchQuery,
    selectedTags: selectedTags ?? this.selectedTags,
    favoriteIds: favoriteIds ?? this.favoriteIds,
    error: error,
  );
}

class JournalNotifier extends StateNotifier<JournalState> {
  JournalNotifier() : super(const JournalState());

  Future<void> init() async {
    // Load favorites from Hive
    final favBox = await Hive.openBox<String>(_favBox);
    final favJson = favBox.get(_favKey);
    Set<String> favoriteIds = {};
    if (favJson != null) {
      try {
        final list = jsonDecode(favJson) as List;
        favoriteIds = Set<String>.from(list.cast<String>());
      } catch (_) {}
    }
    state = state.copyWith(favoriteIds: favoriteIds);
    await fetchEntries(reset: true);
  }

  void reset() => state = const JournalState();

  Future<void> fetchEntries({bool reset = false}) async {
    if (!reset && (state.isLoadingMore || !state.hasMore)) return;
    if (reset && state.isLoading) return;

    final page = reset ? 1 : state.page;

    if (reset) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final response = await ApiClient().dio.get(
        '/journals',
        queryParameters: {
          'page': page,
          'limit': _pageSize,
          if (state.searchQuery.isNotEmpty) 'search': state.searchQuery,
          if (state.selectedTags.isNotEmpty)
            'tag': state.selectedTags.join(','),
        },
      );

      final raw = response.data['data']['entries'];
      final rawList = raw is List
          ? raw
          : (raw as Map<String, dynamic>)['data'] as List;
      log(rawList.toString());
      final fetched = rawList
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      final hasMore = fetched.length >= _pageSize;
      final entries = reset ? fetched : [...state.entries, ...fetched];

      state = state.copyWith(
        entries: entries,
        isLoading: false,
        isLoadingMore: false,
        hasMore: hasMore,
        page: page + 1,
      );

      if (reset) await _writeCache(entries);
    } catch (e) {
      log('[JournalProvider] fetch error: $e');
      if (reset) {
        final cached = await _readCache();
        state = state.copyWith(
          entries: cached,
          isLoading: false,
          isLoadingMore: false,
          error: 'Gagal memuat jurnal',
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    }
  }

  Future<void> setSearch(String query) async {
    state = state.copyWith(searchQuery: query);
    await fetchEntries(reset: true);
  }

  Future<void> toggleTag(String tag) async {
    final tags = Set<String>.from(state.selectedTags);
    tags.contains(tag) ? tags.remove(tag) : tags.add(tag);
    state = state.copyWith(selectedTags: tags);
    await fetchEntries(reset: true);
  }

  Future<JournalEntry?> createEntry({
    required String title,
    required String content,
    List<String> tags = const [],
    String? mood,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '/journals',
        data: {
          'title': title,
          'content': content,
          'emotionTags': tags,
          if (mood != null) 'mood': mood,
        },
      );
      final raw = response.data['data'];
      final data = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      final entry = JournalEntry.fromJson(data);
      state = state.copyWith(entries: [entry, ...state.entries]);
      await _writeCache(state.entries);
      return entry;
    } catch (e) {
      log('[JournalProvider] create error: $e');
      rethrow;
    }
  }

  Future<void> updateEntry(
    String id, {
    required String title,
    required String content,
    List<String> tags = const [],
    String? mood,
  }) async {
    final current = state.entries;
    // Optimistic update
    final optimistic = current.map((e) {
      if (e.id != id) return e;
      return JournalEntry(
        id: e.id,
        userId: e.userId,
        title: title,
        content: content,
        mood: mood,
        tags: tags,
        isFavorite: e.isFavorite,
        createdAt: e.createdAt,
        updatedAt: DateTime.now(),
      );
    }).toList();
    state = state.copyWith(entries: optimistic);

    try {
      final response = await ApiClient().dio.put(
        '/journals/$id',
        data: {
          'title': title,
          'content': content,
          'emotionTags': tags,
          if (mood != null) 'mood': mood,
        },
      );
      final raw = response.data['data'];
      final data = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      final saved = JournalEntry.fromJson(data);
      final updated = current.map((e) => e.id == id ? saved : e).toList();
      state = state.copyWith(entries: updated);
      await _writeCache(updated);
    } catch (e) {
      log('[JournalProvider] update error: $e');
      state = state.copyWith(entries: current);
      rethrow;
    }
  }

  Future<void> deleteEntry(String id) async {
    final current = state.entries;
    state = state.copyWith(entries: current.where((e) => e.id != id).toList());
    try {
      await ApiClient().dio.delete('/journals/$id');
      await _writeCache(state.entries);
    } catch (e) {
      log('[JournalProvider] delete error: $e');
      state = state.copyWith(entries: current);
      rethrow;
    }
  }

  Future<void> toggleFavorite(String id) async {
    final currentEntries = state.entries;
    final entry = currentEntries.firstWhere((e) => e.id == id);
    final newFav = !entry.isFavorite;

    // Optimistic update
    final optimistic = currentEntries.map((e) {
      if (e.id != id) return e;
      return JournalEntry(
        id: e.id,
        userId: e.userId,
        title: e.title,
        content: e.content,
        mood: e.mood,
        tags: e.tags,
        isFavorite: newFav,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );
    }).toList();

    final favs = Set<String>.from(state.favoriteIds);
    newFav ? favs.add(id) : favs.remove(id);
    state = state.copyWith(entries: optimistic, favoriteIds: favs);

    try {
      final response = await ApiClient().dio.put('/journals/$id/favorite');
      final raw = response.data['data'];
      final data = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      final saved = JournalEntry.fromJson(data);
      final updated = state.entries.map((e) => e.id == id ? saved : e).toList();
      state = state.copyWith(entries: updated);
      await _writeCache(updated);

      final confirmedFavs = Set<String>.from(state.favoriteIds);
      saved.isFavorite ? confirmedFavs.add(id) : confirmedFavs.remove(id);
      state = state.copyWith(favoriteIds: confirmedFavs);
      final box = await Hive.openBox<String>(_favBox);
      await box.put(_favKey, jsonEncode(confirmedFavs.toList()));
    } catch (e) {
      log('[JournalProvider] toggleFavorite error: $e');
      state = state.copyWith(entries: currentEntries, favoriteIds: Set<String>.from(state.favoriteIds)..clear()..addAll(currentEntries.where((e) => e.isFavorite).map((e) => e.id)));
      rethrow;
    }
  }

  // ── Draft ──────────────────────────────────────────────────────────────

  Future<void> saveDraft({
    required String key,
    required String title,
    required String content,
    List<String> tags = const [],
    String? mood,
  }) async {
    final box = await Hive.openBox<String>(_draftBox);
    await box.put(
      key,
      jsonEncode({
        'title': title,
        'content': content,
        'tags': tags,
        'mood': mood,
        'savedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<Map<String, dynamic>?> loadDraft(String key) async {
    final box = await Hive.openBox<String>(_draftBox);
    final json = box.get(key);
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDraft(String key) async {
    final box = await Hive.openBox<String>(_draftBox);
    await box.delete(key);
  }

  // ── Cache ──────────────────────────────────────────────────────────────

  Future<void> _writeCache(List<JournalEntry> entries) async {
    final box = await Hive.openBox<String>(_cacheBox);
    await box.put(
      _cacheKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<JournalEntry>> _readCache() async {
    final box = await Hive.openBox<String>(_cacheBox);
    final json = box.get(_cacheKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final journalProvider = StateNotifierProvider<JournalNotifier, JournalState>((
  ref,
) {
  final notifier = JournalNotifier();
  ref.listen<AuthState>(authProvider, (_, next) {
    if (next.status == AuthStatus.authenticated) {
      notifier.init();
    } else if (next.status == AuthStatus.unauthenticated) {
      notifier.reset();
    }
  });
  if (ref.read(authProvider).status == AuthStatus.authenticated) {
    notifier.init();
  }
  return notifier;
});

/// All unique tags from loaded entries.
final journalTagsProvider = Provider<List<String>>((ref) {
  final entries = ref.watch(journalProvider).entries;
  final tags = <String>{};
  for (final e in entries) {
    tags.addAll(e.tags);
  }
  return tags.toList()..sort();
});
