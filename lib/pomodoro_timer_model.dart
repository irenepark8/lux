import 'package:flutter/material.dart';
import 'dart:async';

class PomodoroTimerModel extends ChangeNotifier {
  bool _isWork = true;
  int _workMinutes = 25;
  int _breakMinutes = 5;
  int _secondsLeft = 25 * 60;
  Timer? _timer;
  bool _running = false;

  bool get isWork => _isWork;
  int get workMinutes => _workMinutes;
  int get breakMinutes => _breakMinutes;
  int get secondsLeft => _secondsLeft;
  bool get running => _running;

  void startTimer() {
    if (_running) return;
    _running = true;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        _secondsLeft--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _isWork = !_isWork;
        _secondsLeft = (_isWork ? _workMinutes : _breakMinutes) * 60;
        _running = false;
        notifyListeners();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _running = false;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _secondsLeft = (_isWork ? _workMinutes : _breakMinutes) * 60;
    _running = false;
    notifyListeners();
  }

  void adjustWork(int delta) {
    _workMinutes = (_workMinutes + delta).clamp(1, 60);
    if (_isWork) _secondsLeft = _workMinutes * 60;
    notifyListeners();
  }

  void adjustBreak(int delta) {
    _breakMinutes = (_breakMinutes + delta).clamp(1, 30);
    if (!_isWork) _secondsLeft = _breakMinutes * 60;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
} 