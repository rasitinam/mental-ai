import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../domain/user_profile.dart';

final profileApiProvider = Provider<ProfileApi>((ref) => ProfileApi(ref.watch(apiClientProvider)));

/// The signed-in user's avatar bytes, or `null` when they haven't uploaded
/// one. A `FutureProvider` rather than a field on [ProfileState] — the
/// image is fetched once and displayed with `Image.memory`, entirely
/// separate from the rest of the profile form's load/save cycle.
final avatarBytesProvider = FutureProvider<Uint8List?>((ref) => ref.watch(profileApiProvider).fetchAvatar());

/// One-shot fetch used to decide whether to show admin-only entry points
/// (the story moderation queue) — a full [ProfileController] would be
/// overkill just to read `isAdmin` off of it.
final myProfileProvider = FutureProvider<UserProfile>((ref) => ref.watch(profileApiProvider).profile());

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

  /// Replaces the conversation ground rules — what the person asked the
  /// app not to do. Sent as a whole set (never merged), so clearing every
  /// box is a meaningful answer rather than a no-op.
  Future<UserProfile> setChatBoundaries({
    required List<String> boundaries,
    String? note,
  }) async {
    final response = await _dio.put('/profile/chat-boundaries', data: {
      'boundaries': boundaries,
      'note': note,
    });
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Display name, language and birth year. All three are optional and
  /// omitted fields keep their stored value, so changing the language
  /// doesn't require the screen to resend a birth year — or a name — the
  /// person didn't touch.
  Future<UserProfile> setPreferences({
    String? displayName,
    String? language,
    int? birthYear,
    String? dmPolicy,
    int? utcOffsetMinutes,
  }) async {
    final response = await _dio.put('/profile/preferences', data: {
      'display_name': ?displayName,
      'language': ?language,
      'birth_year': ?birthYear,
      'dm_policy': ?dmPolicy,
      'utc_offset_minutes': ?utcOffsetMinutes,
    });
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Turns the evening check-in reminder on or off and sets its local
  /// hour (17-23, enforced server-side).
  Future<UserProfile> setCheckinReminder({required bool enabled, required int hour}) async {
    final response = await _dio.put('/profile/checkin-reminder', data: {
      'enabled': enabled,
      'hour': hour,
    });
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Replaces the profile photo with the picked image. The content type is
  /// read off the file's extension rather than `XFile.mimeType` — that
  /// field isn't reliably populated across every platform image_picker
  /// supports, while the extension always is.
  Future<UserProfile> uploadAvatar(XFile file) async {
    final bytes = await file.readAsBytes();
    final response = await _dio.put(
      '/profile/avatar',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name,
          contentType: MediaType.parse(_contentTypeFor(file.name)),
        ),
      }),
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// The signed-in user's avatar, or `null` if they haven't uploaded one.
  Future<Uint8List?> fetchAvatar() async {
    try {
      final response = await _dio.get<List<int>>(
        '/profile/avatar',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  String _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
