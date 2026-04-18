import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../service/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const Color _background = Color(0xFFF6F8FC);
  static const Color _yearlyAccent = Color(0xFF0F766E);

  late final SubscriptionService _subscriptionService;

  StreamSubscription<SubscriptionPurchaseEvent>? _purchaseEventsSubscription;
  bool _isLoading = true;
  bool _isPurchasingMonthly = false;
  bool _isPurchasingYearly = false;
  bool _isSubscribed = false;
  String? _errorMessage;
  List<ProductDetails> _products = const <ProductDetails>[];

  final Map<String, List<String>> _planFeatures = const <String, List<String>>{
    SubscriptionService.monthlyProductId: <String>[
      'Unlimited driver status access',
      'Subscription-only ticket tools',
      'License tracking and alerts',
      'Coverage for individuals and families',
    ],
    SubscriptionService.yearlyProductId: <String>[
      'Unlimited driver status access',
      'Subscription-only ticket tools',
      'License tracking and alerts',
      'Best long-term value for families',
    ],
  };

  @override
  void initState() {
    super.initState();
    _subscriptionService = Get.find<SubscriptionService>();
    _purchaseEventsSubscription = _subscriptionService.purchaseEvents.listen(
      _handlePurchaseEvent,
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _subscriptionService.initialize();
      final products = await _subscriptionService.getAvailableProducts();
      final isSubscribed = await _subscriptionService.isUserSubscribed();

      if (!mounted) return;
      setState(() {
        _products = products;
        _isSubscribed = isSubscribed;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handlePurchaseEvent(SubscriptionPurchaseEvent event) {
    if (!mounted) return;

    if (event.productId == SubscriptionService.monthlyProductId) {
      _isPurchasingMonthly = event.status == SubscriptionPurchaseStatus.pending;
    } else if (event.productId == SubscriptionService.yearlyProductId) {
      _isPurchasingYearly = event.status == SubscriptionPurchaseStatus.pending;
    } else if (event.status != SubscriptionPurchaseStatus.pending) {
      _isPurchasingMonthly = false;
      _isPurchasingYearly = false;
    }

    setState(() {});

    final snackbarNotifier = SnackbarNotifier(context: context);
    switch (event.status) {
      case SubscriptionPurchaseStatus.pending:
        snackbarNotifier.notify(message: event.message);
        break;
      case SubscriptionPurchaseStatus.success:
        _isSubscribed = true;
        snackbarNotifier.notifySuccess(message: event.message);
        _showSuccessDialog();
        _loadProducts();
        break;
      case SubscriptionPurchaseStatus.error:
        snackbarNotifier.notifyError(message: event.message);
        break;
      case SubscriptionPurchaseStatus.canceled:
        snackbarNotifier.notify(message: event.message);
        break;
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.verified_rounded, color: Colors.green),
          title: const Text('Subscription Active'),
          content: const Text(
            'Your subscription is now active and premium features are ready to use.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  ProductDetails? _productForId(String productId) {
    for (final product in _products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  Future<void> _purchaseMonthly() async {
    try {
      await _subscriptionService.purchaseMonthlySubscription();
    } catch (_) {
      // User-facing errors are emitted through the purchase event stream.
    }
  }

  Future<void> _purchaseYearly() async {
    try {
      await _subscriptionService.purchaseYearlySubscription();
    } catch (_) {
      // User-facing errors are emitted through the purchase event stream.
    }
  }

  String _priceLabel(ProductDetails? product) {
    if (product == null) return 'Unavailable';
    return product.price;
  }

  String _periodLabel(String productId) {
    return productId == SubscriptionService.yearlyProductId
        ? 'per year'
        : 'per month';
  }

  String _ctaLabel(String productId) {
    if (_isSubscribed) return 'Subscribed';
    return productId == SubscriptionService.yearlyProductId
        ? 'Subscribe Now'
        : 'Subscribe Now';
  }

  @override
  void dispose() {
    _purchaseEventsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Subscriptions'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProducts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                'Drive Status Premium',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose from affordable monthly or annual subscription options designed for individuals and families.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF475467),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              if (_isSubscribed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FFF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFB7F0D3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF15803D),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your account currently has an active subscription.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF166534),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isSubscribed) const SizedBox(height: 20),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                _ErrorState(message: _errorMessage!, onRetry: _loadProducts)
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = <Widget>[
                      _SubscriptionPlanCard(
                        title: 'Monthly',
                        priceLabel: _priceLabel(
                          _productForId(SubscriptionService.monthlyProductId),
                        ),
                        billingLabel: _periodLabel(
                          SubscriptionService.monthlyProductId,
                        ),
                        features:
                            _planFeatures[SubscriptionService
                                .monthlyProductId]!,
                        onPressed: _isSubscribed ? null : _purchaseMonthly,
                        isLoading: _isPurchasingMonthly,
                        buttonLabel: _ctaLabel(
                          SubscriptionService.monthlyProductId,
                        ),
                      ),
                      _SubscriptionPlanCard(
                        title: 'Yearly',
                        priceLabel: _priceLabel(
                          _productForId(SubscriptionService.yearlyProductId),
                        ),
                        billingLabel: _periodLabel(
                          SubscriptionService.yearlyProductId,
                        ),
                        features:
                            _planFeatures[SubscriptionService.yearlyProductId]!,
                        onPressed: _isSubscribed ? null : _purchaseYearly,
                        isLoading: _isPurchasingYearly,
                        buttonLabel: _ctaLabel(
                          SubscriptionService.yearlyProductId,
                        ),
                        badgeText: 'Most Popular',
                        accentColor: _yearlyAccent,
                      ),
                    ];

                    if (constraints.maxWidth >= 760) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 20),
                          Expanded(child: cards[1]),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        cards[0],
                        const SizedBox(height: 16),
                        cards[1],
                      ],
                    );
                  },
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.profile);
                },
                icon: const Icon(Icons.person_outline),
                label: const Text('Back to Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionPlanCard extends StatelessWidget {
  const _SubscriptionPlanCard({
    required this.title,
    required this.priceLabel,
    required this.billingLabel,
    required this.features,
    required this.onPressed,
    required this.isLoading,
    required this.buttonLabel,
    this.badgeText,
    this.accentColor = const Color(0xFF155EEF),
  });

  final String title;
  final String priceLabel;
  final String billingLabel;
  final List<String> features;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String buttonLabel;
  final String? badgeText;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = badgeText == null
        ? const Color(0xFFDDE3EC)
        : accentColor.withValues(alpha: 0.24);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeText!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (badgeText != null) const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodyLarge,
              children: [
                TextSpan(
                  text: priceLabel,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                TextSpan(
                  text: '  $billingLabel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: accentColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF344054),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3C7C7)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 34),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFB42318),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
