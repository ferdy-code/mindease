import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';

class JournalEditorScreen extends ConsumerStatefulWidget {
  final String? entryId;

  const JournalEditorScreen({super.key, this.entryId});

  @override
  ConsumerState<JournalEditorScreen> createState() =>
      _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _tags = <String>[];
  String? _selectedMood;
  bool _saving = false;
  bool _isDirty = false;
  bool _initialized = false;
  Timer? _autoSaveTimer;
  JournalEntry? _existingEntry;

  static const _moodOptions = [
    ('😔', 'Sangat\nBuruk'),
    ('😕', 'Buruk'),
    ('😐', 'Biasa'),
    ('🙂', 'Baik'),
    ('😄', 'Sangat\nBaik'),
  ];

  String get _draftKey =>
      widget.entryId != null ? 'draft_${widget.entryId}' : 'draft_new';

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initEditor();
    }
  }

  Future<void> _initEditor() async {
    if (widget.entryId != null) {
      final entries = ref.read(journalProvider).entries;
      _existingEntry = entries.where((e) => e.id == widget.entryId).firstOrNull;
      if (_existingEntry != null && mounted) {
        _titleController.text = _existingEntry!.title;
        _contentController.text = _existingEntry!.content;
        _tags.addAll(_existingEntry!.tags);
        _selectedMood = _existingEntry!.mood;
        setState(() {});
      }
    }

    // Load draft — use if newer than existing entry
    final draft = await ref.read(journalProvider.notifier).loadDraft(_draftKey);
    if (draft != null && mounted) {
      final savedAt = DateTime.tryParse(draft['savedAt'] as String? ?? '');
      final useDraft =
          savedAt != null &&
          (_existingEntry == null ||
              savedAt.isAfter(_existingEntry!.updatedAt));
      if (useDraft) {
        setState(() {
          _titleController.text =
              draft['title'] as String? ?? _titleController.text;
          _contentController.text =
              draft['content'] as String? ?? _contentController.text;
          if (draft['tags'] is List) {
            _tags
              ..clear()
              ..addAll((draft['tags'] as List).cast<String>());
          }
          _selectedMood = draft['mood'] as String? ?? _selectedMood;
        });
      }
    }

    _startAutoSave();
  }

  void _onChanged() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_isDirty) await _saveDraft();
    });
  }

  Future<void> _saveDraft() async {
    await ref
        .read(journalProvider.notifier)
        .saveDraft(
          key: _draftKey,
          title: _titleController.text,
          content: _contentController.text,
          tags: List.from(_tags),
          mood: _selectedMood,
        );
    if (mounted) setState(() => _isDirty = false);
  }

  void _addTag(String tag) {
    final t = tag.trim();
    if (t.isEmpty || _tags.contains(t)) return;
    setState(() {
      _tags.add(t);
      _tagController.clear();
      _isDirty = true;
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _isDirty = true;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Judul tidak boleh kosong')));
      return;
    }
    setState(() => _saving = true);
    try {
      final notifier = ref.read(journalProvider.notifier);
      if (_existingEntry != null) {
        await notifier.updateEntry(
          _existingEntry!.id,
          title: title,
          content: content,
          tags: List.from(_tags),
          mood: _selectedMood,
        );
      } else {
        await notifier.createEntry(
          title: title,
          content: content,
          tags: List.from(_tags),
          mood: _selectedMood,
        );
      }
      await notifier.clearDraft(_draftKey);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menyimpan jurnal')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_isDirty) await _saveDraft();
    return true;
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existingEntry != null;
    if (!isEdit) {
      _titleController.clear();
      _contentController.clear();
      _tagController.clear();
      _tags.clear();
    }
    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop && _isDirty) await _saveDraft();
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              if (_isDirty) await _saveDraft();
              if (mounted) context.pop();
            },
          ),
          title: Text(isEdit ? 'Edit Jurnal' : 'Jurnal Baru'),
          actions: [
            if (_isDirty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    'Draf tersimpan',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: !_saving ? _save : null,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextField(
                controller: _titleController,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Judul',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textHint,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              Divider(
                color: AppTheme.divider.withValues(alpha: 0.5),
                height: 1,
              ),
              const SizedBox(height: 12),
              // Content
              TextField(
                controller: _contentController,
                maxLines: null,
                minLines: 12,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.8,
                ),
                decoration: InputDecoration(
                  hintText: 'Tulis pikiranmu di sini...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textHint,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 24),
              Divider(
                color: AppTheme.divider.withValues(alpha: 0.5),
                height: 1,
              ),
              const SizedBox(height: 20),

              // Mood link
              // _SectionLabel('Mood (opsional)'),
              // const SizedBox(height: 12),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceAround,
              //   children: _moodOptions.map((opt) {
              //     final (emoji, label) = opt;
              //     final isSelected = _selectedMood == emoji;
              //     return GestureDetector(
              //       onTap: () => setState(() =>
              //           _selectedMood = isSelected ? null : emoji),
              //       child: AnimatedContainer(
              //         duration: const Duration(milliseconds: 150),
              //         padding: const EdgeInsets.symmetric(
              //             horizontal: 8, vertical: 6),
              //         decoration: BoxDecoration(
              //           color: isSelected
              //               ? AppTheme.primary
              //                   .withValues(alpha: 0.1)
              //               : Colors.transparent,
              //           borderRadius: BorderRadius.circular(12),
              //           border: Border.all(
              //             color: isSelected
              //                 ? AppTheme.primary
              //                 : Colors.transparent,
              //             width: 1.5,
              //           ),
              //         ),
              //         child: Column(
              //           children: [
              //             Text(emoji,
              //                 style: const TextStyle(fontSize: 26)),
              //             const SizedBox(height: 2),
              //             Text(
              //               label,
              //               textAlign: TextAlign.center,
              //               style: GoogleFonts.poppins(
              //                 fontSize: 9,
              //                 height: 1.2,
              //                 color: isSelected
              //                     ? AppTheme.primary
              //                     : AppTheme.textHint,
              //                 fontWeight: isSelected
              //                     ? FontWeight.w600
              //                     : FontWeight.w400,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     );
              //   }).toList(),
              // ),
              // const SizedBox(height: 24),

              // Tags
              _SectionLabel('Tag'),
              const SizedBox(height: 10),
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _tags
                      .map(
                        (tag) => Chip(
                          label: Text(
                            tag,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.primary,
                            ),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => _removeTag(tag),
                          backgroundColor: AppTheme.primary.withValues(
                            alpha: 0.08,
                          ),
                          deleteIconColor: AppTheme.primary,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: _addTag,
                      decoration: InputDecoration(
                        hintText: 'Tambah tag...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.textHint,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: AppTheme.background,
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
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _addTag(_tagController.text),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}
