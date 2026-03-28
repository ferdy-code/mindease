import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../../models/mood_entry.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/mood_selector.dart';

class MoodInputSheet extends ConsumerStatefulWidget {
  final MoodEntry? existingEntry;

  const MoodInputSheet({super.key, this.existingEntry});

  static Future<void> show(BuildContext context, {MoodEntry? existingEntry}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoodInputSheet(existingEntry: existingEntry),
    );
  }

  @override
  ConsumerState<MoodInputSheet> createState() => _MoodInputSheetState();
}

class _MoodInputSheetState extends ConsumerState<MoodInputSheet> {
  late int _selectedMood;
  late final TextEditingController _noteController;
  late final Set<String> _selectedActivities;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existingEntry;
    _selectedMood = e != null ? e.mood.index : -1;
    _noteController = TextEditingController(text: e?.note ?? '');
    _selectedActivities = e != null ? Set.of(e.tags) : {};
  }

  static const _activities = [
    'Kerja',
    'Olahraga',
    'Sosial',
    'Keluarga',
    'Belajar',
    'Hiburan',
    'Istirahat',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedMood < 0) return;
    setState(() => _saving = true);
    try {
      final notifier = ref.read(moodProvider.notifier);
      final existing = widget.existingEntry;
      if (existing != null) {
        await notifier.updateEntry(
          existing.id,
          mood: MoodLevel.values[_selectedMood],
          note: _noteController.text,
          tags: _selectedActivities.toList(),
        );
      } else {
        await notifier.addEntry(
          mood: MoodLevel.values[_selectedMood],
          note: _noteController.text,
          tags: _selectedActivities.toList(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan mood')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bagaimana perasaanmu?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    MoodSelector(
                      selectedIndex: _selectedMood,
                      onSelected: (i) => setState(() => _selectedMood = i),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Aktivitas hari ini',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _activities.map((act) {
                        final selected = _selectedActivities.contains(act);
                        return GestureDetector(
                          onTap: () => setState(() => selected
                              ? _selectedActivities.remove(act)
                              : _selectedActivities.add(act)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primary.withValues(alpha: 0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.primary
                                    : AppTheme.divider,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              act,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Catatan (opsional)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Tulis apa yang ada di pikiranmu...',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _selectedMood >= 0 && !_saving ? _save : null,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(widget.existingEntry != null
                                ? 'Perbarui Mood'
                                : 'Simpan Mood'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
