import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../../models/mood_entry.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/mood_selector.dart';

class MoodInputScreen extends ConsumerStatefulWidget {
  const MoodInputScreen({super.key});

  @override
  ConsumerState<MoodInputScreen> createState() => _MoodInputScreenState();
}

class _MoodInputScreenState extends ConsumerState<MoodInputScreen> {
  int _selectedMood = -1;
  final _noteController = TextEditingController();
  final _selectedActivities = <String>{};
  bool _saving = false;

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
      await ref
          .read(moodProvider.notifier)
          .addEntry(
            mood: MoodLevel.values[_selectedMood],
            note: _noteController.text,
            tags: _selectedActivities.toList(),
          );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menyimpan mood')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Catat Mood'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _selectedMood >= 0 && !_saving ? _save : null,
              child: const Text('Simpan'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bagaimana perasaanmu\nsaat ini?',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 28),
            MoodSelector(
              selectedIndex: _selectedMood,
              onSelected: (i) => setState(() => _selectedMood = i),
            ),
            const SizedBox(height: 28),
            Text(
              'Aktivitas hari ini',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activities.map((tag) {
                final isSelected = _selectedActivities.contains(tag);
                return GestureDetector(
                  onTap: () => setState(
                    () => isSelected
                        ? _selectedActivities.remove(tag)
                        : _selectedActivities.add(tag),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
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
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Catatan (opsional)',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 4,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Tulis apa yang ada di pikiranmu...',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedMood >= 0 && !_saving ? _save : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan Mood'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
