import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final onboardingApiProvider =
    Provider<OnboardingApi>((ref) => OnboardingApi(ref.watch(apiClientProvider)));

/// What the server made of the first thing someone typed: a reply to show
/// them, plus the rules it stored on their account as a result.
class IntroUnderstanding {
  final String reply;
  final List<String> boundaries;
  final String? note;

  const IntroUnderstanding({required this.reply, required this.boundaries, this.note});

  factory IntroUnderstanding.fromJson(Map<String, dynamic> json) => IntroUnderstanding(
        reply: json['reply'] as String,
        boundaries:
            (json['boundaries'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
        note: json['note'] as String?,
      );
}

class OnboardingApi {
  final Dio _dio;
  OnboardingApi(this._dio);

  /// The opening exchange: their answer to "how do you want me to be with
  /// you?" goes up as prose, and comes back both answered and turned into
  /// the conversation rules every later reply is bound by.
  Future<IntroUnderstanding> sendIntro(String answer) async {
    final response = await _dio.post('/onboarding/intro', data: {'answer': answer});
    return IntroUnderstanding.fromJson(response.data as Map<String, dynamic>);
  }
}
