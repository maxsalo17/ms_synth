import 'dart:typed_data';

typedef FeedCallback = Int16List Function(int frames);

abstract class PcmAudioOutput {
  Future<void> init();
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();

  void setGenerator(FeedCallback generator);
}
