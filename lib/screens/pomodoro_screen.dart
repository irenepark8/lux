import 'package:flutter/material.dart';
import 'dart:async';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  bool _isWork = true;
  int _workMinutes = 25;
  int _breakMinutes = 5;
  int _secondsLeft = 25 * 60;
  Timer? _timer;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_running) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        setState(() {
          _isWork = !_isWork;
          _secondsLeft = (_isWork ? _workMinutes : _breakMinutes) * 60;
          _running = false;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = (_isWork ? _workMinutes : _breakMinutes) * 60;
      _running = false;
    });
  }

  void _adjustWork(int delta) {
    setState(() {
      _workMinutes = (_workMinutes + delta).clamp(1, 60);
      if (_isWork) _secondsLeft = _workMinutes * 60;
    });
  }

  void _adjustBreak(int delta) {
    setState(() {
      _breakMinutes = (_breakMinutes + delta).clamp(1, 30);
      if (!_isWork) _secondsLeft = _breakMinutes * 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _isWork ? const Color(0xFF888DFF) : const Color(0xFF1A237E); // periwinkle/navy
    final textColor = _isWork ? Colors.white : Colors.white;
    final bubblyFont = 'Rubik'; // Use Rubik as a bubbly font if available, else fallback

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pomodoro Timer',
                    style: TextStyle(
                      fontFamily: bubblyFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isWork ? 'Work' : 'Break',
                      style: TextStyle(
                        fontFamily: bubblyFont,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Timer Display
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FlipClock(
                        seconds: _secondsLeft,
                        color: themeColor,
                        fontFamily: bubblyFont,
                      ),
                      const SizedBox(height: 40),
                      
                      // Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            _running ? 'Pause' : 'Start',
                            _running ? _pauseTimer : _startTimer,
                            themeColor,
                            textColor,
                          ),
                          _buildControlButton(
                            'Reset',
                            _resetTimer,
                            themeColor,
                            textColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Settings Panel
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Timer Settings',
                      style: TextStyle(
                        fontFamily: bubblyFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdjuster(
                            label: 'Work (min)',
                            value: _workMinutes,
                            onInc: () => _adjustWork(1),
                            onDec: () => _adjustWork(-1),
                            color: themeColor,
                            textColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildAdjuster(
                            label: 'Break (min)',
                            value: _breakMinutes,
                            onInc: () => _adjustBreak(1),
                            onDec: () => _adjustBreak(-1),
                            color: themeColor,
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildAdjuster({
    required String label,
    required int value,
    required VoidCallback onInc,
    required VoidCallback onDec,
    required Color color,
    required Color textColor,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.w600, color: color, fontSize: 13)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: color, size: 20),
              onPressed: onDec,
              splashRadius: 16,
            ),
            Text('$value', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: color, size: 20),
              onPressed: onInc,
              splashRadius: 16,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton(String label, VoidCallback onTap, Color bg, Color fg) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: fg,
        foregroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        textStyle: const TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 15),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}

class _FlipClock extends StatelessWidget {
  final int seconds;
  final Color color;
  final String fontFamily;
  const _FlipClock({required this.seconds, required this.color, required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FlipDigit(digit: min[0], color: color, fontFamily: fontFamily),
        _FlipDigit(digit: min[1], color: color, fontFamily: fontFamily),
        Text(':', style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, color: color, fontSize: 36)),
        _FlipDigit(digit: sec[0], color: color, fontFamily: fontFamily),
        _FlipDigit(digit: sec[1], color: color, fontFamily: fontFamily),
      ],
    );
  }
}

class _FlipDigit extends StatelessWidget {
  final String digit;
  final Color color;
  final String fontFamily;
  const _FlipDigit({required this.digit, required this.color, required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
      child: Container(
        key: ValueKey(digit),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          digit,
          style: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 36,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
} 