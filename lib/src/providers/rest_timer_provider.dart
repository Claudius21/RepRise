import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerState {
  final bool isRunning;
  final int remainingSeconds;
  final int totalSeconds;
  final String? exerciseName;
  final int? setNumber;

  const RestTimerState({
    this.isRunning = false,
    this.remainingSeconds = 0,
    this.totalSeconds = 0,
    this.exerciseName,
    this.setNumber,
  });

  RestTimerState copyWith({
    bool? isRunning,
    int? remainingSeconds,
    int? totalSeconds,
    String? exerciseName,
    int? setNumber,
  }) {
    return RestTimerState(
      isRunning: isRunning ?? this.isRunning,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      exerciseName: exerciseName ?? this.exerciseName,
      setNumber: setNumber ?? this.setNumber,
    );
  }

  double get progress => totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;
}

class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _timer;

  @override
  RestTimerState build() => const RestTimerState();

  void startTimer({
    required int seconds,
    required String exerciseName,
    required int setNumber,
  }) {
    _timer?.cancel();
    state = RestTimerState(
      isRunning: true,
      remainingSeconds: seconds,
      totalSeconds: seconds,
      exerciseName: exerciseName,
      setNumber: setNumber,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentRemaining = state.remainingSeconds;
      if (currentRemaining <= 1) {
        _timer?.cancel();
        state = state.copyWith(
          isRunning: false,
          remainingSeconds: 0,
        );
      } else {
        state = state.copyWith(
          remainingSeconds: currentRemaining - 1,
        );
      }
    });
  }

  void skipTimer() {
    _timer?.cancel();
    state = const RestTimerState();
  }

  void addTime(int seconds) {
    if (!state.isRunning) return;
    state = state.copyWith(
      remainingSeconds: state.remainingSeconds + seconds,
      totalSeconds: state.totalSeconds + seconds,
    );
  }

  void subtractTime(int seconds) {
    if (!state.isRunning) return;
    final newRemaining = (state.remainingSeconds - seconds).clamp(0, state.totalSeconds);
    state = state.copyWith(remainingSeconds: newRemaining);
    if (newRemaining == 0) {
      _timer?.cancel();
      state = state.copyWith(isRunning: false);
    }
  }

  void cancelTimer() {
    _timer?.cancel();
    state = const RestTimerState();
  }
}

final restTimerProvider = NotifierProvider<RestTimerNotifier, RestTimerState>(
  RestTimerNotifier.new,
);
