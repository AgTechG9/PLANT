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

  final List<String> _crops = ['AUTO', 'Cassava', 'Pepper'];

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
    final bool hasImage = _selectedImage != null || _sampleImageUrl != null;

    return Container(
      height: 340,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Preview Image or Placeholder
            if (!hasImage)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12, width: 1.5),
                        ),
                        child: const Icon(Icons.center_focus_strong_rounded, size: 48, color: Color(0xFF52B788)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Position Leaf in Center',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Keep well-lit and steady for highest diagnosis accuracy',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),
              )
            else if (_sampleImageUrl != null && _selectedImage == null)
              Image.network(
                _sampleImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 40),
                      const SizedBox(height: 8),
                      Text('Sample image unavailable', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
                ),
              )
            else if (kIsWeb && _webImageBytes != null)
              Image.memory(_webImageBytes!, fit: BoxFit.cover)
            else if (_selectedImage != null)
              Image.file(File(_selectedImage!.path), fit: BoxFit.cover),

            // Subtle darkened vignette overlay for professional camera scanner feel
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Targeting Reticle (Corner Brackets)
            Positioned(
              top: 28,
              left: 28,
              child: _buildCorner(isTop: true, isLeft: true),
            ),
            Positioned(
              top: 28,
              right: 28,
              child: _buildCorner(isTop: true, isLeft: false),
            ),
            Positioned(
              bottom: 28,
              left: 28,
              child: _buildCorner(isTop: false, isLeft: true),
            ),
            Positioned(
              bottom: 28,
              right: 28,
              child: _buildCorner(isTop: false, isLeft: false),
            ),

            // Center targeting crosshairs
            Center(
              child: Opacity(
                opacity: hasImage ? 0.4 : 0.2,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Reset image button when an image is loaded
            if (hasImage)
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    tooltip: 'Clear image',
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _sampleImageUrl = null;
                        _webImageBytes = null;
                      });
                    },
                  ),
                ),
              ),

            // Viewfinder Status Pill
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasImage ? const Color(0xFF10B981).withValues(alpha: 0.5) : Colors.white24,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: hasImage ? const Color(0xFF10B981) : const Color(0xFF52B788),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (hasImage ? const Color(0xFF10B981) : const Color(0xFF52B788)).withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasImage ? 'Leaf Ready • Tap Scan Below' : 'AI Vision Engine Active',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2),
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
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Color(0xFF10B981), width: 3.5) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Color(0xFF10B981), width: 3.5) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Color(0xFF10B981), width: 3.5) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Color(0xFF10B981), width: 3.5) : BorderSide.none,
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
                      icon: const Icon(Icons.photo_library_outlined, size: 20),
                      label: const Text('From Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E293B),
                        elevation: 0,
                      ),
                      onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      ),
                      onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Clean Mode Selector (Target Crop)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_vintage_outlined, size: 16, color: AppTheme.mediumGreen),
                        const SizedBox(width: 6),
                        const Text(
                          'TARGET CROP SPECIES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _crops.map((c) {
                        final isSelected = _selectedCrop == c;
                        String label = c == 'AUTO' ? '✨ Auto-Detect' : (c == 'Cassava' ? '🌿 Cassava' : '🫑 Pepper');
                        return ChoiceChip(
                          label: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.paleGreen,
                          backgroundColor: const Color(0xFFF8FAFC),
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primaryGreen : const Color(0xFF334155),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
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

            // Clean Pitch Sample Cards (Cassava & Pepper Focus)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt, size: 16, color: AppTheme.earthYellow),
                      const SizedBox(width: 6),
                      const Text(
                        'QUICK DEMO PRESETS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSamplePill('🌿 Cassava CMD', 'Cassava', 0.92, false, 'https://images.unsplash.com/photo-1599818816942-e1c251d1847e?auto=format&fit=crop&w=600&q=80'),
                        const SizedBox(width: 8),
                        _buildSamplePill('🌿 Cassava Healthy', 'Cassava', 0.95, false, 'https://images.unsplash.com/photo-1599818816942-e1c251d1847e?auto=format&fit=crop&w=600&q=80'),
                        const SizedBox(width: 8),
                        _buildSamplePill('🫑 Pepper Anthracnose', 'Pepper', 0.91, false, 'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=600&q=80'),
                        const SizedBox(width: 8),
                        _buildSamplePill('🫑 Pepper Healthy', 'Pepper', 0.94, false, 'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=600&q=80'),
                        const SizedBox(width: 8),
                        _buildSamplePill('🌫️ Blurry Leaf (Rule SCAN-04)', 'Cassava', 0.35, true, 'https://images.unsplash.com/photo-1597848212624-a19eb35e2651?auto=format&fit=crop&w=600&q=80'),
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
    final bool isCurrentlySelected = _sampleImageUrl == url;

    return InkWell(
      onTap: () => _loadSample(crop, conf, blurry, url),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentlySelected ? AppTheme.paleGreen : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrentlySelected ? AppTheme.primaryGreen : Colors.grey.shade200,
            width: isCurrentlySelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrentlySelected ? FontWeight.w700 : FontWeight.w600,
                color: isCurrentlySelected ? AppTheme.primaryGreen : const Color(0xFF1E293B),
              ),
            ),
            if (isCurrentlySelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, size: 14, color: AppTheme.primaryGreen),
            ],
          ],
        ),
      ),
    );
  }
}
