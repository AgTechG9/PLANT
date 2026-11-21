import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_session.dart';
import '../models/diagnostic_result.dart';
import '../services/offline_storage_service.dart';
import 'scan_screen.dart';
import 'ussd_simulator_screen.dart';
import 'offline_queue_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserSession user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _WeatherData {
  final String county;
  final IconData icon;
  final int tempMin;
  final int tempMax;
  final String condition;
  final Color iconColor;

  const _WeatherData({
    required this.county,
    required this.icon,
    required this.tempMin,
    required this.tempMax,
    required this.condition,
    required this.iconColor,
  });
}

class _AlertData {
  final String county;
  final String message;

  const _AlertData({required this.county, required this.message});
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<DiagnosticResult> _recentScans = [];
  int _pendingOfflineCount = 0;
  bool _alertDismissed = false;

  static const List<_WeatherData> _weatherCards = [
    _WeatherData(
      county: 'Bong',
      icon: Icons.wb_sunny,
      tempMin: 26,
      tempMax: 28,
      condition: 'Good for planting',
      iconColor: Colors.orange,
    ),
    _WeatherData(
      county: 'Nimba',
      icon: Icons.grain,
      tempMin: 23,
      tempMax: 25,
      condition: 'Rain expected',
      iconColor: Colors.blueAccent,
    ),
    _WeatherData(
      county: 'Lofa',
      icon: Icons.wb_sunny,
      tempMin: 24,
      tempMax: 27,
      condition: 'Good for planting',
      iconColor: Colors.orange,
    ),
  ];

  static const List<_AlertData> _countyAlerts = [
    _AlertData(
      county: 'Bong',
      message: 'Fall Armyworm alert in Suakoko district — inspect maize crops immediately.',
    ),
    _AlertData(
      county: 'Nimba',
      message: 'Cassava mosaic disease reported near Sanniquellie — avoid sharing cuttings.',
    ),
    _AlertData(
      county: 'Lofa',
      message: 'Heavy rains forecast for Voinjama — delay fertilizer application.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final history = await OfflineStorageService.getScanHistory();
    final queue = await OfflineStorageService.getQueuedScans();
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
        title: const Text('PLANT'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.user.isAdmin
                        ? Icons.admin_panel_settings
                        : widget.user.isAgent
                            ? Icons.support_agent
                            : Icons.agriculture,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.user.role,
                    style: const TextStyle(
                      color: Colors.white,
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          const ScanScreen(),
          const UssdSimulatorScreen(),
          const OfflineQueueScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          if (i == 3) _loadDashboardData();
        },
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.paleGreen,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.primaryGreen),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner, color: AppTheme.primaryGreen),
            label: 'Scan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.dialpad_outlined),
            selectedIcon: Icon(Icons.dialpad, color: AppTheme.primaryGreen),
            label: 'USSD',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _pendingOfflineCount > 0,
              label: Text('$_pendingOfflineCount'),
              child: const Icon(Icons.cloud_sync_outlined),
            ),
            selectedIcon: const Icon(Icons.cloud_sync, color: AppTheme.primaryGreen),
            label: 'Sync',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeBanner(),
            const SizedBox(height: 16),
            if (!_alertDismissed) ...[
              _buildCountyAlertBanner(),
              const SizedBox(height: 16),
            ],
            if (_pendingOfflineCount > 0) ...[
              _buildOfflineSyncPill(),
              const SizedBox(height: 16),
            ],
            const Text(
              'County Weather',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
            ),
            const SizedBox(height: 10),
            _buildWeatherRow(),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildQuickAction(
                  icon: Icons.document_scanner,
                  label: 'Scan Leaf',
                  color: AppTheme.primaryGreen,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _buildQuickAction(
                  icon: Icons.document_scanner_outlined,
                  label: 'Offline Scan',
                  color: Colors.orange.shade700,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScanScreen(isOfflineMode: true),
                    ),
                  ),
                ),
                _buildQuickAction(
                  icon: Icons.dialpad,
                  label: 'Dial *123#',
                  color: Colors.indigo.shade700,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _buildQuickAction(
                  icon: Icons.cloud_sync,
                  label: 'Sync Queue',
                  color: Colors.teal.shade700,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Scans',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                ),
                Text(
                  '${_recentScans.length} recorded',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_recentScans.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.eco_outlined, size: 48, color: Colors.black26),
                    SizedBox(height: 10),
                    Text(
                      'No scans yet.\nTap Scan Leaf to get your first AI diagnosis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ...(_recentScans.map((r) => _buildHistoryCard(r))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
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
          const Row(
            children: [
              Icon(Icons.eco_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 6),
              Text(
                'PLANT AI Assistant',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome, ${widget.user.fullName.split(' ').first}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.user.county != null
                ? '${widget.user.county} County · Group 9 · Hackathon 2026'
                : 'Group 9 · AgTech Hackathon 2026 · Liberia',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCountyAlertBanner() {
    final alert = _countyAlerts.first;
    return MaterialBanner(
      backgroundColor: Colors.amber.shade50,
      leading: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
      content: Text(
        '${alert.county}: ${alert.message}',
        style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _alertDismissed = true),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }

  Widget _buildOfflineSyncPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$_pendingOfflineCount scan(s) waiting to sync when network is available.',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _currentIndex = 3),
            child: const Text('View', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherRow() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _weatherCards.length,
        separatorBuilder: (_, i) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _buildWeatherCard(_weatherCards[index]),
      ),
    );
  }

  Widget _buildWeatherCard(_WeatherData data) {
    final isGood = data.condition == 'Good for planting';
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isGood ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGood ? Colors.green.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.county,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Icon(data.icon, color: data.iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${data.tempMin}–${data.tempMax}°C',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            data.condition,
            style: TextStyle(
              fontSize: 10,
              color: isGood ? Colors.green.shade700 : Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(DiagnosticResult r) {
    final bandColor = r.confidenceBand == 'HIGH'
        ? Colors.green.shade700
        : r.confidenceBand == 'MEDIUM'
            ? Colors.orange.shade700
            : Colors.red.shade700;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.paleGreen,
          child: Icon(Icons.eco, color: AppTheme.primaryGreen, size: 20),
        ),
        title: Text(
          r.diagnosis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${r.cropType} · ${r.severity}', style: const TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bandColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${(r.confidenceScore * 100).toInt()}%',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: bandColor),
          ),
        ),
      ),
    );
  }
}
