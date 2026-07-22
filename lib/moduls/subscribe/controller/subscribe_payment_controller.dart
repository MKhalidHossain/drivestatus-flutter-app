import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/helpers/subscription_access.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../../../core/services/app_pigeon/app_pigeon.dart';
import '../../profile/model/profile_data.dart';
import '../model/plan_model.dart';

class SubscribePaymentController extends ChangeNotifier {
  SubscribePaymentController({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  static const Map<String, _StoreSubscriptionConfig> _storeConfigs = {
    'month_subscription': _StoreSubscriptionConfig(
      productId: 'month_subscription',
      displayName: 'Monthly Subscription',
      interval: 'month',
      features: <String>[
        'Full access to driver status subscription features',
        'Ticket details and subscription-only ticket tools',
        'License upload and verification access',
        'Premium driver alerts and account access',
      ],
    ),
    'yearly_subscription': _StoreSubscriptionConfig(
      productId: 'yearly_subscription',
      displayName: 'Yearly Subscription',
      interval: 'year',
      features: <String>[
        'Full access to driver status subscription features',
        'Ticket details and subscription-only ticket tools',
        'License upload and verification access',
        'Premium driver alerts and account access',
      ],
    ),
  };

  final InAppPurchase _inAppPurchase;
  final List<PlanModel> _plans = <PlanModel>[];
  final Map<String, ProductDetails> _storeProductsById =
      <String, ProductDetails>{};

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  SnackbarNotifier? _snackbarNotifier;
  PlanModel? _currentPlan;
  PlanModel? _selectedPlan;
  bool _isLoadingPlans = false;
  bool _isSubmitting = false;
  bool _initialized = false;
  bool _storeAvailable = false;
  String? _storeMessage;

  List<PlanModel> get plans => List.unmodifiable(_plans);
  PlanModel? get currentPlan => _currentPlan;
  PlanModel? get selectedPlan => _selectedPlan;
  bool get isLoadingPlans => _isLoadingPlans;
  bool get isSubmitting => _isSubmitting;
  bool get hasPlans => _plans.isNotEmpty;
  bool get hasSelection => _selectedPlan != null;
  bool get isCurrentSelection =>
      _selectedPlan != null && _selectedPlan?.id == _currentPlan?.id;
  bool get supportsAppleStore => _supportsAppleStore();
  bool get isStoreAvailable => supportsAppleStore && _storeAvailable;
  String? get storeMessage => _storeMessage;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () {
        _purchaseSubscription = null;
      },
      onError: (_) {
        _setSubmitting(false);
        _snackbarNotifier?.notifyError(
          message: 'An error occurred while listening for App Store updates.',
        );
      },
    );
  }

  Future<void> loadPlans({SnackbarNotifier? snackbarNotifier}) async {
    if (snackbarNotifier != null) {
      _snackbarNotifier = snackbarNotifier;
    }

    _setLoadingPlans(true);
    _storeMessage = null;

    try {
      if (!supportsAppleStore) {
        _handleStoreUnavailable(
          'Apple subscriptions are available only on iPhone, iPad, and Mac.',
        );
        return;
      }

      _storeAvailable = await _inAppPurchase.isAvailable();
      if (!_storeAvailable) {
        _handleStoreUnavailable(
          'The App Store is unavailable right now. Try again in a moment.',
        );
        return;
      }

      final response = await _inAppPurchase.queryProductDetails(
        _storeConfigs.keys.toSet(),
      );

      if (response.error != null) {
        _handleStoreUnavailable(
          response.error!.message.isNotEmpty
              ? response.error!.message
              : 'Unable to load Apple subscription products.',
        );
        return;
      }

      _storeProductsById
        ..clear()
        ..addEntries(
          response.productDetails.map(
            (product) => MapEntry(product.id, product),
          ),
        );

      if (response.notFoundIDs.isNotEmpty) {
        _storeMessage =
            'Missing App Store products: ${response.notFoundIDs.join(', ')}.';
      }

      final fetchedPlans = _buildPlans(response.productDetails);
      _plans
        ..clear()
        ..addAll(fetchedPlans);

      _currentPlan = _resolveCurrentPlan(fetchedPlans);
      _selectedPlan = _resolveSelectedPlan(fetchedPlans, _currentPlan);
      notifyListeners();
    } catch (_) {
      _plans.clear();
      _currentPlan = null;
      _selectedPlan = null;
      _storeMessage = 'An error occurred while loading Apple subscriptions.';
      notifyListeners();
    } finally {
      _setLoadingPlans(false);
    }
  }

  void selectPlan(PlanModel plan) {
    if (plan.id == _currentPlan?.id) return;
    _selectedPlan = plan;
    notifyListeners();
  }

  Future<bool> submitSubscription({
    required SnackbarNotifier snackbarNotifier,
  }) async {
    _snackbarNotifier = snackbarNotifier;

    if (!supportsAppleStore) {
      snackbarNotifier.notifyError(
        message: 'Apple subscriptions are supported only on Apple devices.',
      );
      return false;
    }

    if (!isStoreAvailable) {
      snackbarNotifier.notifyError(
        message:
            _storeMessage ??
            'The App Store is unavailable. Refresh and try again.',
      );
      return false;
    }

    if (!hasSelection) {
      snackbarNotifier.notifyError(message: 'Please select a plan.');
      return false;
    }

    if (isCurrentSelection) {
      snackbarNotifier.notify(message: 'You are already on this plan.');
      return false;
    }

    final plan = _selectedPlan!;
    final product = _storeProductsById[plan.id];
    if (product == null) {
      snackbarNotifier.notifyError(
        message: 'This App Store product is not available yet.',
      );
      return false;
    }

    _setSubmitting(true);
    try {
      final launched = await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!launched) {
        _setSubmitting(false);
        snackbarNotifier.notifyError(
          message: 'Unable to open the App Store purchase sheet.',
        );
        return false;
      }
    } catch (_) {
      _setSubmitting(false);
      snackbarNotifier.notifyError(
        message: 'Unable to start the App Store purchase.',
      );
      return false;
    }

    return false;
  }

  Future<void> restorePurchases({
    required SnackbarNotifier snackbarNotifier,
  }) async {
    _snackbarNotifier = snackbarNotifier;

    if (!supportsAppleStore) {
      snackbarNotifier.notifyError(
        message: 'Apple subscriptions are supported only on Apple devices.',
      );
      return;
    }

    if (!isStoreAvailable) {
      snackbarNotifier.notifyError(
        message:
            _storeMessage ??
            'The App Store is unavailable. Refresh and try again.',
      );
      return;
    }

    snackbarNotifier.notify(
      message: 'Checking your App Store account for previous purchases.',
    );
    try {
      await _inAppPurchase.restorePurchases();
    } catch (_) {
      snackbarNotifier.notifyError(
        message: 'Unable to restore previous App Store purchases.',
      );
    }
  }

  Future<void> persistSubscription({
    required String subscriptionPlanId,
    required String planName,
    required String subscriptionInterval,
    required String subscriptionStartsAt,
    required String subscriptionEndsAt,
  }) async {
    _currentPlan = _selectedPlan;
    ProfileData.instance.updateSubscription(
      subscribed: true,
      planName: planName,
      subscriptionInterval: subscriptionInterval,
      subscriptionStartsAt: subscriptionStartsAt,
      subscriptionEndsAt: subscriptionEndsAt,
    );
    await _persistSubscriptionToCurrentAuth(
      subscribed: true,
      subscriptionPlanId: subscriptionPlanId,
      planName: planName,
      subscriptionInterval: subscriptionInterval,
      subscriptionStartsAt: subscriptionStartsAt,
      subscriptionEndsAt: subscriptionEndsAt,
    );
    notifyListeners();
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (!_storeConfigs.containsKey(purchaseDetails.productID)) {
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        continue;
      }

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          // Apple's payment sheet is being shown — do not complete the
          // transaction here; it hasn't been confirmed by the user yet.
          _setSubmitting(true);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliverPurchase(purchaseDetails);
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;
        case PurchaseStatus.error:
          _setSubmitting(false);
          _snackbarNotifier?.notifyError(
            message:
                purchaseDetails.error?.message ??
                'Unable to complete the App Store purchase.',
          );
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;
        case PurchaseStatus.canceled:
          _setSubmitting(false);
          _snackbarNotifier?.notify(message: 'Purchase canceled.');
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;
      }
    }
  }

  Future<void> _deliverPurchase(PurchaseDetails purchaseDetails) async {
    final config = _storeConfigs[purchaseDetails.productID];
    if (config == null) {
      _setSubmitting(false);
      return;
    }

    final startsAtUtc =
        _readTransactionDateUtc(purchaseDetails) ?? DateTime.now().toUtc();
    final endsAtUtc =
        SubscriptionAccess.estimateSubscriptionEndsAt(
          startsAtUtc: startsAtUtc,
          interval: config.interval,
        ) ??
        startsAtUtc;

    await persistSubscription(
      subscriptionPlanId: config.productId,
      planName: config.displayName,
      subscriptionInterval: config.interval,
      subscriptionStartsAt: startsAtUtc.toIso8601String(),
      subscriptionEndsAt: endsAtUtc.toIso8601String(),
    );

    _setSubmitting(false);
    await loadPlans(snackbarNotifier: _snackbarNotifier);
    _snackbarNotifier?.notify(
      message: purchaseDetails.status == PurchaseStatus.restored
          ? '${config.displayName} restored from the App Store.'
          : '${config.displayName} activated.',
    );
  }

  DateTime? _readTransactionDateUtc(PurchaseDetails purchaseDetails) {
    final rawDate = purchaseDetails.transactionDate?.trim() ?? '';
    if (rawDate.isEmpty) return null;

    final millis = int.tryParse(rawDate);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }

    return DateTime.tryParse(rawDate)?.toUtc();
  }

  List<PlanModel> _buildPlans(List<ProductDetails> productDetails) {
    final currentInterval = SubscriptionAccess.normalizeInterval(
      ProfileData.instance.subscriptionInterval,
    );
    final currentPlanName = ProfileData.instance.planName.trim().toLowerCase();
    final hasActiveSubscription = ProfileData.instance.subscribed;

    final plans = productDetails
        .map((product) {
          final config = _storeConfigs[product.id];
          if (config == null) {
            return null;
          }

          final isCurrent =
              hasActiveSubscription &&
              (currentInterval == config.interval ||
                  currentPlanName == config.displayName.toLowerCase());

          return PlanModel(
            id: product.id,
            name: config.displayName,
            price: product.rawPrice,
            currency: product.currencyCode,
            recurring: true,
            interval: config.interval,
            isCurrent: isCurrent,
            features: config.features,
          );
        })
        .whereType<PlanModel>()
        .toList();

    plans.sort(_planSortComparator);
    return plans;
  }

  void _handleStoreUnavailable(String message) {
    _storeAvailable = false;
    _plans.clear();
    _currentPlan = null;
    _selectedPlan = null;
    _storeMessage = message;
    notifyListeners();
  }

  PlanModel? _resolveCurrentPlan(List<PlanModel> plans) {
    for (final plan in plans) {
      if (plan.isCurrent) return plan;
    }
    return null;
  }

  PlanModel? _resolveSelectedPlan(List<PlanModel> plans, PlanModel? current) {
    if (plans.isEmpty) return null;
    for (final plan in plans) {
      if (plan.id != current?.id) return plan;
    }
    return current ?? plans.first;
  }

  bool _supportsAppleStore() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  void _setLoadingPlans(bool value) {
    if (_isLoadingPlans == value) return;
    _isLoadingPlans = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    if (_isSubmitting == value) return;
    _isSubmitting = value;
    notifyListeners();
  }

  Future<void> _persistSubscriptionToCurrentAuth({
    required bool subscribed,
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
      authData['subscribed'] = subscribed;
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
    } catch (_) {}
  }

  int _planSortComparator(PlanModel a, PlanModel b) {
    final rankA = _intervalRank(a.interval);
    final rankB = _intervalRank(b.interval);
    if (rankA != rankB) {
      return rankA.compareTo(rankB);
    }
    return a.price.compareTo(b.price);
  }

  int _intervalRank(String interval) {
    final normalized = interval.toLowerCase();
    if (normalized.startsWith('month')) return 0;
    if (normalized.startsWith('year')) return 1;
    return 2;
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}

class _StoreSubscriptionConfig {
  final String productId;
  final String displayName;
  final String interval;
  final List<String> features;

  const _StoreSubscriptionConfig({
    required this.productId,
    required this.displayName,
    required this.interval,
    required this.features,
  });
}
