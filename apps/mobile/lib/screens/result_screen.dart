import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_result.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class ResultScreen extends StatefulWidget {
  final DiagnosticResult result;
  final bool isOfflineResult;

  const ResultScreen({
    super.key,
    required this.result,
    this.isOfflineResult = false,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String _selectedDialect = 'Liberian English (Koloqua)';
  bool _isPlayingAudio = false;

  final List<String> _dialects = [
    'Liberian English (Koloqua)',
    'Kpelle (Bong & Lofa)',
  ];

  Color _getConfidenceColor() {
    switch (widget.result.confidenceBand.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFF2E7D32);
      case 'MEDIUM':
        return const Color(0xFFE65100);
      case 'LOW':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF546E7A);
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
      case 'severe':
        return const Color(0xFFC62828);
      case 'medium':
      case 'moderate':
        return const Color(0xFFE65100);
      case 'low':
      case 'mild':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF455A64);
    }
  }

  String? _getAudioUrl() {
    final crop = widget.result.cropType.toLowerCase();
    final isKpelle = _selectedDialect.toLowerCase().contains('kpelle');

    final audioKey = isKpelle ? 'audio_kpelle' : 'audio_koloqua';
    if (widget.result.vettedAdvice.containsKey(audioKey) &&
        widget.result.vettedAdvice[audioKey] != null &&
        widget.result.vettedAdvice[audioKey].toString().isNotEmpty) {
      final rawUrl = widget.result.vettedAdvice[audioKey].toString();
      if (rawUrl.startsWith('http')) return rawUrl;
      final uri = Uri.parse(ApiService.baseUrl);
      final portPart = uri.hasPort && uri.port != 80 && uri.port != 443 ? ':${uri.port}' : '';
      return '${uri.scheme}://${uri.host}$portPart$rawUrl';
    }

    final baseAudioUrl = ApiService.baseUrl.replaceAll('/api/v1', '');
    if (crop.contains('cassava')) {
      return isKpelle
          ? '$baseAudioUrl/audio/cassava_kpelle.m4a'
          : '$baseAudioUrl/audio/cassava_koloqua.m4a';
    } else if (crop.contains('pepper')) {
      return isKpelle
          ? '$baseAudioUrl/audio/pepper_kpelle.m4a'
          : '$baseAudioUrl/audio/pepper_koloqua.m4a';
    }
    return null;
  }

  void _toggleAudio() {
    if (_isPlayingAudio) {
      AudioPlayerService.instance.stop();
      setState(() => _isPlayingAudio = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.pause_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Voice guidance paused.', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.grey.shade800,
        ),
      );
    } else {
      final url = _getAudioUrl();
      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio advisory not available for this crop.')),
        );
        return;
      }

      AudioPlayerService.instance.play(url, onComplete: () {
        if (mounted) setState(() => _isPlayingAudio = false);
      });
      setState(() => _isPlayingAudio = true);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Playing voice guidance in $_selectedDialect...',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  @override
  void dispose() {
    AudioPlayerService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.result;
    final confColor = _getConfidenceColor();
    final isLowOrEscalated =
        res.confidenceBand.toUpperCase() == 'LOW' ||
        res.status.toUpperCase().contains('ESCALATED');

    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      appBar: AppBar(
        title: const Text('Diagnostic Findings'),
        actions: [
          if (widget.isOfflineResult)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 14, color: Colors.amber.shade900),
                      const SizedBox(width: 4),
                      Text(
                        'OFFLINE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Unsupported Crop Banner
            if (!res.isSupported) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFE65100), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UNSUPPORTED CROP: ${res.cropType.toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.5,
                              color: Color(0xFFB71C1C),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            res.vettedAdvice['warning'] ??
                                'Our vision model is only calibrated for Cassava and Pepper. Refusing to guess.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.brown.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Main Diagnostic Findings Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isLowOrEscalated
                      ? const Color(0xFFEF9A9A)
                      : Colors.grey.shade200,
                  width: isLowOrEscalated ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Crop type badge and Case Number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.paleGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.eco_rounded,
                                      size: 15, color: AppTheme.primaryGreen),
                                  const SizedBox(width: 5),
                                  Text(
                                    res.cropType.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (res.caseNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.tag_rounded, size: 13, color: Colors.grey.shade700),
                                const SizedBox(width: 3),
                                Text(
                                  res.caseNumber!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Primary Diagnosis Title
                    Text(
                      res.diagnosis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkText,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Status and Severity Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: confColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: confColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                res.confidenceBand.toUpperCase() == 'HIGH'
                                    ? Icons.check_circle_outline_rounded
                                    : (res.confidenceBand.toUpperCase() == 'MEDIUM'
                                        ? Icons.help_outline_rounded
                                        : Icons.error_outline_rounded),
                                size: 14,
                                color: confColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${res.confidenceBand.toUpperCase()} CONFIDENCE (${(res.confidenceScore * 100).toInt()}%)',
                                style: TextStyle(
                                  color: confColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(res.severity).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getSeverityColor(res.severity).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.speed_rounded,
                                  size: 14, color: _getSeverityColor(res.severity)),
                              const SizedBox(width: 5),
                              Text(
                                'Severity: ${res.severity}',
                                style: TextStyle(
                                  color: _getSeverityColor(res.severity),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    _ConfidenceGauge(score: res.confidenceScore),

                    // Escalation / Low Confidence Warning Banner
                    if (isLowOrEscalated) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.shield_outlined,
                                color: Color(0xFFC62828), size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Precautionary Triage Triggered',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFFB71C1C),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Confidence is <65%. Chemical recommendations are strictly withheld to protect your crops. Case automatically escalated to your County Agricultural Extension Officer for verification.',
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // CARI Vetted Field Guidance Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.paleGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.verified_rounded,
                              color: AppTheme.primaryGreen, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CARI Vetted Field Guidance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkText,
                                ),
                              ),
                              Text(
                                'Central Agricultural Research Institute',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (res.knowledgeDocId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.paleGreen.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              res.knowledgeDocId!,
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),

                    // Advisory Step 1: Cultural & Preventative Management
                    _AdvisoryStepItem(
                      stepNumber: 1,
                      title: 'Cultural & Preventative Management',
                      badgeText: 'Farmer Action',
                      badgeColor: AppTheme.primaryGreen,
                      icon: Icons.grass_rounded,
                      content: res.vettedAdvice['cultural_control'] ??
                          'Uproot and burn infected stems. Space ridges appropriately to avoid waterlogging and encourage aeration.',
                    ),

                    const SizedBox(height: 16),

                    // Advisory Step 2: Chemical / Vector Management
                    _AdvisoryStepItem(
                      stepNumber: 2,
                      title: 'Chemical / Vector Management',
                      badgeText: isLowOrEscalated ? 'Withheld / Review' : 'Regulated Advice',
                      badgeColor: isLowOrEscalated ? const Color(0xFFC62828) : const Color(0xFFE65100),
                      icon: Icons.science_outlined,
                      content: isLowOrEscalated
                          ? 'Chemical recommendations withheld due to low confidence threshold (<65%). Please await Extension Officer guidance before applying treatments.'
                          : (res.vettedAdvice['chemical_control'] ??
                              'Pending Extension Officer verification.'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Local Dialect Audio Advisory Card
            Card(
              elevation: 1,
              color: const Color(0xFFF1F8F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: AppTheme.lightGreen.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.paleGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.record_voice_over_rounded,
                              color: AppTheme.primaryGreen, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Local Dialect Audio Advisory',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Listen to step-by-step guidance spoken in local Liberian dialects.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDialect,
                      decoration: InputDecoration(
                        labelText: 'Select Audio Language',
                        labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
                        prefixIcon: const Icon(Icons.language_rounded, size: 20, color: AppTheme.primaryGreen),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      items: _dialects
                          .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkText,
                                  ))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedDialect = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      icon: Icon(_isPlayingAudio
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded),
                      label: Text(_isPlayingAudio
                          ? 'Pause Voice Guidance'
                          : 'Play Audio Guidance ($_selectedDialect)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPlayingAudio ? const Color(0xFFC62828) : AppTheme.primaryGreen,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _toggleAudio,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Advisory Step Item component showing clean step numbers, badges, and icon indicators
class _AdvisoryStepItem extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String badgeText;
  final Color badgeColor;
  final IconData icon;
  final String content;

  const _AdvisoryStepItem({
    required this.stepNumber,
    required this.title,
    required this.badgeText,
    required this.badgeColor,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.primaryGreen,
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: Colors.black45),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Horizontal confidence gradient bar: Low (<45%), Med (45–75%), High (>75%).
/// A polished needle marker pinpoints the exact score position.
class _ConfidenceGauge extends StatelessWidget {
  final double score; // 0.0 – 1.0

  const _ConfidenceGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    final clampedScore = score.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Model Confidence Gauge',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            Text(
              '${(clampedScore * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final needleX = (clampedScore * barWidth).clamp(6.0, barWidth - 6.0);
            return SizedBox(
              height: 38,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Gradient track with subtle depth
                  Positioned(
                    top: 4,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE53935), // Red (<45%)
                            Color(0xFFFB8C00), // Orange (45-65%)
                            Color(0xFFFDD835), // Yellow (65-75%)
                            Color(0xFF43A047), // Green (>75%)
                          ],
                          stops: [0.0, 0.45, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Needle pointer
                  Positioned(
                    left: needleX - 7,
                    top: 0,
                    child: CustomPaint(
                      size: const Size(14, 20),
                      painter: _GaugeNeedlePainter(),
                    ),
                  ),

                  // Zone threshold markers & labels
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Text('Low (<45%)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        )),
                  ),
                  Positioned(
                    bottom: 0,
                    left: barWidth * 0.45 - 18,
                    child: Text('Med (45-75%)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        )),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Text('High (>75%)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        )),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GaugeNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.save();
    canvas.translate(0, 1);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF1B4332)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
