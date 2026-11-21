import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_session.dart';
import '../models/diagnostic_result.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';
import 'login_screen.dart';
import 'scan_screen.dart';
import 'ussd_simulator_screen.dart';
import 'offline_queue_screen.dart';
import 'learning_center_screen.dart';
import 'farmer_forum_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserSession user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<DiagnosticResult> _recentScans = [];
  int _pendingOfflineCount = 0;

  // Live data fetched for Admin & Agent
  Map<String, dynamic> _metrics = {
    'total_farmers': 10,
    'female_ratio_pct': 54.0,
    'livestock_interest_count': 3,
  };
  List<dynamic> _farmersList = [];
  List<dynamic> _triageCases = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final history = await OfflineStorageService.getScanHistory();
    final queue = await OfflineStorageService.getQueuedScans();

    if (widget.user.isAdmin || widget.user.isAgent) {
      final metrics = await ApiService.getFarmersMetrics();
      final farmers = await ApiService.getFarmers();
      final cases = await ApiService.getCases();
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _farmersList = farmers;
          _triageCases = cases;
        });
      }
    }

    if (mounted) {
      setState(() {
        _recentScans = history.take(3).toList();
        _pendingOfflineCount = queue.where((i) => !i.isSynced).length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.isAdmin
            ? 'PLANT Admin Mission Control'
            : widget.user.isAgent
                ? 'PLANT Field Agent Console'
                : 'PLANT Farmer Assistant'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _pendingOfflineCount > 0,
              label: Text('$_pendingOfflineCount'),
              child: const Icon(Icons.cloud_sync_outlined, color: Colors.white, size: 22),
            ),
            tooltip: 'Offline Sync Queue ($_pendingOfflineCount pending)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OfflineQueueScreen()),
              ).then((_) => _loadDashboardData());
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              backgroundColor: Colors.white24,
              side: BorderSide.none,
              avatar: Icon(
                widget.user.isAdmin
                    ? Icons.admin_panel_settings
                    : widget.user.isAgent
                        ? Icons.support_agent
                        : Icons.agriculture,
                color: Colors.white,
                size: 16,
              ),
              label: Text(
                widget.user.role,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            tooltip: 'Switch User / Log Out',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _buildRoleChildren(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          if (i == 0 || i == 4) _loadDashboardData();
        },
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.paleGreen,
        destinations: _buildNavDestinations(),
      ),
    );
  }

  List<Widget> _buildRoleChildren() {
    if (widget.user.isAdmin) {
      return [
        _buildRoleDashboard(),
        const ScanScreen(),
        _buildDirectoryOrTriageTab(),
        LearningCenterScreen(onNotifyPressed: _loadDashboardData),
        const OfflineQueueScreen(),
      ];
    }

    if (widget.user.isAgent) {
      return [
        _buildRoleDashboard(),
        const ScanScreen(),
        _buildDirectoryOrTriageTab(),
        LearningCenterScreen(onNotifyPressed: _loadDashboardData),
        const OfflineQueueScreen(),
      ];
    }

    // Default Farmer Screens (Indexed 0..4)
    return [
      _buildRoleDashboard(),
      const ScanScreen(),
      LearningCenterScreen(onNotifyPressed: _loadDashboardData),
      FarmerForumScreen(onNotifyPressed: _loadDashboardData),
      const UssdSimulatorScreen(),
    ];
  }

  List<NavigationDestination> _buildNavDestinations() {
    if (widget.user.isAdmin) {
      return [
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryGreen), label: 'Overview'),
        const NavigationDestination(icon: Icon(Icons.document_scanner_outlined), selectedIcon: Icon(Icons.document_scanner, color: AppTheme.primaryGreen), label: 'Scan Leaf'),
        const NavigationDestination(icon: Icon(Icons.rule_folder_outlined), selectedIcon: Icon(Icons.rule_folder, color: AppTheme.primaryGreen), label: 'Triage Desk'),
        const NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school, color: AppTheme.primaryGreen), label: 'Learning'),
        NavigationDestination(
          icon: Badge(isLabelVisible: _pendingOfflineCount > 0, label: Text('$_pendingOfflineCount'), child: const Icon(Icons.cloud_sync_outlined)),
          selectedIcon: const Icon(Icons.cloud_sync, color: AppTheme.primaryGreen),
          label: 'Sync',
        ),
      ];
    }

    if (widget.user.isAgent) {
      return [
        const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppTheme.primaryGreen), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.document_scanner_outlined), selectedIcon: Icon(Icons.document_scanner, color: AppTheme.primaryGreen), label: 'Field Scan'),
        const NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: AppTheme.primaryGreen), label: 'Farmers'),
        const NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school, color: AppTheme.primaryGreen), label: 'Learning'),
        NavigationDestination(
          icon: Badge(isLabelVisible: _pendingOfflineCount > 0, label: Text('$_pendingOfflineCount'), child: const Icon(Icons.cloud_sync_outlined)),
          selectedIcon: const Icon(Icons.cloud_sync, color: AppTheme.primaryGreen),
          label: 'Sync',
        ),
      ];
    }

    // Default Farmer Navigation (5 destinations)
    return [
      const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppTheme.primaryGreen), label: 'My Farm'),
      const NavigationDestination(icon: Icon(Icons.document_scanner_outlined), selectedIcon: Icon(Icons.document_scanner, color: AppTheme.primaryGreen), label: 'Scan Leaf'),
      const NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school, color: AppTheme.primaryGreen), label: 'Learning'),
      const NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum, color: AppTheme.primaryGreen), label: 'Community'),
      const NavigationDestination(icon: Icon(Icons.dialpad_outlined), selectedIcon: Icon(Icons.dialpad, color: AppTheme.primaryGreen), label: 'USSD *123#'),
    ];
  }

  Widget _buildRoleDashboard() {
    if (widget.user.isAdmin) return _buildAdminDashboard();
    if (widget.user.isAgent) return _buildAgentDashboard();
    return _buildFarmerDashboard();
  }

  // ==========================================
  // 1. FARMER DASHBOARD (Korto Flomo - Suakoko)
  // ==========================================
  Widget _buildFarmerDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card with textured gradient and quick status chips
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, Color(0xFF1E513A), AppTheme.mediumGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🌾', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 5),
                            Text(
                              'FARMER PORTAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.lightGreen.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off_outlined, color: Colors.white70, size: 13),
                            SizedBox(width: 4),
                            Text('Offline Ready', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Welcome back,\n${widget.user.fullName}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.earthYellow, size: 15),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Suakoko District, Bong County · 2.5 Acres Cassava',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.record_voice_over, color: AppTheme.earthYellow, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Preferred Audio: Kpelle / Liberian English',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Weather Card for Bong (Agro-Met Suakoko)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade50, Colors.orange.shade50.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.amber.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade100.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.wb_sunny_rounded, color: Colors.orange.shade900, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bong Agro-Met (Suakoko)',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 14),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Live Forecast',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '27°C · Light scattered showers expected late afternoon.',
                              style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Weather metric pills: Humidity & Planting Index
                  Row(
                    children: [
                      _buildWeatherPill(icon: Icons.water_drop_outlined, label: 'Humidity', val: '78%'),
                      const SizedBox(width: 8),
                      _buildWeatherPill(icon: Icons.air, label: 'Wind', val: '9 km/h SW'),
                      const SizedBox(width: 8),
                      _buildWeatherPill(icon: Icons.eco_outlined, label: 'Soil Cond.', val: 'Moist / Optimal'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tips_and_updates_outlined, color: Colors.orange.shade900, size: 15),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Advisory: Ideal window for cassava stem cutting & mound planting today.',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Farmer Quick Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                ),
                Text(
                  'Offline Enabled',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _buildActionCard(
                  icon: Icons.camera_alt_rounded,
                  label: 'Scan Leaf',
                  subtitle: 'Diagnose disease in field',
                  color: AppTheme.primaryGreen,
                  badge: 'AI Vision',
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _buildActionCard(
                  icon: Icons.dialpad_rounded,
                  label: 'Dial *123#',
                  subtitle: 'Feature-phone menu & IVR',
                  color: Colors.indigo.shade700,
                  badge: 'Offline',
                  onTap: () => setState(() => _currentIndex = 4),
                ),
                _buildActionCard(
                  icon: Icons.school_rounded,
                  label: 'Learning Center',
                  subtitle: 'Tutorials for farm issues',
                  color: const Color(0xFF1E7E34),
                  badge: 'SOON',
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _buildActionCard(
                  icon: Icons.forum_rounded,
                  label: "Farmer's Forum",
                  subtitle: 'Community & peer advice',
                  color: const Color(0xFFD97706),
                  badge: 'SOON',
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _buildActionCard(
                  icon: Icons.cloud_sync_rounded,
                  label: 'Sync Queue',
                  subtitle: _pendingOfflineCount > 0 ? '$_pendingOfflineCount pending items' : 'Up to date',
                  color: Colors.teal.shade700,
                  badge: _pendingOfflineCount > 0 ? '$_pendingOfflineCount Pending' : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OfflineQueueScreen()),
                    ).then((_) => _loadDashboardData());
                  },
                ),
                _buildActionCard(
                  icon: Icons.support_agent_rounded,
                  label: 'Call Agent',
                  subtitle: 'Gorpu Keller (Bong Desk)',
                  color: Colors.orange.shade900,
                  badge: 'Free Call',
                  onTap: () => _showAgentContactModal(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ==========================================
            // LEARNING CENTER PREVIEW SECTION
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E7E34).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.play_circle_fill, color: Color(0xFF1E7E34), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text('Learning Center: Tutorials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 2),
                  child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Step-by-step tutorials to solve specific farm problems in your county',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            _buildTutorialCard(
              title: 'Treating Cassava Mosaic Disease (CMD)',
              duration: '3 min · Kpelle / English',
              description: 'Learn how to rogue infected plants early and brew organic neem spray to halt whitefly transmission.',
              tag: 'CASSAVA PROBLEM SOLVER',
              tagColor: AppTheme.primaryGreen,
              icon: Icons.ondemand_video,
            ),
            const SizedBox(height: 10),
            _buildTutorialCard(
              title: 'Fall Armyworm & Pepper Anthracnose Control',
              duration: '4 min · Step-by-Step Demo',
              description: 'Proper dilution rates for registered botanical extracts and drip irrigation fungal prevention.',
              tag: 'PEST MANAGEMENT',
              tagColor: const Color(0xFFD97706),
              icon: Icons.bug_report,
            ),
            const SizedBox(height: 10),
            _buildTutorialCard(
              title: 'Healthy Stem Selection & High-Yield Planting',
              duration: '5 min · CARI Field Standard',
              description: 'How to select disease-free CARICASS cuttings and prepare raised planting mounds for rainy season.',
              tag: 'PLANTING & SOIL',
              tagColor: Colors.indigo.shade700,
              icon: Icons.grass,
            ),
            const SizedBox(height: 24),

            // ==========================================
            // FARMER COMMUNITY & FORUM SECTION
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.groups_rounded, color: Color(0xFFD97706), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text("Farmer's Community & Forum", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 3),
                  child: const Text('Open Forum', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Connect with fellow smallholders, trade tips, and ask CARI officers',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            _buildCommunityCard(
              title: 'Bong & Nimba Cassava Growers Circle',
              members: '48 active farmers',
              activity: 'Active 12m ago',
              lastPost: 'Korto F.: "Anyone seeing leaf curling in Suakoko this week after the rainfall?"',
              tag: 'COUNTY CIRCLE',
            ),
            const SizedBox(height: 10),
            _buildCommunityCard(
              title: 'Gbarnga & Monrovia Crop Price Exchange',
              members: '112 farmers & traders',
              activity: 'Updated 1 hour ago',
              lastPost: 'CARI Market Desk: "Cassava bag prices steady at Gbarnga market. Pepper in high demand."',
              tag: 'MARKET PRICES',
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 22),

            // Recent Scans Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Recent Crop Scans',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                ),
                if (_recentScans.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text('View All', style: TextStyle(fontSize: 12)),
                    onPressed: () => setState(() => _currentIndex = 1),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_recentScans.isEmpty)
              _buildEmptyScanBox()
            else
              ..._recentScans.map((r) => _buildScanHistoryTile(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherPill({required IconData icon, required String label, required String val}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: Colors.orange.shade800),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 2),
            Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. AGENT DASHBOARD (Suakoko Field Agent)
  // ==========================================
  Widget _buildAgentDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Agent Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                    blurRadius: 12,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.headset_mic_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'EXTENSION AGENT CONSOLE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 3, backgroundColor: Colors.white),
                            SizedBox(width: 5),
                            Text('FIELD ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Agent Suakoko Station', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Field Assignment: Bong County · CARI Operational Hub', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined, color: AppTheme.earthYellow, size: 16),
                        SizedBox(width: 6),
                        Text('Covering: Suakoko, Salala, Kokoyah & Zota Districts', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Agent Field Metrics
            Row(
              children: [
                _buildStatPill('Enrolled Farmers', '${_metrics['total_farmers'] ?? 10}', Icons.people_rounded, const Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                _buildStatPill('Female Ratio', '${_metrics['female_ratio_pct'] ?? 54}%', Icons.female_rounded, Colors.purple.shade700, sublabel: 'Target: ≥50%'),
                const SizedBox(width: 8),
                _buildStatPill('Livestock Interest', '${_metrics['livestock_interest_count'] ?? 3}', Icons.pets_rounded, AppTheme.mediumGreen),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Agent Field Operations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                Text('Real-time CARI Sync', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _buildActionCard(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Register Farmer',
                  subtitle: 'Enroll with gender quota',
                  color: Colors.purple.shade700,
                  badge: 'Quota 54%',
                  onTap: () => _showRegisterFarmerModal(),
                ),
                _buildActionCard(
                  icon: Icons.document_scanner_rounded,
                  label: 'Field Leaf Scan',
                  subtitle: 'Diagnose disease in field',
                  color: AppTheme.primaryGreen,
                  badge: 'AI Vision',
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _buildActionCard(
                  icon: Icons.send_to_mobile_rounded,
                  label: 'Send SMS Alert',
                  subtitle: 'County broadcast (≤160c)',
                  color: Colors.deepOrange.shade700,
                  badge: 'Telco SMS',
                  onTap: () => _showBroadcastModal(),
                ),
                _buildActionCard(
                  icon: Icons.cloud_sync_rounded,
                  label: 'Sync Queue',
                  subtitle: _pendingOfflineCount > 0 ? '$_pendingOfflineCount pending records' : 'All synced',
                  color: Colors.teal.shade700,
                  badge: _pendingOfflineCount > 0 ? '$_pendingOfflineCount Pending' : null,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
            const SizedBox(height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Enrolled Farmers in Bong', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('View All', style: TextStyle(fontSize: 12)),
                  onPressed: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_farmersList.isEmpty)
              _buildEmptyFarmerBox()
            else
              ..._farmersList.take(3).map((f) => _buildFarmerTile(f)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. ADMIN DASHBOARD (Ministry / CARI HQ)
  // ==========================================
  Widget _buildAdminDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Admin Mission Control Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 14,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, color: Colors.amber, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'NATIONAL ADMINISTRATION HQ',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                            SizedBox(width: 5),
                            Text('SYSTEMS NORMAL', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('PLANT Mission Control', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Ministry of Agriculture · CARI Suakoko Operational Hub', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hub_outlined, color: AppTheme.earthYellow, size: 15),
                        SizedBox(width: 6),
                        Text('15 Counties Connected · Orange LR & MTN Gateways Synced', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // National KPIs
            Row(
              children: [
                _buildStatPill('Total Farmers', '${_metrics['total_farmers'] ?? 10}', Icons.groups_rounded, const Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                _buildStatPill(
                  'Pending Triage',
                  '${_triageCases.length}',
                  Icons.pending_actions_rounded,
                  _triageCases.isNotEmpty ? const Color(0xFFDC2626) : Colors.grey.shade700,
                  sublabel: _triageCases.isNotEmpty ? 'Action needed' : 'All clear',
                ),
                const SizedBox(width: 8),
                _buildStatPill('SMS Gateway', 'ONLINE', Icons.cell_tower_rounded, const Color(0xFF16A34A), sublabel: '99.9% Uptime'),
              ],
            ),
            const SizedBox(height: 20),

            // Master Triage Console Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.orange.shade50.withValues(alpha: 0.5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.red.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade100.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Master Escalation Workbench', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 15)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_triageCases.length} Escaped AI',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Review flagged scans (<65% confidence & blurry photos) and dispatch CARI-verified SMS to smallholders under Rule SCAN-04.',
                              style: TextStyle(color: Colors.red.shade900.withValues(alpha: 0.85), fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.menu_book_rounded, size: 16),
                          label: const Text('Knowledge Base', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade900,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _showKnowledgeBaseModal(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.rule_folder_rounded, size: 16, color: Colors.white),
                          label: const Text('Open Desk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => setState(() => _currentIndex = 2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Administrative Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                Text('Mission Control', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _buildActionCard(
                  icon: Icons.rule_folder_rounded,
                  label: 'Triage Desk',
                  subtitle: '${_triageCases.length} flagged diagnoses',
                  color: Colors.red.shade700,
                  badge: '${_triageCases.length} Alert',
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _buildActionCard(
                  icon: Icons.menu_book_rounded,
                  label: 'Knowledge Base',
                  subtitle: 'CARI vetted bulletins',
                  color: Colors.teal.shade700,
                  badge: 'CARI',
                  onTap: () => _showKnowledgeBaseModal(),
                ),
                _buildActionCard(
                  icon: Icons.cell_tower_rounded,
                  label: 'SMS Dispatch',
                  subtitle: 'Single segment ≤160c',
                  color: Colors.deepOrange.shade700,
                  badge: 'Orange/MTN',
                  onTap: () => _showBroadcastModal(),
                ),
                _buildActionCard(
                  icon: Icons.document_scanner_rounded,
                  label: 'Test Vision AI',
                  subtitle: 'Run diagnostic benchmark',
                  color: AppTheme.primaryGreen,
                  badge: 'YOLOv8',
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SHARED MODALS & HELPERS
  // ==========================================
  Widget _buildDirectoryOrTriageTab() {
    if (widget.user.isAdmin) {
      return _buildTriageQueueView();
    }
    return _buildFarmersDirectoryView();
  }

  Widget _buildTriageQueueView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Master Escalation Triage Desk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                  const SizedBox(height: 2),
                  Text('Rule SCAN-04 (<65% confidence or blurry) · ${_triageCases.length} pending', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh queue',
                onPressed: _loadDashboardData,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_triageCases.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.paleGreen.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: AppTheme.primaryGreen, size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text('All Escalated Cases Resolved', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkText)),
                  const SizedBox(height: 4),
                  const Text('No low-confidence scans currently require human agronomist verification.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            )
          else
            ..._triageCases.map((c) => _buildTriageCaseCard(c)),
        ],
      ),
    );
  }

  Widget _buildTriageCaseCard(dynamic c) {
    final confPct = ((c['ai_confidence'] ?? 0.5) * 100).toInt();
    final isVeryLow = confPct < 50;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.flag_rounded, color: Colors.red.shade700, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(c['case_number'] ?? 'CASE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkText)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isVeryLow ? Colors.red.shade700 : Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$confPct% CONFIDENCE',
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text('Farmer: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text('${c['farmer_name'] ?? "Anonymous"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                const Spacer(),
                Icon(Icons.eco_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${c['crop_type'] ?? "Cassava"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.psychology_outlined, size: 18, color: Colors.red.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Tentative Diagnosis: ${c['ai_diagnosis']}',
                      style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                label: const Text('Resolve & Send Verified SMS (Rule ADV-01)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _resolveCaseDialog(c['id'].toString(), c['case_number'].toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmersDirectoryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enrolled Farmers Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                  const SizedBox(height: 2),
                  Text('${_farmersList.length} smallholders across Bong, Nimba & Lofa', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh directory',
                onPressed: _loadDashboardData,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_farmersList.isEmpty)
            _buildEmptyFarmerBox()
          else
            ..._farmersList.map((f) => _buildFarmerTile(f)),
        ],
      ),
    );
  }

  Widget _buildEmptyFarmerBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline, color: Colors.blue.shade700, size: 30),
          ),
          const SizedBox(height: 10),
          const Text('No Farmers Enrolled Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkText)),
          const SizedBox(height: 4),
          const Text('Tap "Register Farmer" above to enroll smallholders into the CARI registry.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFarmerTile(dynamic f) {
    final isFemale = f['gender'] == 'female';
    final avatarColor = isFemale ? Colors.purple.shade600 : const Color(0xFF1E3A8A);
    final avatarBg = isFemale ? Colors.purple.shade50 : Colors.blue.shade50;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: avatarBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(isFemale ? Icons.female_rounded : Icons.male_rounded, color: avatarColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          f['full_name'] ?? 'Unknown Farmer',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          f['registered_via'] ?? 'AGENT',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${f['county']} · ${f['district']} · Phone: ${f['phone_number']}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.paleGreen.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                f['preferred_language'] ?? 'Kpelle',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resolveCaseDialog(String id, String caseNum) {
    final noteController = TextEditingController(text: 'Verified by CARI Extension Officer. CMD early chlorosis symptoms.');
    final smsController = TextEditingController(text: 'CARI Suakoko Alert: Uproot diseased cassava plant immediately. Spray neem oil for whiteflies. Call extension agent.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Resolve $caseNum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Officer Diagnostic Notes')),
            const SizedBox(height: 10),
            TextField(controller: smsController, maxLines: 2, decoration: const InputDecoration(labelText: '160-char SMS to Farmer (Rule ADV-01)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await ApiService.resolveCase(id, noteController.text, smsController.text, true);
              nav.pop();
              _loadDashboardData();
              messenger.showSnackBar(const SnackBar(content: Text('Case resolved & 160-char SMS dispatched to farmer.')));
            },
            child: const Text('Dispatch SMS & Close'),
          ),
        ],
      ),
    );
  }

  void _showRegisterFarmerModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+231');
    final districtCtrl = TextEditingController();
    String county = 'Bong';
    String gender = 'female';
    bool livestock = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Register Smallholder Farmer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Farmer Full Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Orange / MTN Phone Number')),
              TextField(controller: districtCtrl, decoration: const InputDecoration(labelText: 'District (e.g. Suakoko, Salala)')),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Gender: '),
                  ChoiceChip(
                    label: const Text('Female (54% quota)', style: TextStyle(fontSize: 11)),
                    selected: gender == 'female',
                    onSelected: (v) {
                      if (v) setModalState(() => gender = 'female');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Male', style: TextStyle(fontSize: 11)),
                    selected: gender == 'male',
                    onSelected: (v) {
                      if (v) setModalState(() => gender = 'male');
                    },
                  ),
                ],
              ),
              CheckboxListTile(
                title: const Text('Interested in Livestock Vaccination Alerts (Rule REG-03)'),
                value: livestock,
                onChanged: (v) => setModalState(() => livestock = v ?? false),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  onPressed: () async {
                    final nav = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    await ApiService.registerFarmer(
                      fullName: nameCtrl.text.isEmpty ? 'New Farmer' : nameCtrl.text,
                      phone: phoneCtrl.text,
                      county: county,
                      district: districtCtrl.text.isEmpty ? 'Suakoko' : districtCtrl.text,
                      gender: gender,
                      crop: 'Cassava',
                      livestock: livestock,
                    );
                    nav.pop();
                    _loadDashboardData();
                    messenger.showSnackBar(const SnackBar(content: Text('Farmer registered in CARI directory.')));
                  },
                  child: const Text('Save Registration', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showBroadcastModal() {
    final msgCtrl = TextEditingController(text: 'CARI Suakoko Alert: Fall Armyworm spotted in Bong. Spray registered botanical neem extract.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Emergency SMS Broadcast'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dispatches single-segment (≤160-char) SMS to all active farmers in county.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(controller: msgCtrl, maxLines: 3, maxLength: 160, decoration: const InputDecoration(border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS Broadcast transmitted to Orange LR / MTN gateway.')));
            },
            child: const Text('Transmit Broadcast', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showKnowledgeBaseModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CARI Vetted Knowledge Bulletins'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• CARI-CAS-001: Cassava Mosaic Disease (CMD) - Roguing & Neem oil'),
            SizedBox(height: 6),
            Text('• CARI-CAS-002: Cassava Brown Streak Disease (CBSD) - CARICASS 1/2 tolerance'),
            SizedBox(height: 6),
            Text('• CARI-PEP-001: Pepper Anthracnose - Mancozeb / drip irrigation'),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAgentContactModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('County Extension Office'),
        content: const Text('Bong County Extension Officer: Gorpu Keller\nStation: CARI Suakoko Operational Desk\nPhone: +231 770 123 456'),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Call Agent')),
        ],
      ),
    );
  }

  Widget _buildStatPill(String title, String val, IconData icon, Color color, {String? sublabel}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            if (sublabel != null) ...[
              const SizedBox(height: 2),
              Text(sublabel, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
    String? badge,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: color.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyScanBox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.paleGreen.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.document_scanner_outlined, color: AppTheme.primaryGreen, size: 28),
          ),
          const SizedBox(height: 10),
          const Text(
            'No crop scans recorded yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkText),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "Scan Leaf" above to diagnose cassava, maize, or vegetable diseases in the field.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildScanHistoryTile(DiagnosticResult r) {
    final isHigh = r.confidenceBand == 'HIGH';
    final statusColor = isHigh ? AppTheme.primaryGreen : Colors.orange.shade800;
    final statusBg = isHigh ? AppTheme.paleGreen : Colors.orange.shade50;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.eco_rounded, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.diagnosis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${r.cropType} · ${(r.confidenceScore * 100).toInt()}% match',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                r.confidenceBand,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInDevelopmentDialog({
    required String title,
    required String subtitle,
    required IconData icon,
    required String tag,
    required List<String> features,
  }) {
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
              child: Icon(icon, color: AppTheme.primaryGreen, size: 26),
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
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
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
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What will be available soon:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                f,
                                style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      )),
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
                  content: Text('Thanks! You will be notified when $title goes live.'),
                  backgroundColor: AppTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Notify Me', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard({
    required String title,
    required String duration,
    required String description,
    required String tag,
    required Color tagColor,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _showInDevelopmentDialog(
        title: title,
        subtitle: 'Watch actionable video tutorials to solve practical crop problems.',
        icon: Icons.ondemand_video_rounded,
        tag: 'LEARNING CENTER',
        features: [
          'High-definition video demonstration with step-by-step closeups',
          'Voiceover audio available in Simple Liberian English, Kpelle, and Bassa',
          'Offline downloadable video package (under 12MB per tutorial)',
          'Approved by Central Agricultural Research Institute (CARI Suakoko)',
        ],
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tagColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: tagColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 12, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                            duration,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkText),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.play_circle_outline, size: 14, color: AppTheme.primaryGreen),
                      const SizedBox(width: 4),
                      const Text(
                        'Watch Tutorial (Coming Soon)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard({
    required String title,
    required String members,
    required String activity,
    required String lastPost,
    required String tag,
  }) {
    return InkWell(
      onTap: () => _showInDevelopmentDialog(
        title: title,
        subtitle: 'Connect, share advice, and solve problems with fellow farmers.',
        icon: Icons.groups_rounded,
        tag: 'FARMER COMMUNITY',
        features: [
          'Peer chat with verified smallholders in Bong, Nimba, and Lofa counties',
          'Live crop selling prices and transport cost sharing across districts',
          'Direct assistance from local agriculture extension workers and CARI officers',
        ],
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD97706),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Text(
                  activity,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkText),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 13, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  members,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 13, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lastPost,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
