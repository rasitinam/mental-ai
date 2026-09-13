import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/entitlement.dart';

final purchaseApiProvider = Provider<PurchaseApi>((ref) => PurchaseApi(ref.watch(apiClientProvider)));

class PurchaseApi {
  final Dio _dio;
  PurchaseApi(this._dio);

  /// Sends an App Store receipt to the backend, which validates it with
  /// Apple directly (never trusting the client's own read of it) and
  /// records the resulting entitlement.
  Future<Entitlement> verifyApple(String receiptData) async {
    final response =
        await _dio.post('/purchases/verify-apple', data: {'receipt_data': receiptData});
    return Entitlement.fromJson(response.data as Map<String, dynamic>);
  }

  /// The account's entitlement as of the last verified receipt — read on
  /// launch so a returning subscriber doesn't have to trigger a new
  /// purchase just to unlock what they already pay for.
  Future<Entitlement> current() async {
    final response = await _dio.get('/purchases/subscription');
    return Entitlement.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Watched wherever a screen needs to gate on premium status. `autoDispose`
/// so it re-fetches fresh each time a paywall or premium-gated screen is
/// opened, rather than caching a stale "not premium" from before someone
/// subscribed.
final entitlementProvider = FutureProvider.autoDispose<Entitlement>((ref) async {
  try {
    return await ref.watch(purchaseApiProvider).current();
  } catch (_) {
    return Entitlement.none;
  }
});
