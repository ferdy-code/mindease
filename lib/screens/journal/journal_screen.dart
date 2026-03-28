import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Jurnal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _JournalCard(index: index),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final int index;

  const _JournalCard({required this.index});

  static const _data = [
    ('Refleksi Pagi', 'Hari ini saya merasa lebih tenang dari biasanya...', '🙂', '27 Mar'),
    ('Rasa Syukur', 'Tiga hal yang saya syukuri hari ini adalah...', '😄', '26 Mar'),
    ('Tantangan', 'Hari yang berat tapi saya belajar banyak...', '😐', '25 Mar'),
    ('Pencapaian', 'Berhasil menyelesaikan presentasi dengan baik...', '😄', '24 Mar'),
    ('Pikiran Bebas', 'Kadang saya bertanya-tanya tentang masa depan...', '😕', '23 Mar'),
  ];

  @override
  Widget build(BuildContext context) {
    final (title, preview, mood, date) = _data[index];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border:
            Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(mood, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                date,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            preview,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
