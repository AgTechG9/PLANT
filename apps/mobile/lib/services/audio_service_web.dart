import 'dart:js_interop';
import 'dart:ui';
import 'package:web/web.dart' as web;
import 'audio_service.dart';

AudioPlayerService getAudioPlayer() => WebAudioPlayer();

class WebAudioPlayer implements AudioPlayerService {
  web.HTMLAudioElement? _audio;
  bool _isPlaying = false;

  @override
  bool get isPlaying => _isPlaying;

  @override
  void play(String url, {VoidCallback? onComplete}) {
    stop();
    _audio = web.HTMLAudioElement()..src = url;
    _isPlaying = true;
    _audio!.onended = ((web.Event _) {
      _isPlaying = false;
      if (onComplete != null) onComplete();
    }).toJS;
    _audio!.onerror = ((web.Event _) {
      _isPlaying = false;
      if (onComplete != null) onComplete();
    }).toJS;
    _audio!.play();
  }

  @override
  void stop() {
    if (_audio != null) {
      _audio!.pause();
      _audio!.currentTime = 0;
      _audio = null;
    }
    _isPlaying = false;
  }
}
