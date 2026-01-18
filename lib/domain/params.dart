class EnvelopeParams {
  const EnvelopeParams({
    this.attackSec = 0.01,
    this.decaySec = 0.08,
    this.sustainLevel = 0.6,
    this.holdSec = 0.0,
    this.releaseSec = 0.12,
  });

  final double attackSec;
  final double decaySec;
  final double sustainLevel;
  final double holdSec;
  final double releaseSec;

  EnvelopeParams copyWith({double? attackSec, double? decaySec, double? sustainLevel, double? holdSec, double? releaseSec}) {
    return EnvelopeParams(
      attackSec: attackSec ?? this.attackSec,
      decaySec: decaySec ?? this.decaySec,
      sustainLevel: sustainLevel ?? this.sustainLevel,
      holdSec: holdSec ?? this.holdSec,
      releaseSec: releaseSec ?? this.releaseSec,
    );
  }
}
