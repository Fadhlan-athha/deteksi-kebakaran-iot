import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class AlarmService {
  static const String _conditionAman = 'AMAN';
  static const String _conditionNormal = 'NORMAL';
  static const String _conditionWaspada = 'WASPADA';
  static const String _conditionDarurat = 'DARURAT';

  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _vibrationTimer;
  String? _lastCondition;
  String? _activeAudioCondition;
  String? _activeVibrationCondition;
  bool _disposed = false;

  Future<void> handleCondition(String kondisi) async {
    final String normalizedCondition = _normalizeCondition(kondisi);

    if (_lastCondition == normalizedCondition) {
      return;
    }

    _lastCondition = normalizedCondition;

    try {
      if (normalizedCondition == _conditionWaspada) {
        await playWaspadaAlarm();
        await startWaspadaVibrationLoop();
      } else if (normalizedCondition == _conditionDarurat) {
        await playDaruratAlarm();
        await startDaruratVibrationLoop();
      } else {
        await _stopAlarm(keepLastCondition: true);
      }
    } catch (_) {
      await _stopAlarm(keepLastCondition: true);
    }
  }

  Future<void> playWaspadaAlarm() async {
    if (_disposed || _activeAudioCondition == _conditionWaspada) {
      return;
    }

    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('audio/alarm_waspada.mp3'));
    _activeAudioCondition = _conditionWaspada;
  }

  Future<void> playDaruratAlarm() async {
    if (_disposed || _activeAudioCondition == _conditionDarurat) {
      return;
    }

    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('audio/alarm_darurat.mp3'));
    _activeAudioCondition = _conditionDarurat;
  }

  Future<void> stopAlarm() async {
    await _stopAlarm();
  }

  Future<void> startWaspadaVibrationLoop() async {
    await _startVibrationLoop(
      condition: _conditionWaspada,
      vibrateDuration: const Duration(milliseconds: 500),
      pauseDuration: const Duration(milliseconds: 700),
    );
  }

  Future<void> startDaruratVibrationLoop() async {
    await _startVibrationLoop(
      condition: _conditionDarurat,
      vibrateDuration: const Duration(milliseconds: 1000),
      pauseDuration: const Duration(milliseconds: 300),
    );
  }

  void stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    _activeVibrationCondition = null;
    Vibration.cancel();
  }

  Future<void> dispose() async {
    _disposed = true;
    stopVibration();
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
  }

  String _normalizeCondition(String kondisi) {
    final String normalized = kondisi.trim().toUpperCase();

    if (normalized == _conditionWaspada || normalized == _conditionDarurat) {
      return normalized;
    }

    if (normalized == _conditionAman || normalized == _conditionNormal) {
      return _conditionAman;
    }

    return _conditionAman;
  }

  Future<void> _startVibrationLoop({
    required String condition,
    required Duration vibrateDuration,
    required Duration pauseDuration,
  }) async {
    if (_disposed || _activeVibrationCondition == condition) {
      return;
    }

    stopVibration();

    final bool canVibrate = await Vibration.hasVibrator();

    if (!canVibrate || _disposed) {
      return;
    }

    _activeVibrationCondition = condition;

    void vibrate() {
      if (_disposed || _activeVibrationCondition != condition) {
        return;
      }

      Vibration.vibrate(duration: vibrateDuration.inMilliseconds);
    }

    vibrate();
    _vibrationTimer = Timer.periodic(
      vibrateDuration + pauseDuration,
      (_) => vibrate(),
    );
  }

  Future<void> _stopAlarm({bool keepLastCondition = false}) async {
    if (!keepLastCondition) {
      _lastCondition = null;
    }

    stopVibration();
    _activeAudioCondition = null;
    await _audioPlayer.stop();
  }
}
