import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LearningCenterScreen extends StatefulWidget {
  final VoidCallback? onNotifyPressed;

  const LearningCenterScreen({super.key, this.onNotifyPressed});

  @override
  State<LearningCenterScreen> createState() => _LearningCenterScreenState();
}

class _LearningCenterScreenState extends State<LearningCenterScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Cassava Diseases',
    'Pests & Insects',
    'Soil & Planting',
    'Pepper Care',
    'Audio Guides (Kpelle)',
  ];

  final List<Map<String, dynamic>> _tutorials = [
    {
      'title': 'Treating Cassava Mosaic Disease (CMD)',
      'category': 'Cassava Diseases',
      'duration': '3 min',
      'language': 'Kpelle & Liberian English',
      'problem': 'Yellow mottled leaf patterns, leaf distortion, and stunted root growth caused by whiteflies.',
      'solution': 'Step-by-step roguing of infected stems and organic neem leaf spray application.',
      'badge': 'TOP PROBLEM SOLVER',
      'badgeColor': Color(0xFF1B4332),
      'icon': Icons.ondemand_video_rounded,
      'downloads': '1.2k farmers',
    },
    {
      'title': 'Cassava Brown Streak Disease (CBSD) Identification',
      'category': 'Cassava Diseases',
      'duration': '4 min',
      'language': 'Kpelle & Liberian English',
      'problem': 'Brown necrotic streaks on green stems and dry corky root rot visible at harvest.',
      'solution': 'How to identify clean CARICASS planting material and avoid spreading root rot.',
      'badge': 'CARI VETTED',
      'badgeColor': Color(0xFF2D6A4F),
      'icon': Icons.video_library_rounded,
      'downloads': '890 farmers',
    },
    {
      'title': 'Fall Armyworm Eradication with Neem Extract',
      'category': 'Pests & Insects',
      'duration': '4 min',
      'language': 'Simple Liberian English',
      'problem': 'Severe leaf perforations, sawdust frass on leaf whorls, and early stem destruction.',
      'solution': 'Home preparation of 5% neem seed/leaf extract and early morning target spraying.',
      'badge': 'ORGANIC PEST CONTROL',
      'badgeColor': Color(0xFFD97706),
      'icon': Icons.bug_report_rounded,
      'downloads': '2.1k farmers',
    },
    {
      'title': 'Pepper Anthracnose & Fruit Rot Prevention',
      'category': 'Pepper Care',
      'duration': '5 min',
      'language': 'English & Bassa',
      'problem': 'Dark water-soaked sunken lesions on ripening peppers during high-humidity weeks.',
      'solution': 'Drip irrigation practices, correct plant spacing, and copper-based foliar spray.',
      'badge': 'HORTICULTURE',
      'badgeColor': Color(0xFFE76F51),
      'icon': Icons.local_florist_rounded,
      'downloads': '740 farmers',
    },
    {
      'title': 'Raised Mound Preparation for Wet Season',
      'category': 'Soil & Planting',
      'duration': '5 min',
      'language': 'Liberian English',
      'problem': 'Waterlogging in Bong and Nimba lowland fields causing tuber root rot in rainy season.',
      'solution': 'Mounding techniques: 45cm high ridges, drainage trenches, and diagonal planting angle.',
      'badge': 'FIELD STANDARD',
      'badgeColor': Color(0xFF2563EB),
      'icon': Icons.landscape_rounded,
      'downloads': '1.5k farmers',
    },
    {
      'title': 'Safe Cassava Stem Storage Between Harvests',
      'category': 'Cassava Diseases',
      'duration': '3 min',
      'language': 'Kpelle & English',
      'problem': 'Stem cuttings drying out, termite infestation, and loss of planting viability.',
      'solution': 'Vertical shaded trenching with moist sand layering to preserve 95% germination rate.',
      'badge': 'POST-HARVEST',
      'badgeColor': Color(0xFF059669),
      'icon': Icons.inventory_2_rounded,
      'downloads': '930 farmers',
    },
    {
      'title': 'Audio Field Guide: Cassava Health in Kpelle',
      'category': 'Audio Guides (Kpelle)',
      'duration': '7 min audio',
      'language': '100% Kpelle Audio',
      'problem': 'Voice-first guidance for farmers who prefer listening over reading on their farms.',
      'solution': 'Complete audio instructions on field inspection, disease roguing, and when to call CARI.',
      'badge': 'VOICE / AUDIO',
      'badgeColor': Color(0xFF7C3AED),
      'icon': Icons.headphones_rounded,
      'downloads': '3.4k listens',
    },
  ];

  void _showComingSoon(String tutorialTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.paleGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded, color: AppTheme.primaryGreen, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Text(
                      'IN DEVELOPMENT · COMING SOON',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tutorialTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This video tutorial is being produced and validated with Central Agricultural Research Institute (CARI Suakoko) agronomists.',
              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.35),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What will be included on launch:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• High-definition video with step-by-step field demonstrations', style: TextStyle(fontSize: 12, height: 1.3)),
                  SizedBox(height: 4),
                  Text('• Full voiceovers in Kpelle, Bassa, and Simple Liberian English', style: TextStyle(fontSize: 12, height: 1.3)),
                  SizedBox(height: 4),
                  Text('• Compressed lightweight download (<10MB) for offline farm use', style: TextStyle(fontSize: 12, height: 1.3)),
                  SizedBox(height: 4),
                  Text('• 1-click USSD audio replay (*123#) for basic feature phones', style: TextStyle(fontSize: 12, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You will receive an SMS alert when "$tutorialTitle" is published!'),
                  backgroundColor: AppTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              widget.onNotifyPressed?.call();
            },
            child: const Text('Notify Me on Launch', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _tutorials.where((t) {
      final matchesCategory = _selectedCategory == 'All' || t['category'] == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          t['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t['problem'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t['solution'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Banner
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, Color(0xFF2D6A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Farmer Learning Center',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'CARI Suakoko Certified Problem-Solving Guides',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.earthYellow.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.earthYellow),
                        ),
                        child: const Text(
                          'PREVIEW',
                          style: TextStyle(
                            color: AppTheme.earthYellow,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search Box
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search farm problems (e.g. leaf curl, neem, rot)...',
                        hintStyle: TextStyle(color: Colors.black45, fontSize: 12),
                        prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.primaryGreen),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Category Pills
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _categories.length,
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.darkText,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryGreen,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                },
              ),
            ),

            // Tutorial List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('No tutorials matching "$_searchQuery"', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final t = filtered[index];
                        return _buildTutorialTile(t);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialTile(Map<String, dynamic> t) {
    final Color badgeColor = t['badgeColor'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showComingSoon(t['title']),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge & Duration Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      t['badge'],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        t['duration'],
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(t['icon'] as IconData, color: badgeColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['title'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.record_voice_over_outlined, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              t['language'],
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Problem & Solution Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Problem: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                        Expanded(
                          child: Text(
                            t['problem'],
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CARI Solution: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                        Expanded(
                          child: Text(
                            t['solution'],
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${t['downloads']} learning this',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.paleGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: AppTheme.primaryGreen, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Watch Tutorial (Coming Soon)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
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
