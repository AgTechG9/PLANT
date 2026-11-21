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
        children: [
          _buildRoleDashboard(),
          const ScanScreen(),
          if (widget.user.isFarmer) const UssdSimulatorScreen() else _buildDirectoryOrTriageTab(),
          const OfflineQueueScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          if (i == 0 || i == 3) _loadDashboardData();
        },
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.paleGreen,
        destinations: _buildNavDestinations(),
      ),
    );
  }

  List<NavigationDestination> _buildNavDestinations() {
    if (widget.user.isAdmin) {
      return [
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryGreen), label: 'Overview'),
        const NavigationDestination(icon: Icon(Icons.document_scanner_outlined), selectedIcon: Icon(Icons.document_scanner, color: AppTheme.primaryGreen), label: 'Scan Leaf'),
        const NavigationDestination(icon: Icon(Icons.rule_folder_outlined), selectedIcon: Icon(Icons.rule_folder, color: AppTheme.primaryGreen), label: 'Triage Desk'),
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
        NavigationDestination(
          icon: Badge(isLabelVisible: _pendingOfflineCount > 0, label: Text('$_pendingOfflineCount'), child: const Icon(Icons.cloud_sync_outlined)),
          selectedIcon: const Icon(Icons.cloud_sync, color: AppTheme.primaryGreen),
          label: 'Sync',
        ),
      ];
    }

    // Default Farmer Navigation
    return [
      const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppTheme.primaryGreen), label: 'My Farm'),
      const NavigationDestination(icon: Icon(Icons.document_scanner_outlined), selectedIcon: Icon(Icons.document_scanner, color: AppTheme.primaryGreen), label: 'Scan Leaf'),
      const NavigationDestination(icon: Icon(Icons.dialpad_outlined), selectedIcon: Icon(Icons.dialpad, color: AppTheme.primaryGreen), label: 'USSD *123#'),
      NavigationDestination(
        icon: Badge(isLabelVisible: _pendingOfflineCount > 0, label: Text('$_pendingOfflineCount'), child: const Icon(Icons.cloud_sync_outlined)),
        selectedIcon: const Icon(Icons.cloud_sync, color: AppTheme.primaryGreen),
        label: 'Sync',
      ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.mediumGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌾 FARMER PORTAL', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  Text('Welcome, ${widget.user.fullName}!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Suakoko District, Bong County · 2.5 Acres Cassava', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.record_voice_over, color: AppTheme.earthYellow, size: 16),
                        SizedBox(width: 6),
                        Text('Preferred Language: Kpelle / Liberian English', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Weather Card for Bong
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.wb_sunny, color: Colors.orange.shade800, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bong County Agro-Met (Suakoko)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('27°C · Scattered showers · Excellent conditions for cassava stem planting.', style: TextStyle(fontSize: 12, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Farmer Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(icon: Icons.camera_alt, label: 'Scan Leaf', color: AppTheme.primaryGreen, onTap: () => setState(() => _currentIndex = 1)),
                _buildActionCard(icon: Icons.dialpad, label: 'Dial *123# Offline', color: Colors.indigo.shade700, onTap: () => setState(() => _currentIndex = 2)),
                _buildActionCard(icon: Icons.cloud_sync, label: 'Sync Queue', color: Colors.teal.shade700, onTap: () => setState(() => _currentIndex = 3)),
                _buildActionCard(icon: Icons.contact_phone, label: 'Call Agent', color: Colors.orange.shade800, onTap: () => _showAgentContactModal()),
              ],
            ),
            const SizedBox(height: 20),

            const Text('My Recent Scans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎧 FIELD AGENT CONSOLE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  Text('Agent Suakoko Station', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Field Assignment: Bong County · CARI Operational Hub', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Agent Field Metrics
            Row(
              children: [
                _buildStatPill('Enrolled', '${_metrics['total_farmers'] ?? 10}', Icons.people, Colors.blue.shade800),
                const SizedBox(width: 8),
                _buildStatPill('Female %', '${_metrics['female_ratio_pct'] ?? 54}%', Icons.female, Colors.purple.shade800),
                const SizedBox(width: 8),
                _buildStatPill('Livestock', '${_metrics['livestock_interest_count'] ?? 3}', Icons.pets, Colors.green.shade800),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Agent Field Operations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildActionCard(icon: Icons.person_add_alt_1, label: 'Register Farmer', color: Colors.purple.shade700, onTap: () => _showRegisterFarmerModal()),
                _buildActionCard(icon: Icons.document_scanner, label: 'Field Leaf Scan', color: AppTheme.primaryGreen, onTap: () => setState(() => _currentIndex = 1)),
                _buildActionCard(icon: Icons.send_to_mobile, label: 'Send SMS Alert', color: Colors.deepOrange.shade700, onTap: () => _showBroadcastModal()),
                _buildActionCard(icon: Icons.cloud_sync, label: 'Sync Queue', color: Colors.teal.shade700, onTap: () => setState(() => _currentIndex = 3)),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Enrolled Farmers in Bong', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => setState(() => _currentIndex = 2), child: const Text('View All')),
              ],
            ),
            ..._farmersList.take(3).map((f) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: f['gender'] == 'female' ? Colors.purple.shade100 : Colors.blue.shade100,
                      child: Icon(f['gender'] == 'female' ? Icons.female : Icons.male, color: Colors.black87),
                    ),
                    title: Text(f['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${f['county']} · ${f['district']} · Phone: ${f['phone_number']}'),
                    trailing: Chip(
                      label: Text(f['registered_via'] ?? 'AGENT', style: const TextStyle(fontSize: 10)),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                )),
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
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🏛️ NATIONAL ADMINISTRATION HQ', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  SizedBox(height: 6),
                  Text('PLANT Mission Control', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Ministry of Agriculture · CARI Suakoko Operational Hub', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // National KPIs
            Row(
              children: [
                _buildStatPill('Total Farmers', '${_metrics['total_farmers'] ?? 10}', Icons.groups, Colors.indigo.shade800),
                const SizedBox(width: 8),
                _buildStatPill('Pending Triage', '${_triageCases.length}', Icons.pending_actions, Colors.red.shade800),
                const SizedBox(width: 8),
                _buildStatPill('SMS Gateway', 'ONLINE', Icons.cell_tower, Colors.green.shade800),
              ],
            ),
            const SizedBox(height: 20),

            // Master Triage Console Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Master Escalation Workbench', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Review flagged scans (<65% confidence & blurry photos) and dispatch CARI-verified SMS to farmers.',
                            style: TextStyle(color: Colors.red.shade900, fontSize: 12, height: 1.3)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
                    onPressed: () => setState(() => _currentIndex = 2),
                    child: const Text('Triage', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Administrative Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildActionCard(icon: Icons.rule_folder, label: 'Triage Queue', color: Colors.red.shade700, onTap: () => setState(() => _currentIndex = 2)),
                _buildActionCard(icon: Icons.menu_book, label: 'CARI Knowledge Base', color: Colors.teal.shade700, onTap: () => _showKnowledgeBaseModal()),
                _buildActionCard(icon: Icons.cell_tower, label: 'Telco SMS Dispatch', color: Colors.deepOrange.shade700, onTap: () => _showBroadcastModal()),
                _buildActionCard(icon: Icons.document_scanner, label: 'Test Vision AI', color: AppTheme.primaryGreen, onTap: () => setState(() => _currentIndex = 1)),
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
              const Text('Master Escalation Triage Desk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDashboardData),
            ],
          ),
          const Text('Cases auto-escalated under Rule SCAN-04 (<65% confidence or blurry).', style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 16),
          if (_triageCases.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No pending escalated cases.')))
          else
            ..._triageCases.map((c) => Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.red.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c['case_number'] ?? 'CASE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Chip(
                              label: Text('${((c['ai_confidence'] ?? 0.5) * 100).toInt()}% CONFIDENCE', style: const TextStyle(fontSize: 10, color: Colors.white)),
                              backgroundColor: Colors.red.shade700,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Farmer: ${c['farmer_name'] ?? "Anonymous"} · Crop: ${c['crop_type']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('AI Finding: ${c['ai_diagnosis']}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Resolve & Send Verified SMS (Rule ADV-01)'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                          onPressed: () => _resolveCaseDialog(c['id'].toString(), c['case_number'].toString()),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
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
              const Text('Enrolled Farmers Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDashboardData),
            ],
          ),
          const Text('Live smallholders across Bong, Nimba, and Lofa counties.', style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 16),
          ..._farmersList.map((f) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: f['gender'] == 'female' ? Colors.purple.shade100 : Colors.blue.shade100,
                    child: Icon(f['gender'] == 'female' ? Icons.female : Icons.male, color: Colors.black87),
                  ),
                  title: Text(f['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${f['county']} County · ${f['district']} · Phone: ${f['phone_number']}'),
                  trailing: Text(f['preferred_language'] ?? 'Kpelle', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ),
              )),
        ],
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

  Widget _buildStatPill(String title, String val, IconData icon, Color color) {
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
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScanBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: const Center(child: Text('No scans yet. Tap Scan Leaf to diagnose your crop.', style: TextStyle(color: Colors.black45, fontSize: 12))),
    );
  }

  Widget _buildScanHistoryTile(DiagnosticResult r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.eco, color: r.confidenceBand == 'HIGH' ? Colors.green : Colors.orange),
        title: Text(r.diagnosis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('${r.cropType} · Confidence: ${(r.confidenceScore * 100).toInt()}%'),
        trailing: Text(r.confidenceBand, style: TextStyle(color: r.confidenceBand == 'HIGH' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
