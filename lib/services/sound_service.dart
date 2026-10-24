import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// 앱 내 타이머(호흡, 심상화, 명상) 및 알림 시 맑은 사찰 명상 종소리(528Hz 싱잉볼 차임) 및 햅틱 진동을 제공하는 서비스
class SoundService {
  SoundService._();

  static AudioPlayer? _player;
  static bool _configured = false;

  /// 앱 시작 시 오디오 컨텍스트 및 플레이어 사전 초기화 (Warming up)
  static Future<void> init() async {
    await _configureAudioContext();
    _initPlayer();
  }

  static AudioPlayer _initPlayer() {
    if (_player != null) return _player!;
    final player = AudioPlayer();
    player.setReleaseMode(ReleaseMode.stop);
    _player = player;
    return player;
  }

  static Future<void> _configureAudioContext() async {
    if (_configured) return;
    try {
      final audioContext = AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media, // 미디어 음량(STREAM_MUSIC) 스트림으로 출력
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback, // 무음 모드 스위치 상태에서도 명상음 출력
          options: const {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      );
      await AudioPlayer.global.setAudioContext(audioContext);
      _configured = true;
    } catch (e) {
      debugPrint('AudioContext 설정 안내: $e');
    }
  }

  /// 맑은 명상 종소리(싱잉볼 차임)와 햅틱 피드백을 즉시 재생
  static Future<void> playChime({double volume = 1.0}) async {
    try {
      // 1. 햅틱 진동 피드백
      HapticFeedback.mediumImpact();

      // 2. AudioContext 설정 보장 (미디어 스트림 정상 출력)
      await _configureAudioContext();

      // 3. 싱글톤 플레이어로 즉각 재생
      final player = _initPlayer();
      await player.stop();
      await player.setVolume(volume.clamp(0.0, 1.0));
      await player.play(
        AssetSource('sounds/chime.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('종소리 오디오 1차 재생 시도 실패 ($e), 일반 모드로 재시도');
      try {
        final fallbackPlayer = AudioPlayer();
        await fallbackPlayer.setVolume(volume.clamp(0.0, 1.0));
        await fallbackPlayer.play(AssetSource('sounds/chime.wav'));
      } catch (err) {
        debugPrint('종소리 최종 재생 실패, 시스템 알림음으로 대체: $err');
        try {
          await SystemSound.play(SystemSoundType.alert);
        } catch (_) {}
      }
    }
  }

  /// 재생 정지
  static Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  /// 자원 해제
  static Future<void> dispose() async {
    try {
      await _player?.dispose();
      _player = null;
      _configured = false;
    } catch (_) {}
  }
}
