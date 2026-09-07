/// Mirrors `mental_domain::DisorderExplainer`: the educational card for one
/// condition — what it is, how it develops, what helps.
class DisorderExplainer {
  final String slug;
  final String category;
  final String name;
  final String whatItIs;
  final String howItDevelops;
  final List<String> copingPaths;
  final List<String> treatmentPaths;

  const DisorderExplainer({
    required this.slug,
    required this.category,
    required this.name,
    required this.whatItIs,
    required this.howItDevelops,
    required this.copingPaths,
    required this.treatmentPaths,
  });

  factory DisorderExplainer.fromJson(Map<String, dynamic> json) => DisorderExplainer(
        slug: json['slug'] as String,
        category: json['category'] as String,
        name: json['name'] as String,
        whatItIs: json['what_it_is'] as String,
        howItDevelops: json['how_it_develops'] as String,
        copingPaths: (json['coping_paths'] as List<dynamic>? ?? []).cast<String>(),
        treatmentPaths: (json['treatment_paths'] as List<dynamic>? ?? []).cast<String>(),
      );
}
