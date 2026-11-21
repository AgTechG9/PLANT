import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class UssdSimulatorScreen extends StatefulWidget {
  const UssdSimulatorScreen({super.key});

  @override
  State<UssdSimulatorScreen> createState() => _UssdSimulatorScreenState();
}

class _UssdSimulatorScreenState extends State<UssdSimulatorScreen> {
  final String _sessionId = 'ussd_${DateTime.now().millisecondsSinceEpoch}';
  final String _phoneNumber = '+231770123456';
  final ScrollController _transcriptScrollController = ScrollController();
  final ScrollController _screenScrollController = ScrollController();

  String _currentScreenText =
      'Welcome to PLANT Liberian Agri-Service.\n\nDial *123# and press SEND/CALL to start USSD session.';
  String _inputBuffer = '';
  final List<String> _sessionSteps = [];
  final List<Map<String, dynamic>> _transcript = [];
  bool _sessionActive = false;
  bool _isLoading = false;
  bool _showHelpShortcuts = true;
  final String _signalStrength = '4G LTE';
  final String _carrierName = 'Lonestar MTN / Orange LR';

  @override
  void initState() {
    super.initState();
    _inputBuffer = '*123#';
  }

  @override
  void dispose() {
    _transcriptScrollController.dispose();
    _screenScrollController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      _inputBuffer += key;
    });
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    if (_inputBuffer.isNotEmpty) {
      setState(() {
        _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
      });
    }
  }

  void _clearInput() {
    HapticFeedback.selectionClick();
    setState(() {
      _inputBuffer = '';
    });
  }

  void _appendTranscript(String sent, String received) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    _transcript.add({
      'sent': sent,
      'received': received,
      'time': timeStr,
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transcriptScrollController.hasClients) {
        _transcriptScrollController.animateTo(
          _transcriptScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      if (_screenScrollController.hasClients) {
        _screenScrollController.jumpTo(0);
      }
    });
  }

  Future<void> _dialCall() async {
    HapticFeedback.mediumImpact();
    if (!_sessionActive) {
      if (_inputBuffer != '*123#' && _inputBuffer != '123') {
        setState(() {
          _currentScreenText =
              'Connection problem or invalid MMI code.\nPlease dial *123# to connect.';
        });
        return;
      }

      final dialed = _inputBuffer;
      setState(() {
        _sessionActive = true;
        _isLoading = true;
        _sessionSteps.clear();
      });

      final res = await ApiService.sendUssd(
        sessionId: _sessionId,
        phoneNumber: _phoneNumber,
        text: '',
      );

      final message = res['message'] ?? 'Error connecting to USSD gateway.';
      setState(() {
        _isLoading = false;
        _currentScreenText = message;
        _inputBuffer = '';
        _appendTranscript(dialed, message);
      });
    } else {
      if (_inputBuffer.isEmpty) return;

      final nextStep = _inputBuffer.trim();
      _sessionSteps.add(nextStep);
      final combinedText = _sessionSteps.join('*');

      setState(() {
        _isLoading = true;
        _inputBuffer = '';
      });

      final res = await ApiService.sendUssd(
        sessionId: _sessionId,
        phoneNumber: _phoneNumber,
        text: combinedText,
      );

      final message = res['message'] ?? 'Session terminated.';
      final continueSession = res['continueSession'] ?? false;
      setState(() {
        _isLoading = false;
        _currentScreenText = message;
        _sessionActive = continueSession;
        _appendTranscript(nextStep, message);
      });
    }
  }

  void _endCall() {
    HapticFeedback.heavyImpact();
    setState(() {
      _sessionActive = false;
      _sessionSteps.clear();
      _inputBuffer = '*123#';
      _currentScreenText =
          'Session ended.\n\nDial *123# and press SEND/CALL to begin.';
    });
  }

  void _resetSession() {
    HapticFeedback.mediumImpact();
    setState(() {
      _sessionActive = false;
      _sessionSteps.clear();
      _transcript.clear();
      _inputBuffer = '*123#';
      _currentScreenText =
          'Dial *123# and press CALL to start USSD session.';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('USSD session reset to initial state.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _applyQuickDial(String code) {
    HapticFeedback.lightImpact();
    setState(() {
      _inputBuffer = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'USSD Field Simulator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'Liberia Rural Gateway (*123#) • $_phoneNumber',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showHelpShortcuts ? Icons.info : Icons.info_outline),
            tooltip: 'Toggle Quick Reference',
            onPressed: () {
              setState(() {
                _showHelpShortcuts = !_showHelpShortcuts;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Session',
            onPressed: _resetSession,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  // Optional Quick Help / Agricultural shortcuts card
                  if (_showHelpShortcuts) ...[
                    _buildQuickTipsCard(),
                    const SizedBox(height: 16),
                  ],

                  // Realistic Virtual Feature Phone Chassis
                  _buildPhoneChassis(),

                  const SizedBox(height: 16),

                  // Session Transcript / Audit Log Drawer
                  _buildTranscriptSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTipsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.paleGreen, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.mediumGreen),
              const SizedBox(width: 8),
              const Text(
                'Quick Dial Shortcuts (Simulated USSD)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildShortcutChip('*123#', 'Main Menu'),
              _buildShortcutChip('1', 'Crop Diagnosis'),
              _buildShortcutChip('2', 'Market Prices'),
              _buildShortcutChip('3', 'Weather Alerts'),
              _buildShortcutChip('4', 'Extension Agent'),
              _buildShortcutChip('0', 'Back / Home'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutChip(String code, String label) {
    return InkWell(
      onTap: () => _applyQuickDial(code),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.paleGreen.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.lightGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: AppTheme.primaryGreen,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneChassis() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFF334155), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 24,
            spreadRadius: 1,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0xFF0F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Earpiece speaker & brand indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'PLANT AGRI-COMM',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // High-contrast Retro-Modern LCD Screen
          _buildLcdDisplay(),

          const SizedBox(height: 16),

          // Feature Phone Softkeys / Navigation Bar
          _buildSoftkeys(),

          const SizedBox(height: 12),

          // Numeric Keypad Grid (3x4)
          _buildKeypadGrid(),

          const SizedBox(height: 14),

          // Call Action buttons row
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildLcdDisplay() {
    return Container(
      height: 205,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF9AE6B4), // Crisp retro green LCD tone
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF14532D), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _isLoading
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF14532D),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _sessionActive ? 'Sending USSD code...' : 'Contacting Gateway...',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14532D),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top status bar (Carrier, Battery, Signal, State)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.signal_cellular_alt,
                          size: 13,
                          color: Color(0xFF14532D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_carrierName · $_signalStrength',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14532D),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: _sessionActive
                                ? const Color(0xFF166534)
                                : const Color(0xFF166534).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            _sessionActive ? 'CONNECTED' : 'STANDBY',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _sessionActive
                                  ? const Color(0xFF9AE6B4)
                                  : const Color(0xFF14532D),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.battery_full,
                          size: 13,
                          color: Color(0xFF14532D),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF166534), thickness: 1.2, height: 8),

                // Main LCD prompt / content area
                Expanded(
                  child: Scrollbar(
                    controller: _screenScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _screenScrollController,
                      child: Text(
                        _currentScreenText,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF052E16),
                          height: 1.35,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),

                // LCD input buffer bar with blinking cursor simulation
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14532D).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF14532D).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'CMD > ',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14532D),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _inputBuffer.isEmpty ? '_' : '$_inputBuffer▏',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _inputBuffer.isEmpty
                                ? const Color(0xFF166534).withValues(alpha: 0.6)
                                : const Color(0xFF052E16),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_inputBuffer.isNotEmpty)
                        GestureDetector(
                          onTap: _clearInput,
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Color(0xFF14532D),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSoftkeys() {
    return Row(
      children: [
        // Left Softkey (Select / Action)
        Expanded(
          child: Material(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _dialCall,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  _sessionActive ? 'OPTION' : 'DIAL',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Center D-pad mini navigation hub
        Container(
          width: 58,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: const Center(
            child: Icon(
              Icons.adjust_rounded,
              color: Colors.white54,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Right Softkey (Back / Cancel)
        Expanded(
          child: Material(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _onBackspace,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'BACK',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 8,
      childAspectRatio: 1.45,
      children: [
        _buildKey('1', '.,!'),
        _buildKey('2', 'ABC'),
        _buildKey('3', 'DEF'),
        _buildKey('4', 'GHI'),
        _buildKey('5', 'JKL'),
        _buildKey('6', 'MNO'),
        _buildKey('7', 'PQRS'),
        _buildKey('8', 'TUV'),
        _buildKey('9', 'WXYZ'),
        _buildKey('*', 'PRV'),
        _buildKey('0', '+ _'),
        _buildKey('#', 'NXT'),
      ],
    );
  }

  Widget _buildKey(String primary, String sub) {
    return Material(
      color: const Color(0xFF3B485C),
      borderRadius: BorderRadius.circular(10),
      elevation: 1,
      child: InkWell(
        onTap: () => _onKeyPress(primary),
        borderRadius: BorderRadius.circular(10),
        splashColor: AppTheme.lightGreen.withValues(alpha: 0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                primary,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              if (sub.isNotEmpty)
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 8,
                    letterSpacing: 0.8,
                    color: Colors.white60,
                    height: 1.0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Clear / Delete Key
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.backspace_outlined, size: 16),
            label: const Text('Clear', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF475569),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            onPressed: _onBackspace,
          ),
        ),
        const SizedBox(width: 8),

        // End Call Key (Red)
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.call_end_rounded, size: 16),
            label: const Text('End', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            onPressed: _endCall,
          ),
        ),
        const SizedBox(width: 8),

        // Dial / Send Key (Green)
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(
              _sessionActive ? Icons.send_rounded : Icons.call_rounded,
              size: 16,
            ),
            label: Text(
              _sessionActive ? 'Send' : 'Call',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            onPressed: _dialCall,
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: AppTheme.mediumGreen,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Session Transcript & Audit Log',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                if (_transcript.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _transcript.clear();
                      });
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_transcript.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No USSD transactions yet.\nDial *123# above to start session.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              ),
            )
          else
            Container(
              height: 150,
              padding: const EdgeInsets.all(12),
              child: ListView.separated(
                controller: _transcriptScrollController,
                itemCount: _transcript.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _transcript[index];
                  final sent = item['sent'] as String;
                  final received = item['received'] as String;
                  final time = item['time'] as String;

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.paleGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Dialed: $sent',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          received,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: Color(0xFF334155),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

