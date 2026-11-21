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

    final message = count > 0 ? 'Synced $count item${count == 1 ? '' : 's'}' : 'Nothing to sync';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
    _loadQueue();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _items.where((i) => !i.isSynced).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadQueue,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _SummaryCard(pendingCount: pendingCount),
                if (_isSyncing)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                if (pendingCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSyncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync),
                        label: Text(_isSyncing ? 'Syncing…' : 'Sync $pendingCount Scans to Cloud'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isSyncing ? null : _syncNow,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _syncNow,
                    child: _items.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
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
  const _SummaryCard({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingCount > 0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasPending ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasPending ? Colors.orange.shade300 : Colors.green.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPending ? Icons.cloud_queue : Icons.cloud_done,
            color: hasPending ? Colors.orange.shade800 : Colors.green.shade800,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPending ? '$pendingCount Pending Uploads' : 'All Scans Synchronized',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: hasPending ? Colors.orange.shade900 : Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasPending
                      ? 'Captured offline in field. Connect to network to upload.'
                      : 'All records are fully up-to-date.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isSynced ? Colors.green.shade100 : Colors.orange.shade100,
          child: Icon(
            item.isSynced ? Icons.check : Icons.access_time,
            color: item.isSynced ? Colors.green.shade800 : Colors.orange.shade800,
            size: 20,
          ),
        ),
        title: Text(
          '${item.cropType} Leaf Scan',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          'Recorded ${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2, '0')} · '
          '${item.isSynced ? (item.caseNumber ?? 'Uploaded') : 'Pending network'}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          item.isSynced ? 'Synced' : 'Offline',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: item.isSynced ? Colors.green.shade800 : Colors.orange.shade800,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 80),
        Center(
          child: Text(
            'No scans in the local queue yet.\nUse the camera to capture leaves.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45),
          ),
        ),
      ],
    );
  }
}
