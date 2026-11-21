import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/sync_item.dart';
import '../services/offline_storage_service.dart';

class OfflineQueueScreen extends StatefulWidget {
  const OfflineQueueScreen({super.key});

  @override
  State<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends State<OfflineQueueScreen> {
  List<SyncItem> _items = [];
  bool _isLoading = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    final list = await OfflineStorageService.getQueuedScans();
    setState(() {
      _items = list;
      _isLoading = false;
    });
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final count = await OfflineStorageService.syncAllPending();
    setState(() => _isSyncing = false);

    if (!mounted) return;

    final message = count > 0 ? 'Successfully synced $count scan${count == 1 ? '' : 's'} to cloud' : 'All scans are already synced';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              count > 0 ? Icons.check_circle_outline : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: count > 0 ? AppTheme.mediumGreen : const Color(0xFF374151),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    _loadQueue();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _items.where((i) => !i.isSynced).length;
    final syncedCount = _items.where((i) => i.isSynced).length;

    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      appBar: AppBar(
        title: const Text('Offline Sync Queue'),
        actions: [
          IconButton(
            tooltip: 'Refresh Queue',
            icon: const Icon(Icons.refresh),
            onPressed: (_isLoading || _isSyncing) ? null : _loadQueue,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
            )
          : Column(
              children: [
                _SummaryCard(
                  pendingCount: pendingCount,
                  syncedCount: syncedCount,
                  isSyncing: _isSyncing,
                ),
                if (_isSyncing)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        backgroundColor: AppTheme.paleGreen,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                        minHeight: 6,
                      ),
                    ),
                  ),
                if (pendingCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSyncing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined, size: 22),
                        label: Text(
                          _isSyncing
                              ? 'Syncing Scans to Cloud…'
                              : 'Sync $pendingCount Pending Scan${pendingCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSyncing ? null : _syncNow,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    color: AppTheme.primaryGreen,
                    onRefresh: _syncNow,
                    child: _items.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _SyncItemTile(item: _items[index]),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.pendingCount,
    required this.syncedCount,
    required this.isSyncing,
  });

  final int pendingCount;
  final int syncedCount;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingCount > 0;
    final primaryColor = hasPending ? const Color(0xFFD97706) : AppTheme.mediumGreen;
    final bgColor = hasPending ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4);
    final borderColor = hasPending ? const Color(0xFFFDE68A) : AppTheme.paleGreen;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSyncing
                  ? Icons.sync
                  : (hasPending ? Icons.cloud_queue_rounded : Icons.cloud_done_rounded),
              color: primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasPending
                            ? '$pendingCount Offline Scan${pendingCount == 1 ? '' : 's'} Queued'
                            : 'All Scans Synchronized',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: hasPending ? const Color(0xFF92400E) : AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    if (syncedCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.paleGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$syncedCount synced',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasPending
                      ? 'Captured in field without internet. Connect to cellular/Wi-Fi to submit diagnostics to cloud.'
                      : 'All field diagnostic records and telemetry are backed up safely.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncItemTile extends StatelessWidget {
  const _SyncItemTile({required this.item});

  final SyncItem item;

  Widget _buildThumbnail() {
    Widget? imageWidget;

    if (item.imageBase64 != null && item.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(item.imageBase64!);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 50,
          height: 50,
          errorBuilder: (_, _, _) => _buildFallbackThumbnail(),
        );
      } catch (_) {
        imageWidget = null;
      }
    } else if (item.localPath != null && item.localPath!.isNotEmpty) {
      try {
        final file = File(item.localPath!);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: BoxFit.cover,
            width: 50,
            height: 50,
            errorBuilder: (_, _, _) => _buildFallbackThumbnail(),
          );
        }
      } catch (_) {
        imageWidget = null;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 50,
        height: 50,
        child: imageWidget ?? _buildFallbackThumbnail(),
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    final isSynced = item.isSynced;
    return Container(
      color: isSynced ? AppTheme.paleGreen : const Color(0xFFFEF3C7),
      child: Center(
        child: Icon(
          Icons.eco_rounded,
          color: isSynced ? AppTheme.mediumGreen : const Color(0xFFD97706),
          size: 26,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSynced = item.isSynced;
    final timeStr =
        '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';
    final dateStr = '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSynced ? Colors.grey.shade200 : const Color(0xFFFDE68A),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _buildThumbnail(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.cropType} Diagnostic',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusChip(isSynced: isSynced),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$dateStr · $timeStr',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        isSynced ? Icons.cloud_done_outlined : Icons.offline_pin_outlined,
                        size: 13,
                        color: isSynced ? AppTheme.mediumGreen : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isSynced
                              ? (item.caseNumber != null
                                  ? 'Case Ref: ${item.caseNumber}'
                                  : 'Stored on cloud server')
                              : 'Saved locally · Ready to upload',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSynced ? FontWeight.normal : FontWeight.w500,
                            color: isSynced ? Colors.grey.shade700 : const Color(0xFFB45309),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isSynced});

  final bool isSynced;

  @override
  Widget build(BuildContext context) {
    final bgColor = isSynced ? AppTheme.paleGreen : const Color(0xFFFEF3C7);
    final fgColor = isSynced ? AppTheme.primaryGreen : const Color(0xFFB45309);
    final label = isSynced ? 'Synced' : 'Pending';
    final icon = isSynced ? Icons.check_circle_rounded : Icons.pending_actions_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.paleGreen.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_done_outlined,
                        size: 48,
                        color: AppTheme.mediumGreen,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Scans in Queue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All local diagnostic scans have been synced with the cloud, or no scans have been performed yet.\nCapture leaf scans in the field to diagnose crop health.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
