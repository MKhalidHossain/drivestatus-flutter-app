import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../../core/helpers/subscription_access.dart';
import '../../../core/services/app_pigeon/app_pigeon.dart';
import '../../profile/model/profile_data.dart';

/// Central service for managing subscription products and purchase updates.
///
/// This class intentionally keeps store logic out of widgets so the same
/// purchase flow can be reused from multiple screens and initialized at app
/// startup.
class SubscriptionService {
  SubscriptionService({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  static const String monthlyProductId = 'month_subscription';
  static const String yearlyProductId = 'yearly_subscription';
  static const Set<String> _subscriptionProductIds = <String>{
    monthlyProductId,
    yearlyProductId,
  };

  final InAppPurchase _inAppPurchase;
  final StreamController<SubscriptionPurchaseEvent> _purchaseEventsController =
      StreamController<SubscriptionPurchaseEvent>.broadcast();
  final Map<String, ProductDetails> _productsById = <String, ProductDetails>{};
  final Map<String, PurchaseDetails> _activePurchasesById =
      <String, PurchaseDetails>{};

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _storeAvailable = false;
  String? _lastErrorMessage;

  Stream<SubscriptionPurchaseEvent> get purchaseEvents =>
      _purchaseEventsController.stream;

  bool get isInitialized => _isInitialized;
  bool get isStoreAvailable => _storeAvailable;
  String? get lastErrorMessage => _lastErrorMessage;

  /// Starts listening to purchase updates and primes the cached products.
  Future<void> initialize() async {
    if (_isDisposed || _isInitialized) return;

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error, StackTrace stackTrace) {
        _lastErrorMessage =
            'A purchase update error occurred. Please try again.';
        _emitEvent(
          SubscriptionPurchaseEvent.error(message: _lastErrorMessage!),
        );
      },
    );

    try {
      _storeAvailable = await _inAppPurchase.isAvailable();
      if (!_storeAvailable) {
        _lastErrorMessage =
            'The store is currently unavailable on this device.';
        _isInitialized = true;
        return;
      }

      await _refreshPastPurchases();
      await getAvailableProducts();
      _isInitialized = true;
    } catch (error) {
      _lastErrorMessage =
          'Failed to initialize subscriptions: ${_humanizeError(error)}';
      _emitEvent(SubscriptionPurchaseEvent.error(message: _lastErrorMessage!));
      _isInitialized = true;
    }
  }

  /// Loads subscription products from the underlying store.
  Future<List<ProductDetails>> getAvailableProducts() async {
    if (_isDisposed) return const <ProductDetails>[];
    if (!_storeAvailable) {
      _storeAvailable = await _inAppPurchase.isAvailable();
    }

    if (!_storeAvailable) {
      _lastErrorMessage =
          'The store is currently unavailable. Please try again later.';
      return const <ProductDetails>[];
    }

    try {
      final response = await _inAppPurchase.queryProductDetails(
        _subscriptionProductIds,
      );

      if (response.error != null) {
        _lastErrorMessage = response.error!.message;
        throw SubscriptionException(_lastErrorMessage!);
      }

      _productsById
        ..clear()
        ..addEntries(
          response.productDetails.map(
            (product) => MapEntry(product.id, product),
          ),
        );

      if (response.notFoundIDs.isNotEmpty) {
        _lastErrorMessage =
            'Missing subscription products: ${response.notFoundIDs.join(', ')}';
      } else {
        _lastErrorMessage = null;
      }

      return _sortProducts(response.productDetails);
    } catch (error) {
      _lastErrorMessage =
          'Unable to load subscription products: ${_humanizeError(error)}';
      throw SubscriptionException(_lastErrorMessage!);
    }
  }

  /// Launches the monthly subscription purchase flow.
  Future<void> purchaseMonthlySubscription() {
    return _startPurchaseFlow(monthlyProductId);
  }

  /// Launches the yearly subscription purchase flow.
  Future<void> purchaseYearlySubscription() {
    return _startPurchaseFlow(yearlyProductId);
  }

  /// Returns whether the current user has an active subscription snapshot.
  ///
  /// On Android we can refresh past purchases directly from Play Billing.
  /// On Apple platforms, restoring previous transactions is normally a user-
  /// initiated action, so this method falls back to the locally synced profile
  /// snapshot plus any in-session purchase updates.
  Future<bool> isUserSubscribed() async {
    if (SubscriptionAccess.isCurrentSubscriptionActive()) {
      return true;
    }

    if (_isAndroid) {
      await _refreshPastPurchases();
    }

    return _activePurchasesById.keys.any(_subscriptionProductIds.contains);
  }

  /// Releases stream subscriptions and controllers.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    _purchaseEventsController.close();
  }

  Future<void> _startPurchaseFlow(String productId) async {
    if (_isDisposed) return;
    if (!_isInitialized) {
      await initialize();
    }

    final product = _productsById[productId] ?? await _loadProduct(productId);
    if (product == null) {
      final message = 'The selected subscription is not available.';
      _lastErrorMessage = message;
      throw SubscriptionException(message);
    }

    try {
      _emitEvent(
        SubscriptionPurchaseEvent.pending(
          productId: productId,
          message: 'Opening the store purchase sheet...',
        ),
      );

      final purchaseParam = _buildPurchaseParam(product);
      final launched = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!launched) {
        throw SubscriptionException(
          'The store purchase sheet could not be opened.',
        );
      }
    } catch (error) {
      final message = 'Unable to start the purchase: ${_humanizeError(error)}';
      _lastErrorMessage = message;
      _emitEvent(
        SubscriptionPurchaseEvent.error(productId: productId, message: message),
      );
      rethrow;
    }
  }

  Future<ProductDetails?> _loadProduct(String productId) async {
    final products = await getAvailableProducts();
    for (final product in products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  PurchaseParam _buildPurchaseParam(ProductDetails product) {
    if (_isAndroid) {
      final oldPurchase = _findExistingAndroidSubscription();
      return GooglePlayPurchaseParam(
        productDetails: product,
        changeSubscriptionParam: oldPurchase != null
            ? ChangeSubscriptionParam(
                oldPurchaseDetails: oldPurchase,
                replacementMode: ReplacementMode.withTimeProration,
              )
            : null,
      );
    }

    return PurchaseParam(productDetails: product);
  }

  GooglePlayPurchaseDetails? _findExistingAndroidSubscription() {
    for (final purchase in _activePurchasesById.values) {
      if (purchase is GooglePlayPurchaseDetails &&
          _subscriptionProductIds.contains(purchase.productID)) {
        return purchase;
      }
    }
    return null;
  }

  Future<void> _refreshPastPurchases() async {
    if (_isDisposed || !_isAndroid || !_storeAvailable) return;

    try {
      final addition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();

      if (response.error != null) {
        _lastErrorMessage = response.error!.message;
        return;
      }

      for (final purchase in response.pastPurchases) {
        if (_subscriptionProductIds.contains(purchase.productID)) {
          _rememberPurchase(purchase);
        }
      }
    } catch (error) {
      _lastErrorMessage =
          'Unable to refresh past purchases: ${_humanizeError(error)}';
    }
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (!_subscriptionProductIds.contains(purchaseDetails.productID)) {
        await _completePurchaseIfNeeded(purchaseDetails);
        continue;
      }

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _emitEvent(
            SubscriptionPurchaseEvent.pending(
              productId: purchaseDetails.productID,
              message: 'Your subscription purchase is pending confirmation.',
            ),
          );
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _finalizeSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          _lastErrorMessage =
              purchaseDetails.error?.message ??
              'The purchase could not be completed.';
          _emitEvent(
            SubscriptionPurchaseEvent.error(
              productId: purchaseDetails.productID,
              message: _lastErrorMessage!,
            ),
          );
          break;
        case PurchaseStatus.canceled:
          _emitEvent(
            SubscriptionPurchaseEvent.canceled(
              productId: purchaseDetails.productID,
              message: 'Purchase canceled.',
            ),
          );
          break;
      }

      await _completePurchaseIfNeeded(purchaseDetails);
    }
  }

  Future<void> _finalizeSuccessfulPurchase(PurchaseDetails purchase) async {
    try {
      // Production apps should verify receipts/purchase tokens on a secure
      // backend before granting access. This sample grants access after the
      // store reports a successful or restored transaction.
      _rememberPurchase(purchase);
      await _persistSubscription(purchase);

      final message = purchase.status == PurchaseStatus.restored
          ? 'Subscription restored successfully.'
          : 'Subscription activated successfully.';

      _emitEvent(
        SubscriptionPurchaseEvent.success(
          productId: purchase.productID,
          message: message,
        ),
      );
    } catch (error) {
      _lastErrorMessage =
          'Failed to finish the purchase: ${_humanizeError(error)}';
      _emitEvent(
        SubscriptionPurchaseEvent.error(
          productId: purchase.productID,
          message: _lastErrorMessage!,
        ),
      );
    }
  }

  void _rememberPurchase(PurchaseDetails purchase) {
    _activePurchasesById[purchase.productID] = purchase;
  }

  Future<void> _persistSubscription(PurchaseDetails purchase) async {
    final startsAt =
        _readTransactionDateUtc(purchase) ?? DateTime.now().toUtc();
    final interval = _intervalForProductId(purchase.productID);
    final endsAt =
        SubscriptionAccess.estimateSubscriptionEndsAt(
          startsAtUtc: startsAt,
          interval: interval,
        ) ??
        startsAt;

    final planName = _planNameForProductId(purchase.productID);

    ProfileData.instance.updateSubscription(
      subscribed: true,
      planName: planName,
      subscriptionInterval: interval,
      subscriptionStartsAt: startsAt.toIso8601String(),
      subscriptionEndsAt: endsAt.toIso8601String(),
    );

    await _persistSubscriptionToCurrentAuth(
      subscriptionPlanId: purchase.productID,
      planName: planName,
      subscriptionInterval: interval,
      subscriptionStartsAt: startsAt.toIso8601String(),
      subscriptionEndsAt: endsAt.toIso8601String(),
    );
  }

  Future<void> _persistSubscriptionToCurrentAuth({
    required String subscriptionPlanId,
    required String planName,
    required String subscriptionInterval,
    required String subscriptionStartsAt,
    required String subscriptionEndsAt,
  }) async {
    try {
      final appPigeon = Get.find<AppPigeon>();
      final status = await appPigeon.currentAuth();
      if (status is! Authenticated) return;

      final accessToken = status.auth.accessToken ?? '';
      final refreshToken = status.auth.refreshToken ?? '';
      if (accessToken.isEmpty || refreshToken.isEmpty) return;

      final authData = Map<String, dynamic>.from(status.auth.data);
      authData['subscribed'] = true;
      authData['subscriptionPlanId'] = subscriptionPlanId;
      authData['planId'] = subscriptionPlanId;
      authData['planName'] = planName;
      authData['subscriptionInterval'] = subscriptionInterval;
      authData['subscriptionStartsAt'] = subscriptionStartsAt;
      authData['subscriptionEndsAt'] = subscriptionEndsAt;

      await appPigeon.updateCurrentAuth(
        updateAuthParams: UpdateAuthParams(
          accessToken: accessToken,
          refreshToken: refreshToken,
          data: authData,
        ),
      );
    } catch (_) {
      // Keep local subscription access even if auth cache persistence fails.
    }
  }

  Future<void> _completePurchaseIfNeeded(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;

    try {
      await _inAppPurchase.completePurchase(purchase);
    } catch (error) {
      _lastErrorMessage =
          'Failed to finalize the store transaction: ${_humanizeError(error)}';
    }
  }

  DateTime? _readTransactionDateUtc(PurchaseDetails purchase) {
    final rawDate = purchase.transactionDate?.trim() ?? '';
    if (rawDate.isEmpty) return null;

    final millis = int.tryParse(rawDate);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }

    return DateTime.tryParse(rawDate)?.toUtc();
  }

  List<ProductDetails> _sortProducts(List<ProductDetails> products) {
    final sorted = List<ProductDetails>.from(products);
    sorted.sort((a, b) {
      return _sortRankForProductId(a.id).compareTo(_sortRankForProductId(b.id));
    });
    return sorted;
  }

  int _sortRankForProductId(String productId) {
    switch (productId) {
      case monthlyProductId:
        return 0;
      case yearlyProductId:
        return 1;
      default:
        return 99;
    }
  }

  String _intervalForProductId(String productId) {
    return productId == yearlyProductId ? 'year' : 'month';
  }

  String _planNameForProductId(String productId) {
    return productId == yearlyProductId
        ? 'Yearly Subscription'
        : 'Monthly Subscription';
  }

  String _humanizeError(Object error) {
    if (error is SubscriptionException) {
      return error.message;
    }
    return error.toString();
  }

  void _emitEvent(SubscriptionPurchaseEvent event) {
    if (_isDisposed) return;
    _purchaseEventsController.add(event);
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

class SubscriptionPurchaseEvent {
  const SubscriptionPurchaseEvent._({
    required this.status,
    required this.message,
    this.productId,
  });

  final SubscriptionPurchaseStatus status;
  final String message;
  final String? productId;

  factory SubscriptionPurchaseEvent.pending({
    required String message,
    String? productId,
  }) {
    return SubscriptionPurchaseEvent._(
      status: SubscriptionPurchaseStatus.pending,
      message: message,
      productId: productId,
    );
  }

  factory SubscriptionPurchaseEvent.success({
    required String message,
    String? productId,
  }) {
    return SubscriptionPurchaseEvent._(
      status: SubscriptionPurchaseStatus.success,
      message: message,
      productId: productId,
    );
  }

  factory SubscriptionPurchaseEvent.error({
    required String message,
    String? productId,
  }) {
    return SubscriptionPurchaseEvent._(
      status: SubscriptionPurchaseStatus.error,
      message: message,
      productId: productId,
    );
  }

  factory SubscriptionPurchaseEvent.canceled({
    required String message,
    String? productId,
  }) {
    return SubscriptionPurchaseEvent._(
      status: SubscriptionPurchaseStatus.canceled,
      message: message,
      productId: productId,
    );
  }
}

enum SubscriptionPurchaseStatus { pending, success, error, canceled }

class SubscriptionException implements Exception {
  const SubscriptionException(this.message);

  final String message;

  @override
  String toString() => message;
}
