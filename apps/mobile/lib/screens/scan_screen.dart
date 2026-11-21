import 'dart:convert';
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
  String _selectedCrop = 'AUTO';
  bool _isAnalyzing = false;
  String? _sampleImageUrl;

  // Hackathon presentation simulation dials
  bool _simulateBlurry = false;
  double _simulatedConfidence = 0.88;
  bool _showDemoControls = false;

  final List<String> _crops = ['AUTO', 'Cassava', 'Pepper', 'Maize'];

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

  void _loadSample(String crop, double conf, bool blurry, String imageUrl) {
    setState(() {
      _selectedCrop = crop;
      _simulatedConfidence = conf;
      _simulateBlurry = blurry;
      _sampleImageUrl = imageUrl;
      _selectedImage = null;
      _webImageBytes = null;
    });
  }

  void _runScan() async {
    setState(() => _isAnalyzing = true);

    String? b64Image;
    if (_webImageBytes != null) {
      b64Image = base64Encode(_webImageBytes!);
    } else if (_selectedImage != null) {
      try {
        final bytes = await _selectedImage!.readAsBytes();
        b64Image = base64Encode(bytes);
      } catch (e) {
        debugPrint('Error reading image bytes: $e');
      }
    }

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
      imageBase64: b64Image,
      imageUrl: _sampleImageUrl,
      isBlurry: _simulateBlurry,
      simulatedConfidence: _showDemoControls ? _simulatedConfidence : null,
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
    if (_selectedImage == null && _sampleImageUrl == null) {
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

    if (_sampleImageUrl != null && _selectedImage == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          _sampleImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.eco, size: 64, color: Colors.green),
          ),
        ),
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
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Or load a live pitch sample:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Text('🌿', style: TextStyle(fontSize: 14)),
                        label: const Text('Cassava CMD', style: TextStyle(fontSize: 11)),
                        onPressed: _isAnalyzing
                            ? null
                            : () => _loadSample(
                                  'Cassava',
                                  0.92,
                                  false,
                                  'https://images.unsplash.com/photo-1599818816942-e1c251d1847e?auto=format&fit=crop&w=600&q=80',
                                ),
                      ),
                      ActionChip(
                        avatar: const Text('🫑', style: TextStyle(fontSize: 14)),
                        label: const Text('Pepper Anthracnose', style: TextStyle(fontSize: 11)),
                        onPressed: _isAnalyzing
                            ? null
                            : () => _loadSample(
                                  'Pepper',
                                  0.88,
                                  false,
                                  'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=600&q=80',
                                ),
                      ),
                      ActionChip(
                        avatar: const Text('🌽', style: TextStyle(fontSize: 14)),
                        label: const Text('Maize (Rule SCAN-03)', style: TextStyle(fontSize: 11)),
                        onPressed: _isAnalyzing
                            ? null
                            : () => _loadSample(
                                  'Maize',
                                  0.10,
                                  false,
                                  'https://images.unsplash.com/photo-1551754655-cd27e38d2076?auto=format&fit=crop&w=600&q=80',
                                ),
                      ),
                      ActionChip(
                        avatar: const Text('🌫️', style: TextStyle(fontSize: 14)),
                        label: const Text('Blurry Leaf (Rule SCAN-04)', style: TextStyle(fontSize: 11)),
                        onPressed: _isAnalyzing
                            ? null
                            : () => _loadSample(
                                  'Cassava',
                                  0.34,
                                  true,
                                  'https://images.unsplash.com/photo-1597848212624-a19eb35e2651?auto=format&fit=crop&w=600&q=80',
                                ),
                      ),
                    ],
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
                    'Crop Recognition Mode:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _crops.map((c) {
                      final isSelected = _selectedCrop == c;
                      String chipLabel;
                      if (c == 'AUTO') {
                        chipLabel = '✨ Auto-Detect from Leaf';
                      } else if (c == 'Maize') {
                        chipLabel = 'Maize (Warning Test)';
                      } else {
                        chipLabel = c;
                      }

                      return ChoiceChip(
                        avatar: c == 'AUTO'
                            ? Icon(Icons.auto_awesome, size: 14, color: isSelected ? Colors.white : AppTheme.primaryGreen)
                            : null,
                        label: Text(
                          chipLabel,
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
