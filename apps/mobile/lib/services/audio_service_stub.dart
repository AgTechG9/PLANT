import 'dart:ui';
import 'audio_service.dart';

AudioPlayerService getAudioPlayer() => StubAudioPlayer();

class StubAudioPlayer implements AudioPlayerService {
  bool _isPlaying = false;

  @override
  bool get isPlaying => _isPlaying;

  @override
  void play(String url, {VoidCallback? onComplete}) {
    _isPlaying = true;
  }

  @override
  void stop() {
    _isPlaying = false;
  }
}
