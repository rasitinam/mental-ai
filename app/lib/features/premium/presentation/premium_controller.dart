import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/purchase_api.dart';
import '../domain/entitlement.dart';

/// Must match the product id created in App Store Connect under Hearth's
/// subscription group.
const premiumMonthlyProductId = 'com.rasitinam.hearth.premium.monthly';

class PremiumState {
  final bool loadingProducts;
  final ProductDetails? monthly;
  final bool purchasing;
  final bool restoring;
  final Object? error;
  final Entitlement entitlement;

  const PremiumState({
    this.loadingProducts = true,
    this.monthly,
    this.purchasing = false,
    this.restoring = false,
    this.error,
    this.entitlement = Entitlement.none,
  });

  PremiumState copyWith({
    bool? loadingProducts,
    ProductDetails? monthly,
    bool? purchasing,
    bool? restoring,
    Object? error,
    Entitlement? entitlement,
  }) =>
      PremiumState(
        loadingProducts: loadingProducts ?? this.loadingProducts,
        monthly: monthly ?? this.monthly,
        purchasing: purchasing ?? this.purchasing,
        restoring: restoring ?? this.restoring,
        error: error,
        entitlement: entitlement ?? this.entitlement,
      );
}

final premiumControllerProvider =
    NotifierProvider<PremiumController, PremiumState>(PremiumController.new);

/// Owns the StoreKit/Play Billing purchase flow. The store is the only
/// thing that ever says "this purchase succeeded" — the moment it does,
/// this hands the resulting receipt to the backend (`PurchaseApi.verifyApple`)
/// and only trusts *that* answer for `entitlement`, never a local flag set
/// the instant `buyNonConsumable` returns.
class PremiumController extends Notifier<PremiumState> {
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  PremiumState build() {
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {},
    );
    ref.onDispose(() => _subscription?.cancel());
    Future.microtask(_load);
    return const PremiumState();
  }

  Future<void> _load() async {
    final iap = InAppPurchase.instance;
    final available = await iap.isAvailable();
    if (!available) {
      // `monthly` stays null, which the screen already reads as "nothing
      // to sell right now" — no separate error needed on top of that.
      state = state.copyWith(loadingProducts: false);
      return;
    }

    final response = await iap.queryProductDetails({premiumMonthlyProductId});
    final product = response.productDetails.isEmpty ? null : response.productDetails.first;

    final entitlement = await ref.read(purchaseApiProvider).current().catchError((_) => Entitlement.none);

    state = state.copyWith(loadingProducts: false, monthly: product, entitlement: entitlement);
  }

  Future<void> buy() async {
    final product = state.monthly;
    if (product == null) return;

    state = state.copyWith(purchasing: true, error: null);
    // Subscriptions go through `buyNonConsumable` in this package's
    // cross-platform API — StoreKit/Play Billing own renewal, this call
    // is just "start the purchase sheet".
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  /// Re-links a purchase already on the App Store account — needed the
  /// first time someone opens the app on a new device or after a
  /// reinstall, since a subscription isn't tied to local app state.
  Future<void> restore() async {
    state = state.copyWith(restoring: true, error: null);
    await InAppPurchase.instance.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          continue;
        case PurchaseStatus.error:
          state = state.copyWith(purchasing: false, restoring: false, error: purchase.error);
        case PurchaseStatus.canceled:
          state = state.copyWith(purchasing: false, restoring: false);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            final entitlement = await ref
                .read(purchaseApiProvider)
                .verifyApple(purchase.verificationData.serverVerificationData);
            state = state.copyWith(purchasing: false, restoring: false, entitlement: entitlement);
          } catch (e) {
            state = state.copyWith(purchasing: false, restoring: false, error: e);
          }
      }

      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }
}
