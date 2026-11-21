import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_result.dart';

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
  String _selectedDialect = 'Simple Liberian English';
  bool _isPlayingAudio = false;

  final List<String> _dialects = [
    'Simple Liberian English',
    'Kpelle (Bong & Lofa)',
    'Bassa (Grand Bassa & Margibi)',
  ];

  Color _getConfidenceColor() {
    switch (widget.result.confidenceBand) {
      case 'HIGH':
        return Colors.green.shade700;
      case 'MEDIUM':
        return Colors.orange.shade700;
      case 'LOW':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  void _toggleAudio() {
    setState(() => _isPlayingAudio = !_isPlayingAudio);
    if (_isPlayingAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing voice guidance in $_selectedDialect...'),
          duration: const Duration(seconds: 3),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.result;
    final confColor = _getConfidenceColor();
    final isLowOrEscalated =
        res.confidenceBand == 'LOW' || res.status.contains('ESCALATED');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Findings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!res.isSupported) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade800),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.amber.shade900, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UNSUPPORTED CROP: ${res.cropType.toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            res.vettedAdvice['warning'] ??
                                'Our vision model is only calibrated for Cassava and Pepper. Refusing to guess.',
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                    color: isLowOrEscalated
                        ? Colors.red.shade200
                        : Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          res.cropType,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold),
                        ),
                        if (res.caseNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              res.caseNumber!,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      res.diagnosis,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkText),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: confColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${res.confidenceBand} CONFIDENCE (${(res.confidenceScore * 100).toInt()}%)',
                            style: TextStyle(
                              color: confColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Severity: ${res.severity}',
                            style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    _ConfidenceGradientBar(score: res.confidenceScore),

                    if (isLowOrEscalated) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined,
                                color: Colors.red, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Confidence is <65%. Chemical advice withheld. Case automatically escalated to County Extension Officer triage.',
                                style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 12,
                                    height: 1.3),
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

            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified,
                            color: AppTheme.primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'CARI Vetted Field Guidance',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (res.knowledgeDocId != null)
                          Text(
                            res.knowledgeDocId!,
                            style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Cultural & Preventative Management:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      res.vettedAdvice['cultural_control'] ??
                          'Uproot and burn infected stems. Space ridges appropriately to avoid waterlogging.',
                      style: const TextStyle(
                          fontSize: 13, height: 1.4, color: Colors.black87),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Chemical / Vector Management:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      res.vettedAdvice['chemical_control'] ??
                          'Pending Extension Officer verification.',
                      style: const TextStyle(
                          fontSize: 13, height: 1.4, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 1,
              color: AppTheme.paleGreen.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: AppTheme.lightGreen.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.record_voice_over_rounded,
                            color: AppTheme.primaryGreen),
                        SizedBox(width: 8),
                        Text(
                          'Local Dialect Audio Advisory',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDialect,
                      decoration: InputDecoration(
                        labelText: 'Select Audio Language',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      items: _dialects
                          .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d,
                                  style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedDialect = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      icon: Icon(_isPlayingAudio
                          ? Icons.pause_circle
                          : Icons.play_circle_fill),
                      label: Text(_isPlayingAudio
                          ? 'Pause Voice Guidance'
                          : 'Play Audio Guidance ($_selectedDialect)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        minimumSize: const Size.fromHeight(48),
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

/// Horizontal confidence gradient bar: Red (<45%), Yellow (45–75%), Green (>75%).
/// A triangular needle marks the exact score position.
class _ConfidenceGradientBar extends StatelessWidget {
  final double score; // 0.0 – 1.0

  const _ConfidenceGradientBar({required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confidence Level',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final needleX = (score.clamp(0.0, 1.0) * barWidth);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient bar
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFD32F2F), // red
                        Color(0xFFFDD835), // yellow
                        Color(0xFF388E3C), // green
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                // Zone labels
                Positioned(
                  bottom: -16,
                  left: 0,
                  child: Text('Low',
                      style: TextStyle(fontSize: 9, color: Colors.red.shade700)),
                ),
                Positioned(
                  bottom: -16,
                  left: barWidth * 0.45 - 12,
                  child: Text('Med',
                      style: TextStyle(
                          fontSize: 9, color: Colors.orange.shade800)),
                ),
                Positioned(
                  bottom: -16,
                  right: 0,
                  child: Text('High',
                      style:
                          TextStyle(fontSize: 9, color: Colors.green.shade700)),
                ),
                // Needle marker
                Positioned(
                  left: needleX - 6,
                  top: -4,
                  child: CustomPaint(
                    size: const Size(12, 20),
                    painter: _NeedlePainter(),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
