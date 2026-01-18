import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

import 'pcm_audio_output.dart';

class FlutterPcmAudioOutput implements PcmAudioOutput {
  FlutterPcmAudioOutput({
    required this.sampleRate,
    this.channelCount = 1,
    this.framesPerFeed = 512,
    this.prefeedBlocks = 5,
    this.feedAheadBlocks = 3,
  });

  final int sampleRate;
  final int channelCount;
  final int framesPerFeed;
  final int prefeedBlocks;
  final int feedAheadBlocks;

  FeedCallback? _generator;
  bool _started = false;

  @override
  void setGenerator(FeedCallback generator) => _generator = generator;

  @override
  Future<void> init() async {
    FlutterPcmSound.setLogLevel(LogLevel.verbose);
    await FlutterPcmSound.setup(sampleRate: sampleRate, channelCount: channelCount, iosAudioCategory: IosAudioCategory.playback);
    await FlutterPcmSound.setFeedThreshold(sampleRate ~/ 10);
    FlutterPcmSound.setFeedCallback(_onFeed);
  }

  @override
  Future<void> start() async {
    FlutterPcmSound.start();
    _started = true;

    // prefeed
    for (int i = 0; i < prefeedBlocks; i++) {
      _pushBlock();
    }
  }

  @override
  Future<void> stop() async {
    _started = false;
    await FlutterPcmSound.release();
  }

  @override
  Future<void> dispose() async {
    _started = false;
    await FlutterPcmSound.release();
  }

  void _onFeed(int remainingFrames) {
    if (!_started) return;

    for (int i = 0; i < feedAheadBlocks; i++) {
      _pushBlock();
    }
  }

  void _pushBlock() {
    final gen = _generator;
    if (gen == null) return;
    final pcm = gen(framesPerFeed);
    FlutterPcmSound.feed(PcmArrayInt16.fromList(pcm));
  }
}
