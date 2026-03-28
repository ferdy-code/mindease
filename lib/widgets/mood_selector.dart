import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';
import '../models/mood_entry.dart';

class MoodSelector extends StatelessWidget {
  final int selectedIndex; // -1 = none selected
  final ValueChanged<int> onSelected;

  const MoodSelector({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const moodColors = <Color>[
    Color(0xFFD63031), // veryBad  – red
    Color(0xFFE17055), // bad      – orange
    Color(0xFFF3D250), // neutral  – yellow
    Color(0xFF55D98D), // good     – light green
    Color(0xFF00B894), // veryGood – green
  ];

  static Color colorFor(MoodLevel level) => moodColors[level.index];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (i) {
        final level = MoodLevel.values[i];
        final color = moodColors[i];
        final isSelected = selectedIndex == i;
        return GestureDetector(
          onTap: () => onSelected(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 58,
            height: 78,
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(fontSize: isSelected ? 32 : 26),
                  child: Text(level.emoji),
                ),
                const SizedBox(height: 4),
                Text(
                  level.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? color : AppTheme.textHint,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
