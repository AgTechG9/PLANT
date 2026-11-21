import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';
import '../models/sync_item.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  final bool isOfflineMode;

  const ScanScreen({super.key, this.isOfflineMode = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _webImageBytes;
  String _selectedCrop = 'Cassava';
  bool _isAnalyzing = false;

  // Hackathon presentation simulation dials
  bool _simulateBlurry = false;
  double _simulatedConfidence = 0.88;
  bool _showDemoControls = false;

  final List<String> _crops = ['Cassava', 'Pepper', 'Maize'];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          setState(() {
            _selectedImage = file;
            _webImageBytes = bytes;
          });
        } else {
          setState(() {
            _selectedImage = file;
            _webImageBytes = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _runScan() async {
    setState(() => _isAnalyzing = true);

    if (widget.isOfflineMode) {
      await Future.delayed(const Duration(milliseconds: 900));
      final syncItem = SyncItem(
        id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
        cropType: _selectedCrop,
        localPath: _selectedImage?.path,
        createdAt: DateTime.now(),
        isSynced: false,
      );
      await OfflineStorageService.queueScan(syncItem);
    }

    final result = await ApiService.diagnoseCrop(
      cropType: _selectedCrop,
      isBlurry: _simulateBlurry,
      simulatedConfidence: _simulatedConfidence,
      localImagePath: _selectedImage?.path,
    );

    await OfflineStorageService.saveScanHistory(result);

    setState(() => _isAnalyzing = false);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: result, isOfflineResult: widget.isOfflineMode),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 64, color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text(
            'Place leaf inside frame\nEnsure bright, even light',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: kIsWeb
          ? Image.memory(
              _webImageBytes!,
              fit: BoxFit.cover,
            )
          : Image.file(
              File(_selectedImage!.path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.image, size: 64, color: Colors.green)),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Leaf Scanner'),
        actions: [
          IconButton(
            icon: Icon(
              _showDemoControls ? Icons.tune : Icons.tune_outlined,
              color: _showDemoControls ? AppTheme.earthYellow : Colors.white,
            ),
            tooltip: 'Hackathon Demo Dials',
            onPressed: () => setState(() => _showDemoControls = !_showDemoControls),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_showDemoControls)
              Container(
                color: Colors.amber.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚡ HACKATHON LIVE DEMO DIALS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _simulateBlurry,
                          onChanged: (v) => setState(() => _simulateBlurry = v ?? false),
                        ),
                        const Text('Simulate Blurry Photo (Rule SCAN-04)', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Confidence: ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Slider(
                            value: _simulatedConfidence,
                            min: 0.30,
                            max: 0.98,
                            divisions: 14,
                            label: '${(_simulatedConfidence * 100).toInt()}%',
                            onChanged: (v) => setState(() => _simulatedConfidence = v),
                          ),
                        ),
                        Text(
                          '${(_simulatedConfidence * 100).toInt()}% ${_simulatedConfidence < 0.65 ? '(Escalate)' : '(Pass)'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _simulatedConfidence < 0.65 ? Colors.red : Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            Container(
              height: 320,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImagePreview(),

                  Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white70, width: 2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),

                  if (widget.isOfflineMode)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'OFFLINE QUEUE',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose Photo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppTheme.primaryGreen),
                      ),
                      onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                      onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Target Crop:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _crops.map((c) {
                      final isSelected = _selectedCrop == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            c + (c == 'Maize' ? ' (Test Warning)' : ''),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryGreen,
                          onSelected: (val) {
                            if (val) setState(() => _selectedCrop = c);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAnalyzing ? null : _runScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 3,
                  ),
                  child: _isAnalyzing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Analyzing Leaf Features...', style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.document_scanner),
                            SizedBox(width: 8),
                            Text('Run AI Diagnostic', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
