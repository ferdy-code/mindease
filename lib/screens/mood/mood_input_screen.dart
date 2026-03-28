import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';

class MoodInputScreen extends StatefulWidget {
  const MoodInputScreen({super.key});

  @override
  State<MoodInputScreen> createState() => _MoodInputScreenState();
}

class _MoodInputScreenState extends State<MoodInputScreen> {
  int _selectedMood = -1;
  final _noteController = TextEditingController();
  final _selectedTags = <String>{};

  static const _moods = [
    ('😔', 'Sangat\nBuruk', Color(0xFFD63031)),
    ('😕', 'Buruk', Color(0xFFE17055)),
    ('😐', 'Biasa', Color(0xFFB2BEC3)),
    ('🙂', 'Baik', Color(0xFF00B894)),
    ('😄', 'Sangat\nBaik', Color(0xFF6C5CE7)),
  ];

  static const _tags = [
    'Cemas', 'Tenang', 'Lelah', 'Bersemangat',
    'Sendirian', 'Bersyukur', 'Stres', 'Bahagia',
    'Sedih', 'Antusias',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    // TODO: dispatch save mood action via provider
    context.pop();
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
              onPressed: _selectedMood >= 0 ? _save : null,
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
            // Mood selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _moods.asMap().entries.map((entry) {
                final i = entry.key;
                final (emoji, label, color) = entry.value;
                final isSelected = _selectedMood == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    height: 78,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: color, width: 2)
                          : Border.all(
                              color: Colors.transparent, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                              fontSize: isSelected ? 32 : 26),
                          child: Text(emoji),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? color
                                : AppTheme.textHint,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Text(
              'Apa yang kamu rasakan?',
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
              children: _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
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
                  fontSize: 14, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Tulis apa yang ada di pikiranmu...',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedMood >= 0 ? _save : null,
                child: const Text('Simpan Mood'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
