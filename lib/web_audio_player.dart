import 'dart:js_interop';

@JS('Audio')
extension type _JSAudio._(JSObject _) implements JSObject {
  external factory _JSAudio();
  external set src(String value);
  external set loop(bool value);
  external set preload(String value);
  external set currentTime(num value);
  external set volume(num value);
  external JSPromise play();
  external void pause();
}

class WebAudioPlayer {
  _JSAudio? _audio;

  void load(String assetPath) {
    _audio = _JSAudio()
      ..src = 'assets/$assetPath'
      ..loop = true
      ..preload = 'auto'
      ..volume = 0.5;
  }

  void play() {
    _audio?.play();
  }

  void stop() {
    final audio = _audio;
    if (audio == null) return;
    audio.pause();
    audio.currentTime = 0;
  }

  void dispose() {
    stop();
    _audio = null;
  }
}
