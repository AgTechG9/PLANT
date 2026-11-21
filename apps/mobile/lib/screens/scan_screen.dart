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

  // Pitch simulation dials
  bool _simulateBlurry = false;
  double _simulatedConfidence = 0.88;

  final List<String> _crops = ['AUTO', 'Cassava', 'Pepper', 'Maize'];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (file != null) {
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          setState(() {
            _selectedImage = file;
            _webImageBytes = bytes;
            _sampleImageUrl = null;
          });
        } else {
          setState(() {
            _selectedImage = file;
            _webImageBytes = null;
            _sampleImageUrl = null;
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
      await Future.delayed(const Duration(milliseconds: 700));
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
      simulatedConfidence: _simulateBlurry ? _simulatedConfidence : null,
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

  void _showDialsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('⚡ Pitch Demo Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Text('Test safety guardrails during live presentation:', style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Simulate Blurry Image (Rule SCAN-04)'),
                subtitle: const Text('Triggers abstention & retake guidance'),
                value: _simulateBlurry,
                onChanged: (v) {
                  setModalState(() => _simulateBlurry = v);
                  setState(() => _simulateBlurry = v);
                },
              ),
              const Divider(),
              const Text('Confidence Override:'),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _simulatedConfidence,
                      min: 0.30,
                      max: 0.98,
                      divisions: 14,
                      onChanged: (v) {
                        setModalState(() => _simulatedConfidence = v);
                        setState(() => _simulatedConfidence = v);
                      },
                    ),
                  ),
                  Text('${(_simulatedConfidence * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinder() {
    return Container(
      height: 330,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Preview
            if (_selectedImage == null && _sampleImageUrl == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Position crop leaf inside frame',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI detects crop & pathology automatically',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                    ),
                  ],
                ),
              )
            else if (_sampleImageUrl != null && _selectedImage == null)
              Image.network(_sampleImageUrl!, fit: BoxFit.cover)
            else if (kIsWeb && _webImageBytes != null)
              Image.memory(_webImageBytes!, fit: BoxFit.cover)
            else if (_selectedImage != null)
              Image.file(File(_selectedImage!.path), fit: BoxFit.cover),

            // Targeting Reticle (Corner Brackets)
            Positioned(
              top: 30,
              left: 30,
              child: _buildCorner(isTop: true, isLeft: true),
            ),
            Positioned(
              top: 30,
              right: 30,
              child: _buildCorner(isTop: true, isLeft: false),
            ),
            Positioned(
              bottom: 30,
              left: 30,
              child: _buildCorner(isTop: false, isLeft: true),
            ),
            Positioned(
              bottom: 30,
              right: 30,
              child: _buildCorner(isTop: false, isLeft: false),
            ),

            // Viewfinder Status Pill
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedImage != null || _sampleImageUrl != null
                            ? 'Leaf Staged • Ready to Scan'
                            : 'AI Vision Engine Active',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Color(0xFF10B981), width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Color(0xFF10B981), width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Color(0xFF10B981), width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Color(0xFF10B981), width: 3) : BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Crop Vision Scanner'),
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Demo Dials',
            onPressed: _showDialsSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildViewfinder(),

            // Action Buttons Row (Take Photo / Choose Photo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('From Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: const Color(0xFF1E293B),
                      ),
                      onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Clean Mode Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Diagnosis Target:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _crops.map((c) {
                        final isSelected = _selectedCrop == c;
                        String label = c == 'AUTO'
                            ? '✨ Auto-Detect'
                            : c == 'Maize'
                                ? 'Maize (Safety Test)'
                                : c;
                        return ChoiceChip(
                          label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          selectedColor: AppTheme.paleGreen,
                          labelStyle: TextStyle(color: isSelected ? AppTheme.primaryGreen : Colors.black87),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300),
                          onSelected: (val) {
                            if (val) setState(() => _selectedCrop = c);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Clean Pitch Sample Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Test Samples:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSamplePill('🌿 Cassava CMD', 'Cassava', 0.92, false, 'https://images.unsplash.com/photo-1599818816942-e1c251d1847e?auto=format&fit=crop&w=600&q=80'),
                        const SizedBox(width: 8),
                        _buildSamplePill('🫑 Pepper Leaf', 'Pepper', 0.88, false, 'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=600&q=80'),
                        const SizedBox(width: 8),
                        _buildSamplePill('🌽 Maize (Reject)', 'Maize', 0.10, false, 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?auto=format&fit=crop&w=600&q=80'),
                        const SizedBox(width: 8),
                        _buildSamplePill('🌫️ Blurry (Escalate)', 'Cassava', 0.35, true, 'https://images.unsplash.com/photo-1597848212624-a19eb35e2651?auto=format&fit=crop&w=600&q=80'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Big Clean Run Diagnostic Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isAnalyzing ? null : _runScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: _isAnalyzing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                            SizedBox(width: 12),
                            Text('Running Real-Time Vision AI...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 20),
                            SizedBox(width: 10),
                            Text('Run Diagnostic Scan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSamplePill(String title, String crop, double conf, bool blurry, String url) {
    return InkWell(
      onTap: () => _loadSample(crop, conf, blurry, url),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
