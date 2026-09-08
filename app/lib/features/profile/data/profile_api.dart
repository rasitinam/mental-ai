import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/user_profile.dart';

final profileApiProvider = Provider<ProfileApi>((ref) => ProfileApi(ref.watch(apiClientProvider)));

class ProfileApi {
  final Dio _dio;
  ProfileApi(this._dio);

  Future<UserProfile> profile() async {
    final response = await _dio.get('/profile');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Replaces the whole list — the screen edits it as a set of checkboxes,
  /// so there's nothing partial to send.
  Future<UserProfile> setDiagnoses(List<String> diagnoses) async {
    final response = await _dio.put('/profile/diagnoses', data: {'diagnoses': diagnoses});
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Language and birth year. Both are optional and omitted fields keep
  /// their stored value, so changing the language doesn't require the screen
  /// to resend a birth year the person never gave.
  Future<UserProfile> setPreferences({String? language, int? birthYear}) async {
    final response = await _dio.put('/profile/preferences', data: {
      'language': ?language,
      'birth_year': ?birthYear,
    });
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }
}
