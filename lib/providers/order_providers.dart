import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/validators.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../repositories/order_repository.dart';
import 'auth_providers.dart';
import 'user_providers.dart';

final orderRepositoryProvider =
    Provider((ref) => OrderRepository(ref.watch(firestoreProvider)));

/// Orders received by the signed-in seller (live, newest first).
final sellerOrdersProvider = StreamProvider<List<CustomerOrder>>((ref) {
  final uid = ref.watch(currentUserProvider
      .select((u) => (u != null && u.isSeller) ? u.uid : null));
  if (uid == null) return Stream.value(const <CustomerOrder>[]);
  return ref.watch(orderRepositoryProvider).watchSellerOrders(uid);
});

/// Orders placed by the signed-in customer (live, newest first).
final customerOrdersProvider = StreamProvider<List<CustomerOrder>>((ref) {
  final uid = ref.watch(currentUserProvider
      .select((u) => (u != null && u.isCustomer) ? u.uid : null));
  if (uid == null) return Stream.value(const <CustomerOrder>[]);
  return ref.watch(orderRepositoryProvider).watchCustomerOrders(uid);
});

final orderProvider = StreamProvider.autoDispose.family<CustomerOrder?, String>(
    (ref, id) => ref.watch(orderRepositoryProvider).watchOrder(id));

final pendingOrderCountProvider = Provider<int>((ref) =>
    ref
        .watch(sellerOrdersProvider)
        .valueOrNull
        ?.where((o) => o.status == OrderStatus.pending)
        .length ??
    0);

// ---------------------------------------------------------------------------
// Seller actions
// ---------------------------------------------------------------------------
final sellerOrderControllerProvider =
    AsyncNotifierProvider<SellerOrderController, void>(
        SellerOrderController.new);

class SellerOrderController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  String _sellerUid() {
    final u = ref.read(currentUserProvider);
    if (u == null || !u.isSeller) {
      throw const AppException("You don't have permission to perform this action.");
    }
    return u.uid;
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  /// Pending -> Confirmed, deducting stock in a transaction (Rules 6 and 8).
  Future<bool> accept(CustomerOrder o) =>
      _run(() => _repo.acceptOrder(o.orderId, _sellerUid()));

  /// Pending -> Rejected. No inventory change (Rule 7).
  Future<bool> reject(CustomerOrder o) => _run(
      () => _repo.changeStatus(o.orderId, _sellerUid(), OrderStatus.rejected));

  /// Moves the order to its next status (Rule 12).
  Future<bool> advance(CustomerOrder o) => _run(() {
        final next = o.status.next;
        if (next == null || next == OrderStatus.confirmed) {
          throw const AppException('There is no next step for this order.');
        }
        return _repo.changeStatus(o.orderId, _sellerUid(), next);
      });
}

// ---------------------------------------------------------------------------
// Checkout
// ---------------------------------------------------------------------------
final checkoutControllerProvider =
    AsyncNotifierProvider<CheckoutController, void>(CheckoutController.new);

class CheckoutController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Validates the form data, then creates one order per seller.
  /// Returns the created orders, or null on failure (see [state] for why).
  Future<List<CustomerOrder>?> placeOrder({
    required DeliveryAddress address,
    required PaymentMethod method,
    String? paymentReference,
    required List<PlaceOrderGroup> groups,
    required bool clearCart,
  }) async {
    final user = ref.read(currentUserProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      if (user == null || !user.isCustomer) {
        throw const AppException(
            "You don't have permission to perform this action.");
      }
      if (groups.isEmpty || groups.every((g) => g.lines.isEmpty)) {
        throw const AppException('Select at least one item to check out.');
      }
      if (address.fullName.trim().length < 2) {
        throw const AppException('Enter the recipient name.');
      }
      if (Validators.phone(address.phone, isRequired: true) != null) {
        throw const AppException('Enter a valid phone number (09XXXXXXXXX).');
      }
      if (address.address.trim().length < 5) {
        throw const AppException('Enter your street address.');
      }
      if (!address.location.isComplete) {
        throw const AppException(
            'Choose a delivery location (region, city and barangay).');
      }
      if (method == PaymentMethod.gcash &&
          (paymentReference == null || paymentReference.trim().length < 6)) {
        throw const AppException('Enter your GCash reference number.');
      }
      return ref.read(orderRepositoryProvider).placeOrders(
            customerId: user.uid,
            address: address,
            method: method,
            paymentReference:
                method == PaymentMethod.gcash ? paymentReference!.trim() : null,
            groups: groups,
            clearCart: clearCart,
          );
    });
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace ?? StackTrace.current)
        : const AsyncData(null);
    return result.valueOrNull;
  }
}
