/// The account's current subscription entitlement, as last confirmed by
/// the backend validating an App Store receipt. Mirrors the backend's
/// `EntitlementResponse` — see `apps/server/src/routes/purchases.rs`.
class Entitlement {
  final bool isPremium;
  final DateTime? expiresAt;
  final String? productId;

  const Entitlement({required this.isPremium, this.expiresAt, this.productId});

  static const none = Entitlement(isPremium: false);

  factory Entitlement.fromJson(Map<String, dynamic> json) => Entitlement(
        isPremium: json['is_premium'] as bool? ?? false,
        expiresAt:
            json['expires_at'] == null ? null : DateTime.parse(json['expires_at'] as String),
        productId: json['product_id'] as String?,
      );
}
