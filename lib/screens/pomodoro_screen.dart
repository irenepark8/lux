import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pomodoro_timer_model.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  bool _pulseOn = true;

  @override
  Widget build(BuildContext context) {
    final timerModel = Provider.of<PomodoroTimerModel>(context);
    final themeColor = timerModel.isWork ? const Color(0xFF888DFF) : const Color(0xFF1A237E);
    final textColor = Colors.white;
    final bubblyFont = 'Rubik';

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light 
          ? Colors.white 
          : Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _FullscreenPulsingBackground(
            isRunning: timerModel.running && _pulseOn,
            isWork: timerModel.isWork,
            pulseOn: _pulseOn,
          ),
          SafeArea(
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: bubblyFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (timerModel.isWork) {
                                timerModel.switchToBreak();
                              } else {
                                timerModel.switchToWork();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: themeColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                timerModel.isWork ? 'Work' : 'Break',
                                style: TextStyle(
                                  fontFamily: bubblyFont,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _pulseOn = !_pulseOn;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: themeColor.withOpacity(_pulseOn ? 1.0 : 0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: themeColor, width: 1.2),
                              ),
                              child: Text(
                                _pulseOn ? 'Pulse: On' : 'Pulse: Off',
                                style: TextStyle(
                                  fontFamily: bubblyFont,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                            seconds: timerModel.secondsLeft,
                            color: themeColor,
                            fontFamily: bubblyFont,
                          ),
                          const SizedBox(height: 40),
                          // Control Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildControlButton(
                                timerModel.running ? 'Pause' : 'Start',
                                timerModel.running ? timerModel.pauseTimer : timerModel.startTimer,
                                themeColor,
                                textColor,
                              ),
                              _buildControlButton(
                                'Reset',
                                timerModel.resetTimer,
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
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF232325) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF444444) : Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Timer Settings',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontFamily: bubblyFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _EditableAdjuster(
                                label: 'Work (min)',
                                value: timerModel.workMinutes,
                                onInc: () => timerModel.adjustWork(1),
                                onDec: () => timerModel.adjustWork(-1),
                                color: themeColor,
                                textColor: Colors.white,
                                onManualInput: (int newValue) => timerModel.setWorkMinutes(newValue),
                                isWork: true,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _EditableAdjuster(
                                label: 'Break (min)',
                                value: timerModel.breakMinutes,
                                onInc: () => timerModel.adjustBreak(1),
                                onDec: () => timerModel.adjustBreak(-1),
                                color: themeColor,
                                textColor: Colors.white,
                                onManualInput: (int newValue) => timerModel.setBreakMinutes(newValue),
                                isWork: false,
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
        ],
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
        Text(':', style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, color: color, fontSize: 64)),
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
            fontSize: 64,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _FullscreenPulsingBackground extends StatefulWidget {
  final bool isRunning;
  final bool isWork;
  final bool pulseOn;
  const _FullscreenPulsingBackground({required this.isRunning, required this.isWork, required this.pulseOn});

  @override
  State<_FullscreenPulsingBackground> createState() => _FullscreenPulsingBackgroundState();
}

class _FullscreenPulsingBackgroundState extends State<_FullscreenPulsingBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.linear);
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    if (widget.isRunning && widget.pulseOn) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _FullscreenPulsingBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning && widget.pulseOn && !_controller.isAnimating) {
      _controller.repeat();
    } else if ((!widget.isRunning || !widget.pulseOn) && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = widget.isWork ? const Color(0xFF888DFF) : const Color(0xFF1A237E);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double scale = _scaleAnim.value;
        final double opacity = _opacityAnim.value;
        return SizedBox.expand(
          child: Stack(
            children: [
              Container(color: baseColor.withOpacity(0.13)),
              if (widget.pulseOn)
                CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _GradientRipplePainter(
                    progress: scale,
                    color: baseColor,
                    opacity: opacity,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GradientRipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double opacity;
  _GradientRipplePainter({required this.progress, required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width > size.height ? size.width : size.height) * 0.7;
    final radius = maxRadius * progress;
    if (radius > 0) {
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      );
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientRipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}

class _EditableAdjuster extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final Color color;
  final Color textColor;
  final void Function(int) onManualInput;
  final bool isWork;
  const _EditableAdjuster({
    required this.label,
    required this.value,
    required this.onInc,
    required this.onDec,
    required this.color,
    required this.textColor,
    required this.onManualInput,
    required this.isWork,
  });

  @override
  Widget build(BuildContext context) {
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
            GestureDetector(
              onTap: () async {
                final newValue = await showDialog<int>(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) => _ManualInputModal(
                    initialValue: value,
                    color: color,
                    isWork: isWork,
                  ),
                );
                if (newValue != null && newValue > 0) {
                  onManualInput(newValue);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$value', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold, color: color, fontSize: 16)),
              ),
            ),
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
}

class _ManualInputModal extends StatefulWidget {
  final int initialValue;
  final Color color;
  final bool isWork;
  const _ManualInputModal({required this.initialValue, required this.color, required this.isWork});

  @override
  State<_ManualInputModal> createState() => _ManualInputModalState();
}

class _ManualInputModalState extends State<_ManualInputModal> {
  late TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modalBg = widget.isWork ? const Color(0xFF888DFF) : const Color(0xFF1A237E);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            width: double.infinity,
            height: 200,
          ),
          Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Set Minutes',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: modalBg,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 22, color: modalBg, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      errorText: _error,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _error = null;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: modalBg,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        final val = int.tryParse(_controller.text);
                        if (val == null || val <= 0) {
                          setState(() {
                            _error = 'Enter a valid number';
                          });
                        } else {
                          Navigator.of(context).pop(val);
                        }
                      },
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 