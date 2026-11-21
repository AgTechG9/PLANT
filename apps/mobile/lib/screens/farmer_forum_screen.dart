import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FarmerForumScreen extends StatefulWidget {
  final VoidCallback? onNotifyPressed;

  const FarmerForumScreen({super.key, this.onNotifyPressed});

  @override
  State<FarmerForumScreen> createState() => _FarmerForumScreenState();
}

class _FarmerForumScreenState extends State<FarmerForumScreen> {
  String _selectedCircle = 'All';
  String _searchQuery = '';

  final List<String> _circles = [
    'All',
    'Bong County',
    'Nimba County',
    'Market Prices',
    'Pest Alerts',
    'Ask CARI Extension',
  ];

  final List<Map<String, dynamic>> _threads = [
    {
      'author': 'Korto Flomo',
      'location': 'Suakoko, Bong',
      'avatarColor': Colors.purple.shade700,
      'time': '14m ago',
      'title': 'Early leaf curling spotted in Suakoko after heavy rain. Is anyone else spraying neem?',
      'circle': 'Bong County',
      'replies': 48,
      'likes': 19,
      'tag': 'CASSAVA ALERT',
      'tagColor': Color(0xFF1B4332),
      'hasVerifiedOfficer': true,
      'preview': 'I noticed yellowing on my 3-month CARICASS plot. Officer Gorpu suggested early morning neem extract. How many times a week are you folks spraying?',
    },
    {
      'author': 'CARI Market Desk',
      'location': 'Gbarnga Central Hub',
      'avatarColor': Colors.amber.shade900,
      'time': '1h ago',
      'title': 'Gbarnga Central Market Price Update: Fresh Cassava & Pepper Exchange',
      'circle': 'Market Prices',
      'replies': 31,
      'likes': 42,
      'tag': 'MARKET PRICES',
      'tagColor': Color(0xFFD97706),
      'hasVerifiedOfficer': true,
      'preview': 'Cassava 50kg bag wholesale: 3,200 - 3,500 LRD. Habanero pepper basket: 1,800 LRD (high demand). Monrovia truck arrivals expected on Thursday morning.',
    },
    {
      'author': 'Emmanuel Gbahn',
      'location': 'Tappita, Nimba',
      'avatarColor': Colors.blue.shade700,
      'time': '3h ago',
      'title': 'Fall Armyworm sightings in lower Nimba cassava and maize border plots',
      'circle': 'Nimba County',
      'replies': 22,
      'likes': 15,
      'tag': 'PEST ALERT',
      'tagColor': Color(0xFFDC2626),
      'hasVerifiedOfficer': false,
      'preview': 'Chewed leaves spotted around Tappita district. Sharing photo of the caterpillar whorls for verification from other farmers.',
    },
    {
      'author': 'Officer Gorpu Keller',
      'location': 'CARI Extension Desk',
      'avatarColor': AppTheme.primaryGreen,
      'time': '5h ago',
      'title': 'Official CARI Guidelines: Preserving stem cuttings for upcoming dry season',
      'circle': 'Ask CARI Extension',
      'replies': 56,
      'likes': 68,
      'tag': 'CARI EXTENSION',
      'tagColor': Color(0xFF2D6A4F),
      'hasVerifiedOfficer': true,
      'preview': 'Smallholders in Bong: Do not leave cut stems exposed to direct sunlight. Use shaded vertical trenching covered with banana leaves and moist sand.',
    },
    {
      'author': 'Mary Kollie',
      'location': 'Salala, Bong',
      'avatarColor': Colors.teal.shade700,
      'time': '1d ago',
      'title': 'Where to buy certified registered neem oil in Gbarnga or Kakata?',
      'circle': 'Bong County',
      'replies': 18,
      'likes': 11,
      'tag': 'INPUT SUPPLIES',
      'tagColor': Color(0xFF0D9488),
      'hasVerifiedOfficer': false,
      'preview': 'Looking for vetted agro-dealers who sell certified botanical extracts without synthetic contamination. Any phone contacts?',
    },
  ];

  void _showComingSoon(String actionOrTopic) {
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
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.forum_rounded, color: Color(0xFFD97706), size: 26),
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
                    actionOrTopic,
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
              'The Farmer Community & Forum is being developed to connect smallholders across Bong, Nimba, and Lofa counties for peer advice and trade.',
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
                    'What will be available on launch:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• County-level farmer discussion circles with audio voice messaging', style: TextStyle(fontSize: 12, height: 1.3)),
                  SizedBox(height: 4),
                  Text('• Direct Q&A with certified CARI Suakoko extension officers', style: TextStyle(fontSize: 12, height: 1.3)),
                  SizedBox(height: 4),
                  Text('• Real-time wholesale market price exchanges from local trading desks', style: TextStyle(fontSize: 12, height: 1.3)),
                  SizedBox(height: 4),
                  Text('• Offline SMS sync: post or reply via free SMS when internet drops', style: TextStyle(fontSize: 12, height: 1.3)),
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
                const SnackBar(
                  content: Text('You will be notified via SMS when the Farmer Community goes live!'),
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
    final filtered = _threads.where((t) {
      final matchesCircle = _selectedCircle == 'All' || t['circle'] == _selectedCircle;
      final matchesQuery = _searchQuery.isEmpty ||
          t['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t['preview'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t['author'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCircle && matchesQuery;
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
                  colors: [Color(0xFFB45309), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.2),
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
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.forum_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Farmer's Forum & Community",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Bong, Nimba, and Lofa Smallholder Peer Network',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _showComingSoon('Start a Discussion Topic'),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Color(0xFFB45309), size: 14),
                              SizedBox(width: 3),
                              Text(
                                'Post',
                                style: TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                        hintText: 'Search topics, disease reports, or market rates...',
                        hintStyle: TextStyle(color: Colors.black45, fontSize: 12),
                        prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFFD97706)),
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

            // Horizontal Circle Filter Chips
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _circles.length,
                itemBuilder: (context, idx) {
                  final circle = _circles[idx];
                  final isSelected = _selectedCircle == circle;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        circle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.darkText,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFFD97706),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade300,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCircle = circle);
                      },
                    ),
                  );
                },
              ),
            ),

            // Thread List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('No posts matching "$_searchQuery"', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final t = filtered[index];
                        return _buildThreadTile(t);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('Start Discussion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        onPressed: () => _showComingSoon('Start a Discussion Topic'),
      ),
    );
  }

  Widget _buildThreadTile(Map<String, dynamic> t) {
    final Color tagColor = t['tagColor'] as Color;
    final Color avatarColor = t['avatarColor'] as Color;

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
              // Author Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: avatarColor.withValues(alpha: 0.15),
                    child: Text(
                      t['author'][0],
                      style: TextStyle(fontWeight: FontWeight.bold, color: avatarColor, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              t['author'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkText),
                            ),
                            if (t['hasVerifiedOfficer'] == true) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 14),
                            ],
                          ],
                        ),
                        Text(
                          '${t['location']} · ${t['time']}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      t['tag'],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: tagColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                t['title'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkText, height: 1.3),
              ),
              const SizedBox(height: 6),

              // Preview Body
              Text(
                t['preview'],
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Metrics & Actions Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('${t['replies']} replies', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(width: 14),
                      Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('${t['likes']} helpful', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Reply (Coming Soon)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
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
