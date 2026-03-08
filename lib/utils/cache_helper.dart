import 'dart:async';
import 'package:app1/utils/debugger.dart';
import 'package:flutter/foundation.dart';

class _PendingJob {
  final Future<void> Function() action;
  Timer? timer;

  _PendingJob(this.action);
}

class CacheHelper extends ChangeNotifier {
  static final CacheHelper instance = CacheHelper._internal();
  CacheHelper._internal();

  _PendingJob? _pendingJob;

  static const int _delaySeconds = 5;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;

  bool get hasPendingJob => _pendingJob != null;
  int get remainingSeconds => _remainingSeconds;

  void schedule(Future<void> Function() action) {
    AppLogger.instance.log("cache helper is called!");
    _commitPending();

    _pendingJob = _PendingJob(action);
    _remainingSeconds = _delaySeconds;

    notifyListeners();

    // ⏱️ Geri sayım timer
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _remainingSeconds--;
        notifyListeners();

        if (_remainingSeconds <= 0) {
          timer.cancel();
        }
      },
    );

    // ⏳ Asıl commit timer
    _pendingJob!.timer = Timer(
      const Duration(seconds: _delaySeconds),
      () async {
        await action();
        _clearPending();
      },
    );
  }

  Future<void> commitNow() async {
    await _commitPending();
  }

  void cancelPending() {
    _clearPending();
  }

  Future<void> _commitPending() async {
    if (_pendingJob != null) {
      _pendingJob!.timer?.cancel();
      _countdownTimer?.cancel();
      await _pendingJob!.action();
      _clearPending();
    }
  }

  void _clearPending() {
    _pendingJob?.timer?.cancel();
    _countdownTimer?.cancel();
    _pendingJob = null;
    _remainingSeconds = 0;
    notifyListeners();
  }
}


