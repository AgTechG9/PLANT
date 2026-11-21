import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UssdSimulatorScreen extends StatefulWidget {
  const UssdSimulatorScreen({super.key});

  @override
  State<UssdSimulatorScreen> createState() => _UssdSimulatorScreenState();
}

class _UssdSimulatorScreenState extends State<UssdSimulatorScreen> {
  final String _sessionId = 'ussd_${DateTime.now().millisecondsSinceEpoch}';
  final String _phoneNumber = '+231770123456';
  final ScrollController _transcriptScrollController = ScrollController();

  String _currentScreenText = 'Dial *123# and press CALL to start USSD session.';
  String _inputBuffer = '';
  final List<String> _sessionSteps = [];
  final List<String> _transcript = [];
  bool _sessionActive = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inputBuffer = '*123#';
  }

  @override
  void dispose() {
    _transcriptScrollController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    setState(() {
      _inputBuffer += key;
    });
  }

  void _onBackspace() {
    if (_inputBuffer.isNotEmpty) {
      setState(() {
        _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
      });
    }
  }

  void _appendTranscript(String sent, String received) {
    _transcript.add('>> $sent');
    _transcript.add('<< $received');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transcriptScrollController.hasClients) {
        _transcriptScrollController.animateTo(
          _transcriptScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _dialCall() async {
    if (!_sessionActive) {
      if (_inputBuffer != '*123#' && _inputBuffer != '123') {
        setState(() {
          _currentScreenText = 'Invalid MMI code. Please dial *123#';
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
    setState(() {
      _sessionActive = false;
      _sessionSteps.clear();
      _transcript.clear();
      _inputBuffer = '*123#';
      _currentScreenText = 'Dial *123# and press CALL to start USSD session.';
    });
  }

  void _resetSession() => _endCall();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        title: const Text('USSD *123# Feature Phone'),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Session',
            onPressed: _resetSession,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white24, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    // LCD Screen
                    Container(
                      height: 190,
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF86EFAC).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF166534), width: 3),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(color: Color(0xFF14532D)),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'ORANGE LR / MTN',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF14532D),
                                      ),
                                    ),
                                    Text(
                                      _sessionActive ? 'ACTIVE' : 'IDLE',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF14532D),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Color(0xFF166534), height: 10),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      _currentScreenText,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF052E16),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_inputBuffer.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    color: const Color(0xFF166534).withValues(alpha: 0.15),
                                    child: Text(
                                      'Input: $_inputBuffer',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF052E16),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),

                    // Session Transcript Panel
                    if (_transcript.isNotEmpty) ...[
                      Container(
                        height: 120,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Session Transcript',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: Colors.white38,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: ListView.builder(
                                controller: _transcriptScrollController,
                                itemCount: _transcript.length,
                                itemBuilder: (context, index) {
                                  final entry = _transcript[index];
                                  final isSent = entry.startsWith('>>');
                                  return Text(
                                    entry,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: isSent
                                          ? Colors.lightBlueAccent.shade100
                                          : Colors.greenAccent.shade100,
                                      height: 1.5,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Keypad Grid
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.4,
                      children: [
                        _buildKey('1', ''),
                        _buildKey('2', 'ABC'),
                        _buildKey('3', 'DEF'),
                        _buildKey('4', 'GHI'),
                        _buildKey('5', 'JKL'),
                        _buildKey('6', 'MNO'),
                        _buildKey('7', 'PQRS'),
                        _buildKey('8', 'TUV'),
                        _buildKey('9', 'WXYZ'),
                        _buildKey('*', ''),
                        _buildKey('0', '+'),
                        _buildKey('#', ''),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Action buttons row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.backspace_outlined, size: 18),
                            label: const Text('Clear'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _onBackspace,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.call_end, size: 18),
                            label: const Text('End Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _endCall,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.call, size: 18),
                            label: Text(_sessionActive ? 'Send' : 'Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _dialCall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String primary, String sub) {
    return InkWell(
      onTap: () => _onKeyPress(primary),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF475569),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              primary,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (sub.isNotEmpty)
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.0,
                  color: Colors.white54,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
