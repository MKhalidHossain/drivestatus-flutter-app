import 'package:flutter/material.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../model/plan_model.dart';
import '../../controller/subscribe_payment_controller.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  static const Color _background = Color(0xFFF2F2F2);
  static const Color _borderBlue =  Color(0xFF1976F3);
  static const Color _titleBlue = Colors.black;
  static const Color _accentOrange = Color(0xFFF5A524);

  late final SnackbarNotifier _snackbarNotifier;
  late final SubscribePaymentController _controller;
  bool _initialized = false;

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
      _controller.init();
      _controller.loadPlans(snackbarNotifier: _snackbarNotifier);
    }
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

  String _intervalLabel(String interval, double price) {
    if (price == 0) return 'forever';
    final value = interval.toLowerCase();
    if (value.startsWith('year')) return 'year';
    if (value.startsWith('month')) return 'month';
    return value;
  }

  bool _isPopularPlan(PlanModel plan) {
    final name = plan.name.toLowerCase();
    if (name.contains('pro')) return true;
    final plans = _controller.plans;
    final maxPrice = plans.isNotEmpty
        ? plans.map((item) => item.price).reduce((a, b) => a > b ? a : b)
        : plan.price;
    return plan.price == maxPrice && plan.price > 0;
  }

  void _selectPlan(PlanModel plan) => _controller.selectPlan(plan);

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
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Subscription Active'),
          content: Text('You are now subscribed to ${plan.name} ($priceText).'),
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

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: _borderBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required PlanModel plan,
    required bool isCurrent,
    required bool isSelected,
  }) {
    final isFree = plan.price == 0;
    final priceText = isFree
        ? 'Free'
        : '${_currencySymbol(plan.currency)}${plan.price.toStringAsFixed(2)}';
    final interval = _intervalLabel(plan.interval, plan.price);
    final features = plan.features.isNotEmpty
        ? plan.features
        : <String>[
            'Upgrade anytime for full access',
            'Access to selected API exams',
            'Full-length mock exams',
            'Timed & full simulation modes',
          ];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderBlue, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A000000),
            blurRadius: 18,
            offset: const Offset(0, 12),
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
                  color: _borderBlue,
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
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_isPopularPlan(plan) && !isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _accentOrange,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Popular',
                              style: TextStyle(
                                color: Colors.white,
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
                          color: const Color(0xFFCFEBD1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Color(0xFF2D6A35),
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
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/$interval',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 24),
          Text(
            isCurrent
                ? "What's Included in Your Plan"
                : "What's included in your plan",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                      foregroundColor: Colors.black38,
                      side: const BorderSide(color: Color(0xFFD7D7D7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Your Current Plan'),
                  )
                : (isSelected
                      ? ElevatedButton(
                          onPressed: _controller.isSubmitting
                              ? null
                              : _submitSubscription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _borderBlue,
                            foregroundColor: Colors.white,
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
                            foregroundColor: _borderBlue,
                            side: const BorderSide(color: _borderBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Select Plan'),
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
        leading: const BackButton(color: _titleBlue),
        title: const Text(
          'Subscribe',
          style: TextStyle(color: _titleBlue, fontWeight: FontWeight.w600),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final hasPlans = _controller.hasPlans;
          final currentPlan = _controller.currentPlan;
          final selectedPlan = _controller.selectedPlan;
          final plansToShow = hasPlans
              ? _controller.plans
                    .where((plan) => plan.id != currentPlan?.id)
                    .toList()
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
                        plan: currentPlan,
                        isCurrent: true,
                        isSelected: false,
                      ),
                    for (final plan in plansToShow)
                      GestureDetector(
                        onTap: () => _selectPlan(plan),
                        child: _buildPlanCard(
                          plan: plan,
                          isCurrent: false,
                          isSelected: plan.id == selectedPlan?.id,
                        ),
                      ),
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
