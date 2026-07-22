import 'dart:async';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../../../core/constants/api_endpoints.dart';
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
  static const Map<String, _FallbackSubscriptionPlan> _fallbackPlansByProductId =
      <String, _FallbackSubscriptionPlan>{
        monthlyProductId: _FallbackSubscriptionPlan(
          name: 'Drive Status Premium Monthly',
          price: 9.99,
          currency: 'USD',
          interval: 'month',
          features: <String>[
            'Unlimited driver status access',
            'Subscription-only ticket tools',
            'License tracking and alerts',
            'Coverage for individuals and families',
          ],
        ),
        yearlyProductId: _FallbackSubscriptionPlan(
          name: 'Drive Status Premium Yearly',
          price: 89.99,
          currency: 'USD',
          interval: 'year',
          features: <String>[
            'Unlimited driver status access',
            'Subscription-only ticket tools',
            'License tracking and alerts',
            'Best long-term value for families',
          ],
        ),
      };

  final InAppPurchase _inAppPurchase;
  final StreamController<SubscriptionPurchaseEvent> _purchaseEventsController =
      StreamController<SubscriptionPurchaseEvent>.broadcast();
  final Map<String, ProductDetails> _productsById = <String, ProductDetails>{};
  final Map<String, StoreSubscriptionPlanInfo> _backendPlansByProductId =
      <String, StoreSubscriptionPlanInfo>{};
  final Map<String, PurchaseDetails> _activePurchasesById =
      <String, PurchaseDetails>{};

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _storeAvailable = false;
  bool _storeProductsEndpointUnavailable = false;
  bool _storeConfirmEndpointUnavailable = false;
  String? _lastErrorMessage;

  Stream<SubscriptionPurchaseEvent> get purchaseEvents =>
      _purchaseEventsController.stream;

  bool get isInitialized => _isInitialized;
  bool get isStoreAvailable => _storeAvailable;
  String? get lastErrorMessage => _lastErrorMessage;

  StoreSubscriptionPlanInfo? backendPlanForProduct(String productId) {
    return _backendPlansByProductId[productId] ?? _fallbackPlanForProduct(productId);
  }

  String priceLabelForProduct(String productId) {
    final product = _productsById[productId];
    if (product != null) {
      return product.price;
    }
    final backendPlan = _backendPlansByProductId[productId];
    if (backendPlan != null) {
      return backendPlan.formattedPrice;
    }
    return _fallbackPlanForProduct(productId)?.formattedPrice ?? 'Unavailable';
  }

  String displayTitleForProduct(String productId) {
    return _metadataForProduct(productId).displayTitle;
  }

  String descriptionForProduct(String productId) {
    final description = _metadataForProduct(productId).description.trim();
    if (description.isNotEmpty) {
      return description;
    }

    return productId == yearlyProductId
        ? 'Best value billed once yearly through Apple.'
        : 'Available through your App Store account.';
  }

  bool isCurrentPlanProduct(String productId) {
    if (!SubscriptionAccess.isCurrentSubscriptionActive()) {
      return false;
    }

    if (_activePurchasesById.containsKey(productId)) {
      return true;
    }

    final normalizedCurrentInterval = SubscriptionAccess.normalizeInterval(
      ProfileData.instance.subscriptionInterval,
    );
    final metadata = _metadataForProduct(productId);
    return normalizedCurrentInterval.isNotEmpty &&
        normalizedCurrentInterval == metadata.interval;
  }

  String ctaLabelForProduct(String productId) {
    if (isCurrentPlanProduct(productId)) {
      return 'Current Plan';
    }

    if (SubscriptionAccess.isCurrentSubscriptionActive()) {
      return 'Change Plan';
    }

    return 'Subscribe Now';
  }

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
      await _loadBackendPlans();
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
    await _loadBackendPlans();
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

      printStoreProductDebugInfo(response.productDetails);

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

  /// Attempts to restore previously purchased subscriptions for the current
  /// store account.
  Future<void> restorePurchases() async {
    if (_isDisposed) return;
    if (!_isInitialized) {
      await initialize();
    }

    if (!_storeAvailable) {
      final message = 'The store is currently unavailable. Please try again later.';
      _lastErrorMessage = message;
      throw SubscriptionException(message);
    }

    _emitEvent(
      SubscriptionPurchaseEvent.pending(
        message: 'Checking your store account for previous subscriptions...',
      ),
    );

    try {
      if (_isAndroid) {
        await _refreshPastPurchases();
        final restored = await isUserSubscribed();
        if (!restored) {
          throw const SubscriptionException(
            'No previous subscriptions were found for this account.',
          );
        }
        _emitEvent(
          SubscriptionPurchaseEvent.success(
            message: 'Previous subscriptions restored successfully.',
          ),
        );
        return;
      }

      await _inAppPurchase.restorePurchases();
    } catch (error) {
      final message = 'Unable to restore purchases: ${_humanizeError(error)}';
      _lastErrorMessage = message;
      _emitEvent(SubscriptionPurchaseEvent.error(message: message));
      rethrow;
    }
  }

  bool hasStoreProduct(String productId) => _productsById.containsKey(productId);

  /// Prints the store fields returned by Apple or Google for each loaded
  /// subscription product. This is useful for checking exactly what metadata
  /// the store exposes to the app at runtime.
  void printStoreProductDebugInfo([Iterable<ProductDetails>? products]) {
    final entries = (products ?? _productsById.values).toList();
    if (entries.isEmpty) {
      debugPrint('No store subscription products available to print.');
      return;
    }

    for (final product in entries) {
      debugPrint('---------- Store Subscription Info ----------');
      debugPrint('Product ID: ${product.id}');
      debugPrint('Title: ${product.title}');
      debugPrint('Description: ${product.description}');
      debugPrint('Price: ${product.price}');
      debugPrint('Raw Price: ${product.rawPrice}');
      debugPrint('Currency Code: ${product.currencyCode}');
      debugPrint('Currency Symbol: ${product.currencySymbol}');

      if (product is AppStoreProductDetails) {
        final skProduct = product.skProduct;
        debugPrint('Platform: Apple StoreKit');
        debugPrint(
          'Subscription Group Identifier: '
          '${skProduct.subscriptionGroupIdentifier ?? 'N/A'}',
        );
        debugPrint(
          'Subscription Period: '
          '${_formatAppleSubscriptionPeriod(skProduct.subscriptionPeriod)}',
        );
        debugPrint(
          'Introductory Offer: '
          '${_formatAppleDiscount(skProduct.introductoryPrice)}',
        );
        debugPrint('Promotional Offers Count: ${skProduct.discounts.length}');
        for (var index = 0; index < skProduct.discounts.length; index++) {
          final discount = skProduct.discounts[index];
          debugPrint(
            'Promotional Offer ${index + 1}: '
            '${_formatAppleDiscount(discount)}',
          );
        }
        debugPrint(
          'Storefront Country Code: ${skProduct.priceLocale.countryCode}',
        );
      } else if (product is AppStoreProduct2Details) {
        debugPrint('Platform: Apple StoreKit 2');
      } else {
        debugPrint('Platform: ${defaultTargetPlatform.name}');
      }

      debugPrint('--------------------------------------------');
    }
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
          // Apple's payment sheet is being shown to the user — no action needed.
          // Do NOT call completePurchase on a pending transaction; doing so would
          // finish the transaction before the user has confirmed payment.
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _finalizeSuccessfulPurchase(purchaseDetails);
          await _completePurchaseIfNeeded(purchaseDetails);
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
          await _completePurchaseIfNeeded(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          _emitEvent(
            SubscriptionPurchaseEvent.canceled(
              productId: purchaseDetails.productID,
              message: 'Purchase canceled.',
            ),
          );
          await _completePurchaseIfNeeded(purchaseDetails);
          break;
      }
    }
  }

  Future<void> _finalizeSuccessfulPurchase(PurchaseDetails purchase) async {
    try {
      // Production apps should verify receipts/purchase tokens on a secure
      // backend before granting access. This sample grants access after the
      // store reports a successful or restored transaction.
      _rememberPurchase(purchase);
      final metadata = await _persistSubscription(purchase);

      final action = purchase.status == PurchaseStatus.restored
          ? 'restored'
          : 'activated';
      final message = '${metadata.displayTitle} subscription $action successfully.';

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

  Future<StoreSubscriptionMetadata> _persistSubscription(
    PurchaseDetails purchase,
  ) async {
    final metadata = _metadataForProduct(purchase.productID);
    final transactionId = _resolveTransactionId(purchase);
    final startsAt =
        _readTransactionDateUtc(purchase) ?? DateTime.now().toUtc();
    final endsAt =
        SubscriptionAccess.estimateSubscriptionEndsAt(
          startsAtUtc: startsAt,
          interval: metadata.interval,
        ) ??
        startsAt;

    ProfileData.instance.updateSubscription(
      subscribed: true,
      planName: metadata.planName,
      subscriptionInterval: metadata.interval,
      subscriptionStartsAt: startsAt.toIso8601String(),
      subscriptionEndsAt: endsAt.toIso8601String(),
    );

    final backendSnapshot = await _confirmStoreSubscriptionWithBackend(
      purchase: purchase,
      transactionId: transactionId,
      startsAt: startsAt,
      metadata: metadata,
    );

    if (backendSnapshot != null) {
      _applyBackendSubscriptionSnapshot(backendSnapshot, metadata: metadata);
      return metadata;
    }

    await _persistSubscriptionToCurrentAuth(
      subscriptionPlanId: metadata.planId,
      planName: metadata.planName,
      subscriptionInterval: metadata.interval,
      subscriptionStartsAt: startsAt.toIso8601String(),
      subscriptionEndsAt: endsAt.toIso8601String(),
      metadata: metadata,
    );

    return metadata;
  }

  Future<void> _loadBackendPlans() async {
    if (_storeProductsEndpointUnavailable) return;

    try {
      final appPigeon = Get.find<AppPigeon>();
      final response = await appPigeon.get(
        ApiEndpoints.storeSubscriptionProducts,
      );
      if (_responseHasMissingStoreEndpoint(response)) {
        _storeProductsEndpointUnavailable = true;
        return;
      }
      final payload = response.data;
      final rawPlans = payload is Map<String, dynamic> ? payload['data'] : null;
      if (rawPlans is! List) return;

      _backendPlansByProductId
        ..clear()
        ..addEntries(
          rawPlans.whereType<Map>().map((rawPlan) {
            final plan = StoreSubscriptionPlanInfo.fromJson(
              Map<String, dynamic>.from(rawPlan),
            );
            return MapEntry(plan.storeProductId, plan);
          }),
        );
    } catch (error) {
      if (_isMissingStoreEndpointError(error)) {
        _storeProductsEndpointUnavailable = true;
      }
      // Keep the purchase flow functional even if plan metadata sync fails.
    }
  }

  Future<Map<String, dynamic>?> _confirmStoreSubscriptionWithBackend({
    required PurchaseDetails purchase,
    required String transactionId,
    required DateTime startsAt,
    required StoreSubscriptionMetadata metadata,
  }) async {
    if (_storeConfirmEndpointUnavailable) {
      return null;
    }

    try {
      final appPigeon = Get.find<AppPigeon>();
      dio.Response<dynamic> response;
      try {
        response = await appPigeon.post(
          ApiEndpoints.confirmStoreSubscription,
          options: dio.Options(
            validateStatus: _allowsMissingStoreEndpointStatus,
          ),
          data: _buildStoreConfirmationPayload(
            purchase: purchase,
            transactionId: transactionId,
            startsAt: startsAt,
            metadata: metadata,
            includeMetadata: true,
          ),
        );
      } catch (error) {
        if (!_shouldRetryStoreConfirmationWithoutMetadata(error)) {
          rethrow;
        }

        response = await appPigeon.post(
          ApiEndpoints.confirmStoreSubscription,
          options: dio.Options(
            validateStatus: _allowsMissingStoreEndpointStatus,
          ),
          data: _buildStoreConfirmationPayload(
            purchase: purchase,
            transactionId: transactionId,
            startsAt: startsAt,
            metadata: metadata,
            includeMetadata: false,
          ),
        );
      }
      if (_responseHasMissingStoreEndpoint(response)) {
        _storeConfirmEndpointUnavailable = true;
        return null;
      }

      final payload = response.data;
      if (payload is Map<String, dynamic> && payload['data'] is Map) {
        return Map<String, dynamic>.from(payload['data'] as Map);
      }
    } catch (error) {
      if (_isMissingStoreEndpointError(error)) {
        _storeConfirmEndpointUnavailable = true;
        return null;
      }
      throw SubscriptionException(
        'Purchase completed in the store, but backend confirmation failed: ${_humanizeError(error)}',
      );
    }
    return null;
  }

  Map<String, dynamic> _buildStoreConfirmationPayload({
    required PurchaseDetails purchase,
    required String transactionId,
    required DateTime startsAt,
    required StoreSubscriptionMetadata metadata,
    required bool includeMetadata,
  }) {
    final payload = <String, dynamic>{
      'productId': purchase.productID,
      'transactionId': transactionId,
      'purchaseDate': startsAt.toIso8601String(),
      'source': _isAndroid ? 'android' : 'ios',
      'localVerificationData': purchase.verificationData.localVerificationData,
      'serverVerificationData':
          purchase.verificationData.serverVerificationData,
      'verificationSource': purchase.verificationData.source,
    };

    if (!includeMetadata) {
      return payload;
    }

    payload.addAll(<String, dynamic>{
      'planId': metadata.planId,
      'planName': metadata.planName,
      'productTitle': metadata.displayTitle,
      'productDescription': metadata.description,
      'formattedPrice': metadata.priceLabel,
      'price': metadata.rawPrice,
      'currencyCode': metadata.currencyCode,
      'currencySymbol': metadata.currencySymbol,
      'subscriptionInterval': metadata.interval,
      'subscriptionGroupIdentifier': metadata.subscriptionGroupIdentifier,
      'storefrontCountryCode': metadata.storefrontCountryCode,
      'storeProduct': metadata.toJson(),
    });

    return payload;
  }

  void _applyBackendSubscriptionSnapshot(
    Map<String, dynamic> data, {
    StoreSubscriptionMetadata? metadata,
  }) {
    final subscribed = _readBool(data['subscribed']);
    final planId = _readString(data['planId']);
    final planName = _readString(data['planName']);
    final subscriptionInterval = _readString(data['subscriptionInterval']);
    final subscriptionStartsAt = _readString(data['subscriptionStartsAt']);
    final subscriptionEndsAt = _readString(data['subscriptionEndsAt']);

    ProfileData.instance.updateSubscription(
      subscribed: subscribed,
      planName: planName,
      subscriptionInterval: subscriptionInterval,
      subscriptionStartsAt: subscriptionStartsAt,
      subscriptionEndsAt: subscriptionEndsAt,
    );

    _persistSubscriptionToCurrentAuth(
      subscriptionPlanId: planId,
      planName: planName,
      subscriptionInterval: subscriptionInterval,
      subscriptionStartsAt: subscriptionStartsAt,
      subscriptionEndsAt: subscriptionEndsAt,
      metadata: metadata,
    );
  }

  Future<void> _persistSubscriptionToCurrentAuth({
    required String subscriptionPlanId,
    required String planName,
    required String subscriptionInterval,
    required String subscriptionStartsAt,
    required String subscriptionEndsAt,
    StoreSubscriptionMetadata? metadata,
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
      if (metadata != null) {
        authData['storeProduct'] = metadata.toJson();
        authData['storeProductId'] = metadata.productId;
        authData['storeProductTitle'] = metadata.displayTitle;
        authData['storeProductDescription'] = metadata.description;
        authData['storeFormattedPrice'] = metadata.priceLabel;
        authData['storeRawPrice'] = metadata.rawPrice;
        authData['storeCurrencyCode'] = metadata.currencyCode;
        authData['storeCurrencySymbol'] = metadata.currencySymbol;
        authData['storeSubscriptionGroupIdentifier'] =
            metadata.subscriptionGroupIdentifier;
        authData['storefrontCountryCode'] = metadata.storefrontCountryCode;
      }

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

  String _resolveTransactionId(PurchaseDetails purchase) {
    final purchaseId = purchase.purchaseID?.trim() ?? '';
    if (purchaseId.isNotEmpty) {
      return purchaseId;
    }
    final transactionDate = purchase.transactionDate?.trim() ?? '';
    if (transactionDate.isNotEmpty) {
      return '${purchase.productID}_$transactionDate';
    }
    return '${purchase.productID}_${DateTime.now().toUtc().millisecondsSinceEpoch}';
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
    return backendPlanForProduct(productId)?.name ??
        (productId == yearlyProductId
            ? 'Drive Status Premium Yearly'
            : 'Drive Status Premium Monthly');
  }

  StoreSubscriptionMetadata _metadataForProduct(String productId) {
    final product = _productsById[productId];
    final backendPlan = backendPlanForProduct(productId);
    final interval = _resolveIntervalForProduct(
      productId: productId,
      product: product,
      backendPlan: backendPlan,
    );
    final fallbackDisplayTitle = interval == 'year' ? 'Yearly' : 'Monthly';
    final rawTitle = product?.title.trim() ?? '';
    final displayTitle =
        rawTitle.isNotEmpty &&
            !_looksLikeRawProductIdentifier(rawTitle, productId)
        ? rawTitle
        : fallbackDisplayTitle;

    return StoreSubscriptionMetadata(
      planId: backendPlan?.planId.isNotEmpty == true
          ? backendPlan!.planId
          : productId,
      productId: productId,
      planName: _planNameForProductId(productId),
      displayTitle: displayTitle,
      description: product?.description.trim() ?? '',
      priceLabel: product?.price ?? backendPlan?.formattedPrice ?? 'Unavailable',
      rawPrice: product?.rawPrice ?? backendPlan?.price ?? 0,
      currencyCode: product?.currencyCode ?? backendPlan?.currency ?? 'USD',
      currencySymbol: product?.currencySymbol ?? '',
      interval: interval,
      subscriptionGroupIdentifier: _subscriptionGroupIdentifierForProduct(
        product,
      ),
      storefrontCountryCode: _storefrontCountryCodeForProduct(product),
    );
  }

  String _resolveIntervalForProduct({
    required String productId,
    required ProductDetails? product,
    required StoreSubscriptionPlanInfo? backendPlan,
  }) {
    if (product is AppStoreProductDetails) {
      final period = product.skProduct.subscriptionPeriod;
      final unit = period?.unit;
      if (unit == SKSubscriptionPeriodUnit.year) {
        return 'year';
      }
      if (unit == SKSubscriptionPeriodUnit.month) {
        return 'month';
      }
    }

    final backendInterval = SubscriptionAccess.normalizeInterval(
      backendPlan?.interval ?? '',
    );
    if (backendInterval == 'year' || backendInterval == 'month') {
      return backendInterval;
    }

    return _intervalForProductId(productId);
  }

  String? _subscriptionGroupIdentifierForProduct(ProductDetails? product) {
    if (product is AppStoreProductDetails) {
      return product.skProduct.subscriptionGroupIdentifier?.trim();
    }
    return null;
  }

  String _storefrontCountryCodeForProduct(ProductDetails? product) {
    if (product is AppStoreProductDetails) {
      return product.skProduct.priceLocale.countryCode.trim();
    }
    return '';
  }

  bool _looksLikeRawProductIdentifier(String title, String productId) {
    final normalizedTitle = title.trim().toLowerCase();
    final normalizedProductId = productId.trim().toLowerCase();
    return normalizedTitle == normalizedProductId || normalizedTitle.contains('_');
  }

  StoreSubscriptionPlanInfo? _fallbackPlanForProduct(String productId) {
    final fallback = _fallbackPlansByProductId[productId];
    if (fallback == null) {
      return null;
    }

    return StoreSubscriptionPlanInfo(
      planId: productId,
      name: fallback.name,
      price: fallback.price,
      currency: fallback.currency,
      interval: fallback.interval,
      storeProductId: productId,
      features: fallback.features,
    );
  }

  bool _isMissingStoreEndpointError(Object error) {
    if (error is! dio.DioException) {
      return false;
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != 400 && statusCode != 404) {
      return false;
    }

    final payload = error.response?.data;
    if (payload is Map) {
      final message = payload['message']?.toString().trim().toLowerCase() ?? '';
      return message.contains('api not found');
    }

    return false;
  }

  bool _shouldRetryStoreConfirmationWithoutMetadata(Object error) {
    if (error is! dio.DioException) {
      return false;
    }

    final statusCode = error.response?.statusCode;
    return statusCode == 400 || statusCode == 422;
  }

  bool _allowsMissingStoreEndpointStatus(int? statusCode) {
    if (statusCode == null) {
      return false;
    }
    return statusCode >= 200 && statusCode < 300 || statusCode == 400 || statusCode == 404;
  }

  bool _responseHasMissingStoreEndpoint(dio.Response<dynamic> response) {
    final statusCode = response.statusCode;
    if (statusCode != 400 && statusCode != 404) {
      return false;
    }

    final payload = response.data;
    if (payload is Map) {
      final message = payload['message']?.toString().trim().toLowerCase() ?? '';
      return message.contains('api not found');
    }

    return false;
  }

  String _humanizeError(Object error) {
    if (error is SubscriptionException) {
      return error.message;
    }
    return error.toString();
  }

  bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  String _readString(dynamic value) => value?.toString().trim() ?? '';

  String _formatAppleSubscriptionPeriod(
    SKProductSubscriptionPeriodWrapper? period,
  ) {
    if (period == null) {
      return 'N/A';
    }
    return '${period.numberOfUnits} ${period.unit.name}';
  }

  String _formatAppleDiscount(SKProductDiscountWrapper? discount) {
    if (discount == null) {
      return 'N/A';
    }

    return 'price=${discount.priceLocale.currencySymbol}${discount.price}, '
        'periods=${discount.numberOfPeriods}, '
        'paymentMode=${discount.paymentMode.name}, '
        'subscriptionPeriod='
        '${_formatAppleSubscriptionPeriod(discount.subscriptionPeriod)}, '
        'identifier=${discount.identifier ?? 'N/A'}, '
        'type=${discount.type.name}';
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

class StoreSubscriptionMetadata {
  const StoreSubscriptionMetadata({
    required this.planId,
    required this.productId,
    required this.planName,
    required this.displayTitle,
    required this.description,
    required this.priceLabel,
    required this.rawPrice,
    required this.currencyCode,
    required this.currencySymbol,
    required this.interval,
    required this.subscriptionGroupIdentifier,
    required this.storefrontCountryCode,
  });

  final String planId;
  final String productId;
  final String planName;
  final String displayTitle;
  final String description;
  final String priceLabel;
  final double rawPrice;
  final String currencyCode;
  final String currencySymbol;
  final String interval;
  final String? subscriptionGroupIdentifier;
  final String storefrontCountryCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'planId': planId,
      'productId': productId,
      'planName': planName,
      'displayTitle': displayTitle,
      'description': description,
      'priceLabel': priceLabel,
      'rawPrice': rawPrice,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'interval': interval,
      'subscriptionGroupIdentifier': subscriptionGroupIdentifier,
      'storefrontCountryCode': storefrontCountryCode,
    };
  }
}

class StoreSubscriptionPlanInfo {
  const StoreSubscriptionPlanInfo({
    required this.planId,
    required this.name,
    required this.price,
    required this.currency,
    required this.interval,
    required this.storeProductId,
    required this.features,
  });

  final String planId;
  final String name;
  final double price;
  final String currency;
  final String interval;
  final String storeProductId;
  final List<String> features;

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  factory StoreSubscriptionPlanInfo.fromJson(Map<String, dynamic> json) {
    final featuresJson = json['features'];
    return StoreSubscriptionPlanInfo(
      planId: json['planId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      interval: json['interval']?.toString() ?? 'month',
      storeProductId: json['storeProductId']?.toString() ?? '',
      features: featuresJson is List
          ? featuresJson.map((item) => item.toString()).toList()
          : const <String>[],
    );
  }
}

class _FallbackSubscriptionPlan {
  const _FallbackSubscriptionPlan({
    required this.name,
    required this.price,
    required this.currency,
    required this.interval,
    required this.features,
  });

  final String name;
  final double price;
  final String currency;
  final String interval;
  final List<String> features;
}

class SubscriptionException implements Exception {
  const SubscriptionException(this.message);

  final String message;

  @override
  String toString() => message;
}
