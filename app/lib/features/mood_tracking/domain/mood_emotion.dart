/// The word list the mood check-in offers, with where each word sits on
/// the two axes the backend actually stores. Ten words, spread so that
/// every quadrant is reachable — "Gergin" (unpleasant, activated) has to
/// be as easy to say as "Sakin" (pleasant, quiet), or the check-in only
/// ever collects the moods people find easy to name.
///
/// Coordinates run -2..2 here to match how the design reasons about
/// them; [MoodEmotion.normalized] converts to the -1..1 the API takes.
class MoodEmotion {
  final String key;
  final double valence;
  final double arousal;

  const MoodEmotion(this.key, this.valence, this.arousal);
}

const moodEmotions = <MoodEmotion>[
  MoodEmotion('calm', 1, -2),
  MoodEmotion('hopeful', 2, 1),
  MoodEmotion('tired', -1, -2),
  MoodEmotion('tense', -1, 2),
  MoodEmotion('unsure', 0, 1),
  MoodEmotion('relieved', 2, -1),
  MoodEmotion('heavy', -2, -1),
  MoodEmotion('joyful', 2, 2),
  MoodEmotion('angry', -2, 2),
  MoodEmotion('empty', -1, -1),
];

extension MoodEmotionMath on MoodEmotion {
  double get normalizedValence => valence / 2;
  double get normalizedArousal => arousal / 2;
}

/// The average position of a set of words, in the -1..1 the API takes.
/// An empty selection sits at dead centre rather than nowhere.
({double valence, double arousal}) averageOf(Set<String> keys) {
  final picked = moodEmotions.where((e) => keys.contains(e.key)).toList();
  if (picked.isEmpty) return (valence: 0, arousal: 0);

  final v = picked.map((e) => e.normalizedValence).reduce((a, b) => a + b) / picked.length;
  final a = picked.map((e) => e.normalizedArousal).reduce((a, b) => a + b) / picked.length;
  return (valence: v, arousal: a);
}
