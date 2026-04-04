import 'package:flutter/material.dart';
import '../../../../core/helpers/subscription_access.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../../profile/model/profile_data.dart';
import '../../model/plan_model.dart';
import '../../controller/subscribe_payment_controller.dart';

enum _BillingCycle { monthly, yearly }

extension _BillingCycleX on _BillingCycle {
  String get interval => this == _BillingCycle.monthly ? 'month' : 'year';

  String get label => this == _BillingCycle.monthly ? 'Monthly' : 'Yearly';
}

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  static const Color _background = Color(0xFFF5F7FB);
  static const Color _primaryBlue = Color(0xFF1F6FEB);
  static const Color _title = Color(0xFF101828);
  static const Color _muted = Color(0xFF667085);
  static const Color _divider = Color(0xFFD0D5DD);
  static const Color _surface = Colors.white;
  static const Color _successBg = Color(0xFFDDF6E5);
  static const Color _successText = Color(0xFF166534);
  static const Color _popularBg = Color(0xFFFFE9CC);
  static const Color _popularText = Color(0xFFB45309);

  late final SnackbarNotifier _snackbarNotifier;
  late final SubscribePaymentController _controller;
  bool _initialized = false;
  String? _forcedInterval;

  @override
  void initState() {
    super.initState();
    _controller = SubscribePaymentController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _snackbarNotifier = SnackbarNotifier(context: context);
      _syncSubscriptionSnapshot();
      _controller.init();
      _controller.loadPlans(snackbarNotifier: _snackbarNotifier);
    }
  }

  Future<void> _syncSubscriptionSnapshot() async {
    await SubscriptionAccess.syncFromCurrentAuth();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _currencySymbol(String currency) {
    final normalized = currency.toUpperCase();
    if (normalized == 'USD') return '\$';
    return '$normalized ';
  }

  String _normalizeInterval(String interval) {
    return SubscriptionAccess.normalizeInterval(interval);
  }

  _BillingCycle? _toCycle(String interval) {
    final normalized = _normalizeInterval(interval);
    if (normalized == 'month') return _BillingCycle.monthly;
    if (normalized == 'year') return _BillingCycle.yearly;
    return null;
  }

  List<_BillingCycle> _availableCycles(List<PlanModel> plans) {
    final cycles = <_BillingCycle>[];
    for (final plan in plans) {
      final cycle = _toCycle(plan.interval);
      if (cycle != null && !cycles.contains(cycle)) {
        cycles.add(cycle);
      }
    }
    if (cycles.isEmpty) {
      cycles.add(_BillingCycle.monthly);
    }
    return cycles;
  }

  String _activeInterval(List<PlanModel> plans) {
    final available = _availableCycles(plans);
    final desiredInterval =
        _forcedInterval ??
        _controller.selectedPlan?.interval ??
        _controller.currentPlan?.interval ??
        available.first.interval;
    final normalized = _normalizeInterval(desiredInterval);
    final exists = available.any((cycle) => cycle.interval == normalized);
    if (exists) return normalized;
    return available.first.interval;
  }

  List<PlanModel> _plansForInterval(List<PlanModel> plans, String interval) {
    final scoped = plans
        .where((plan) => _normalizeInterval(plan.interval) == interval)
        .toList();
    if (scoped.isEmpty) {
      return plans;
    }
    return scoped;
  }

  String _intervalLabel(String interval) {
    final value = _normalizeInterval(interval);
    if (value == 'year') return 'year';
    if (value == 'month') return 'month';
    return value;
  }

  String _cycleLabel(String interval) {
    final value = _normalizeInterval(interval);
    if (value == 'year') return 'Yearly';
    if (value == 'month') return 'Monthly';
    return value.toUpperCase();
  }

  bool _isLockedBySubscription({
    required PlanModel plan,
    required bool hasActiveSubscription,
  }) {
    if (!hasActiveSubscription) return false;
    return plan.price > 0;
  }

  String _yearlyEquivalentText(PlanModel plan) {
    if (_normalizeInterval(plan.interval) != 'year' || plan.price <= 0) {
      return '';
    }
    final monthlyEquivalent = plan.price / 12;
    return 'Equivalent to ${_currencySymbol(plan.currency)}${monthlyEquivalent.toStringAsFixed(2)}/month';
  }

  void _onCycleSelected(_BillingCycle cycle) {
    setState(() {
      _forcedInterval = cycle.interval;
    });
    final currentId = _controller.currentPlan?.id;
    final candidates = _plansForInterval(_controller.plans, cycle.interval);
    final preferred = candidates.firstWhere(
      (plan) => plan.id != currentId && plan.price > 0,
      orElse: () => candidates.first,
    );
    _controller.selectPlan(preferred);
  }

  bool _isPopularPlan(PlanModel plan, List<PlanModel> plans) {
    final name = plan.name.toLowerCase();
    if (name.contains('pro')) return true;
    final maxPrice = plans.isNotEmpty
        ? plans.map((item) => item.price).reduce((a, b) => a > b ? a : b)
        : plan.price;
    return plan.price == maxPrice && plan.price > 0;
  }

  void _selectPlan(PlanModel plan) {
    final hasActiveSubscription =
        SubscriptionAccess.isCurrentSubscriptionActive();
    final isLocked = _isLockedBySubscription(
      plan: plan,
      hasActiveSubscription: hasActiveSubscription,
    );
    if (isLocked) {
      final blockMessage = SubscriptionAccess.activeSubscriptionBlockMessage();
      if (blockMessage != null) {
        _snackbarNotifier.notify(message: blockMessage);
      }
      return;
    }
    _controller.selectPlan(plan);
    final cycle = _toCycle(plan.interval);
    if (cycle != null) {
      setState(() {
        _forcedInterval = cycle.interval;
      });
    }
  }

  Future<void> _submitSubscription() async {
    final success = await _controller.submitSubscription(
      snackbarNotifier: _snackbarNotifier,
    );
    if (mounted && success) _showSuccessDialog();
  }

  void _showSuccessDialog() {
    final plan = _controller.selectedPlan;
    if (plan == null) return;
    final priceText =
        '${_currencySymbol(plan.currency)}${plan.price.toStringAsFixed(2)}';
    final cycle = _cycleLabel(plan.interval).toLowerCase();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Subscription Active'),
          content: Text(
            'You are now subscribed to ${plan.name} ($priceText / $cycle).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveSubscriptionBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8DBFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, color: _primaryBlue, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF1849A9),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFDCE8FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: _primaryBlue, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Color(0xFF1D2939),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleSelector({
    required List<_BillingCycle> availableCycles,
    required String activeInterval,
  }) {
    if (availableCycles.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          for (final cycle in availableCycles)
            Expanded(
              child: GestureDetector(
                onTap: () => _onCycleSelected(cycle),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: cycle.interval == activeInterval
                        ? _primaryBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cycle.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cycle.interval == activeInterval
                          ? Colors.white
                          : _title,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required List<PlanModel> scopedPlans,
    required PlanModel plan,
    required bool isCurrent,
    required bool isSelected,
    required bool isLockedForSubscription,
  }) {
    final isFree = plan.price == 0;
    final priceText = isFree
        ? 'Free'
        : '${_currencySymbol(plan.currency)}${plan.price.toStringAsFixed(2)}';
    final interval = _intervalLabel(plan.interval);
    final cycleLabel = _cycleLabel(plan.interval);
    final yearlyEquivalent = _yearlyEquivalentText(plan);
    final features = plan.features.isNotEmpty
        ? plan.features
        : <String>[
            'Upgrade anytime for full access',
            'Access to selected API exams',
            'Full-length mock exams',
            'Timed & full simulation modes',
          ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected || isCurrent
              ? _primaryBlue
              : const Color(0xFFD0D5DD),
          width: isSelected || isCurrent ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F101828),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: _primaryBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.name,
                            style: const TextStyle(
                              color: _title,
                              fontSize: 30 / 1.7,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9EFFD),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            cycleLabel,
                            style: const TextStyle(
                              color: _primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_isPopularPlan(plan, scopedPlans) && !isCurrent)
                          const SizedBox(width: 8),
                        if (_isPopularPlan(plan, scopedPlans) && !isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _popularBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Popular',
                              style: TextStyle(
                                color: _popularText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (isCurrent)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _successBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: _successText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priceText,
                style: const TextStyle(
                  color: _title,
                  fontSize: 48 / 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/$interval',
                style: const TextStyle(fontSize: 18, color: _muted),
              ),
            ],
          ),
          if (yearlyEquivalent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                yearlyEquivalent,
                style: const TextStyle(fontSize: 13, color: _muted),
              ),
            ),
          const SizedBox(height: 16),
          const Divider(height: 24, color: _divider),
          Text(
            isCurrent
                ? "What's Included in Your Plan"
                : "What's included in your plan",
            style: const TextStyle(
              fontSize: 18,
              color: _title,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final feature in features.take(6)) _buildFeatureRow(feature),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: isCurrent
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF98A2B3),
                      side: const BorderSide(color: Color(0xFFD0D5DD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Your Current Plan'),
                  )
                : isLockedForSubscription
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF98A2B3),
                      side: const BorderSide(color: Color(0xFFD0D5DD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Subscription Active'),
                  )
                : (isSelected
                      ? ElevatedButton(
                          onPressed: _controller.isSubmitting
                              ? null
                              : _submitSubscription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _controller.isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text('Subscribe - $priceText'),
                        )
                      : OutlinedButton(
                          onPressed: () => _selectPlan(plan),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryBlue,
                            side: const BorderSide(color: _primaryBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text('Select $cycleLabel'),
                        )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: _title),
        title: const Text(
          'Subscribe',
          style: TextStyle(color: _title, fontWeight: FontWeight.w700),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, ProfileData.instance]),
        builder: (context, _) {
          final hasPlans = _controller.hasPlans;
          final allPlans = _controller.plans;
          final activeInterval = _activeInterval(allPlans);
          final hasActiveSubscription =
              SubscriptionAccess.isCurrentSubscriptionActive();
          final activeSubscriptionMessage =
              SubscriptionAccess.activeSubscriptionBlockMessage();
          final scopedPlans = _plansForInterval(allPlans, activeInterval);
          final availableCycles = _availableCycles(allPlans);
          final currentPlan =
              _controller.currentPlan != null &&
                  _normalizeInterval(_controller.currentPlan!.interval) ==
                      activeInterval
              ? _controller.currentPlan
              : null;
          final selectedPlan = _controller.selectedPlan;
          final plansToShow = hasPlans
              ? scopedPlans.where((plan) => plan.id != currentPlan?.id).toList()
              : <PlanModel>[];

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () =>
                  _controller.loadPlans(snackbarNotifier: _snackbarNotifier),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  if (hasActiveSubscription &&
                      activeSubscriptionMessage != null &&
                      activeSubscriptionMessage.isNotEmpty)
                    _buildActiveSubscriptionBanner(activeSubscriptionMessage),
                  if (hasPlans)
                    _buildCycleSelector(
                      availableCycles: availableCycles,
                      activeInterval: activeInterval,
                    ),
                  if (_controller.isLoadingPlans)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (!hasPlans)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'No plans available right now.',
                            style: TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => _controller.loadPlans(
                              snackbarNotifier: _snackbarNotifier,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    if (currentPlan != null)
                      _buildPlanCard(
                        scopedPlans: scopedPlans,
                        plan: currentPlan,
                        isCurrent: true,
                        isSelected: false,
                        isLockedForSubscription: false,
                      ),
                    for (final plan in plansToShow)
                      () {
                        final isLockedForSubscription = _isLockedBySubscription(
                          plan: plan,
                          hasActiveSubscription: hasActiveSubscription,
                        );
                        final card = _buildPlanCard(
                          scopedPlans: scopedPlans,
                          plan: plan,
                          isCurrent: false,
                          isSelected: plan.id == selectedPlan?.id,
                          isLockedForSubscription: isLockedForSubscription,
                        );
                        if (plan.id == selectedPlan?.id ||
                            isLockedForSubscription) {
                          return card;
                        }
                        return GestureDetector(
                          onTap: () => _selectPlan(plan),
                          child: card,
                        );
                      }(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
