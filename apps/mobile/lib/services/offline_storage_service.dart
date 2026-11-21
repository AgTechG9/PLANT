import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sync_item.dart';
import '../models/diagnostic_result.dart';
import 'api_service.dart';

class OfflineStorageService {
  static const String _queueKey = 'plant_offline_sync_queue';
  static const String _historyKey = 'plant_scan_history';

  // 1. Queue a scan for later sync
  static Future<void> queueScan(SyncItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getQueuedScans();
    items.insert(0, item);
    final jsonList = items.map((i) => i.toJson()).toList();
    await prefs.setStringList(_queueKey, jsonList);
  }

  // 2. Get all queued scans
  static Future<List<SyncItem>> getQueuedScans() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_queueKey) ?? [];
    return list.map((str) => SyncItem.fromJson(str)).toList();
  }

  // 3. Clear or sync queue
  static Future<int> syncAllPending() async {
    final items = await getQueuedScans();
    final pending = items.where((i) => !i.isSynced).toList();
    if (pending.isEmpty) return 0;

    int syncedCount = 0;
    final List<SyncItem> updated = [];

    for (var item in items) {
      if (!item.isSynced) {
        try {
          final res = await ApiService.diagnoseCrop(
            cropType: item.cropType,
            localImagePath: item.localPath,
          );
          updated.add(SyncItem(
            id: item.id,
            cropType: item.cropType,
            localPath: item.localPath,
            createdAt: item.createdAt,
            isSynced: true,
            caseNumber: res.caseNumber ?? 'SYNCED-OK',
          ));
          syncedCount++;
        } catch (_) {
          updated.add(item);
        }
      } else {
        updated.add(item);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_queueKey, updated.map((i) => i.toJson()).toList());
    return syncedCount;
  }

  // 4. Save recent scan result
  static Future<void> saveScanHistory(DiagnosticResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];
    list.insert(0, jsonEncode(result.toJson()));
    if (list.length > 20) list.removeLast(); // Keep top 20
    await prefs.setStringList(_historyKey, list);
  }

  // 5. Get recent scan history
  static Future<List<DiagnosticResult>> getScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];
    return list.map((str) => DiagnosticResult.fromJson(jsonDecode(str))).toList();
  }
}
