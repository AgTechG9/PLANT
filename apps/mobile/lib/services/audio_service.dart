import 'dart:ui';
import 'audio_service_stub.dart'
    if (dart.library.html) 'audio_service_web.dart';

abstract class AudioPlayerService {
  static AudioPlayerService get instance => getAudioPlayer();
  void play(String url, {VoidCallback? onComplete});
  void stop();
  bool get isPlaying;
}
