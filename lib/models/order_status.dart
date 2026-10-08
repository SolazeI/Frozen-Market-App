/// Order workflow:
///   pending -> confirmed -> preparing -> out_for_delivery -> delivered
/// plus rejected (seller) and cancelled (customer, while pending).
enum OrderStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  preparing('preparing', 'Preparing'),
  outForDelivery('out_for_delivery', 'Out for Delivery'),
  delivered('delivered', 'Delivered'),
  rejected('rejected', 'Rejected'),
  cancelled('cancelled', 'Cancelled');

  const OrderStatus(this.value, this.label);
  final String value; // stored in Firestore
  final String label;

  static OrderStatus parse(String? v) => OrderStatus.values
      .firstWhere((s) => s.value == v, orElse: () => OrderStatus.pending);

  bool get isFinal =>
      this == OrderStatus.delivered ||
      this == OrderStatus.rejected ||
      this == OrderStatus.cancelled;

  /// The next step in the normal flow (null once finished).
  OrderStatus? get next => switch (this) {
        OrderStatus.pending => OrderStatus.confirmed,
        OrderStatus.confirmed => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.outForDelivery,
        OrderStatus.outForDelivery => OrderStatus.delivered,
        _ => null,
      };

  /// Rule 12: only these transitions are allowed (mirrored in Firestore rules).
  bool canTransitionTo(OrderStatus n) => switch (this) {
        OrderStatus.pending => n == OrderStatus.confirmed ||
            n == OrderStatus.rejected ||
            n == OrderStatus.cancelled,
        OrderStatus.confirmed => n == OrderStatus.preparing,
        OrderStatus.preparing => n == OrderStatus.outForDelivery,
        OrderStatus.outForDelivery => n == OrderStatus.delivered,
        _ => false,
      };

  /// Button text for the seller's next action.
  String? get actionLabel => switch (this) {
        OrderStatus.confirmed => 'Start preparing',
        OrderStatus.preparing => 'Out for delivery',
        OrderStatus.outForDelivery => 'Mark as delivered',
        _ => null,
      };
}
