import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import '../../../core/constants/stripe_config.dart';
import '../../../core/helpers/validation.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../../../core/services/app_pigeon/app_pigeon.dart';
import '../../profile/interface/profile_interface.dart';
import '../../profile/model/profile_data.dart';
import '../implement/plan_interface_impl.dart';
import '../interface/plan_interface.dart';
import '../model/payment_response_model.dart';
import '../model/plan_model.dart';

class SubscribePaymentController extends ChangeNotifier {
  SubscribePaymentController();

  final List<PlanModel> _plans = [];
  PlanModel? _currentPlan;
  PlanModel? _selectedPlan;
  bool _isLoadingPlans = false;
  bool _isSubmitting = false;
  bool _initialized = false;

  List<PlanModel> get plans => List.unmodifiable(_plans);
  PlanModel? get currentPlan => _currentPlan;
  PlanModel? get selectedPlan => _selectedPlan;
  bool get isLoadingPlans => _isLoadingPlans;
  bool get isSubmitting => _isSubmitting;

  bool get hasPlans => _plans.isNotEmpty;
  bool get hasSelection => _selectedPlan != null;
  bool get isCurrentSelection =>
      _selectedPlan != null && _selectedPlan?.id == _currentPlan?.id;

  PlanInterface get _planInterface => _ensurePlanInterface();

  void init() {
    if (_initialized) return;
    _initialized = true;
  }

  PlanInterface _ensurePlanInterface() {
    if (!Get.isRegistered<PlanInterface>()) {
      Get.put<PlanInterface>(
        PlanInterfaceImpl(appPigeon: Get.find<AppPigeon>()),
      );
    }
    return Get.find<PlanInterface>();
  }

  Future<void> loadPlans({SnackbarNotifier? snackbarNotifier}) async {
    _setLoadingPlans(true);
    try {
      final result = await _planInterface.getPlans();
      result.fold(
        (failure) => _handlePlanLoadFailure(failure, snackbarNotifier),
        (success) => _handlePlanLoadSuccess(success),
      );
    } catch (_) {
      snackbarNotifier?.notifyError(
        message: 'An error occurred while loading plans',
      );
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
    if (!_canSubmit(snackbarNotifier)) return false;

    var success = false;
    _setSubmitting(true);
    try {
      final billingInfo = await _requireBillingInfo(snackbarNotifier);
      final paymentData = await _createPayment(billingInfo, snackbarNotifier);
      if (paymentData == null) return false;

      await _presentPaymentSheet(billingInfo, paymentData);
      success = await _confirmPayment(paymentData, snackbarNotifier);
    } on TimeoutException {
      snackbarNotifier.notifyError(
        message: 'Payment timed out. Please try again.',
      );
    } on StripeException catch (e) {
      snackbarNotifier.notifyError(
        message:
            e.error.localizedMessage ??
            e.error.message ??
            'Stripe payment cancelled',
      );
    } catch (_) {
      snackbarNotifier.notifyError(message: 'Stripe payment failed');
    } finally {
      _setSubmitting(false);
    }
    return success;
  }

  bool _canSubmit(SnackbarNotifier snackbarNotifier) {
    if (!hasSelection) {
      snackbarNotifier.notifyError(message: 'Please select a plan.');
      return false;
    }
    if (isCurrentSelection) {
      snackbarNotifier.notify(message: 'You are already on this plan.');
      return false;
    }
    if (StripeConfig.publishableKey.isEmpty ||
        StripeConfig.publishableKey.contains('replace_with_your_key')) {
      snackbarNotifier.notifyError(
        message: 'Stripe publishable key is not set.',
      );
      return false;
    }
    return true;
  }

  void _handlePlanLoadFailure(failure, SnackbarNotifier? snackbarNotifier) {
    snackbarNotifier?.notifyError(
      message: failure.uiMessage.isNotEmpty
          ? failure.uiMessage
          : 'Failed to load plans',
    );
    _plans.clear();
    _currentPlan = null;
    _selectedPlan = null;
    notifyListeners();
  }

  void _handlePlanLoadSuccess(success) {
    final fetchedPlans = success.data ?? <PlanModel>[];
    _plans
      ..clear()
      ..addAll(fetchedPlans);

    _currentPlan = _resolveCurrentPlan(fetchedPlans);
    _selectedPlan = _resolveSelectedPlan(fetchedPlans, _currentPlan);
    notifyListeners();
  }

  PlanModel? _resolveCurrentPlan(List<PlanModel> plans) {
    for (final plan in plans) {
      if (plan.price == 0) return plan;
    }
    return plans.isNotEmpty ? plans.first : null;
  }

  PlanModel? _resolveSelectedPlan(List<PlanModel> plans, PlanModel? current) {
    if (plans.isEmpty) return null;
    return plans.firstWhere(
      (plan) => plan.id != current?.id && plan.price > 0,
      orElse: () => current ?? plans.first,
    );
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

  bool _isValidEmail(String value) => value.isNotEmpty && isEmail(value);

  bool _isValidName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final normalized = trimmed.toLowerCase();
    return normalized != 'n/a' && normalized != 'profile name';
  }

  String _readString(dynamic value) => value?.toString().trim() ?? '';

  String _readNameFromMap(Map data) {
    final direct = _readString(data['name']);
    if (_isValidName(direct)) return direct;
    final fullName = _readString(data['fullName'] ?? data['fullname']);
    if (_isValidName(fullName)) return fullName;
    final firstName = _readString(data['firstName'] ?? data['firstname']);
    final lastName = _readString(data['lastName'] ?? data['lastname']);
    final combined = [firstName, lastName].where((v) => v.isNotEmpty).join(' ');
    if (_isValidName(combined)) return combined;
    return '';
  }

  String _readEmailFromMap(Map data) {
    final direct = _readString(data['email']);
    if (_isValidEmail(direct)) return direct;
    final alt = _readString(data['emailAddress'] ?? data['mail']);
    if (_isValidEmail(alt)) return alt;
    return '';
  }

  _BillingInfo _readBillingFromProfileData() {
    return _BillingInfo(
      email: _readString(ProfileData.instance.email),
      name: _readString(ProfileData.instance.name),
    );
  }

  _BillingInfo _mergeBilling(_BillingInfo current, _BillingInfo next) {
    final email = _isValidEmail(current.email) ? current.email : next.email;
    final name = _isValidName(current.name) ? current.name : next.name;
    return _BillingInfo(email: email, name: name);
  }

  _BillingInfo _readBillingFromMap(Map data) {
    return _BillingInfo(
      email: _readEmailFromMap(data),
      name: _readNameFromMap(data),
    );
  }

  Future<_BillingInfo> _readBillingFromAuth() async {
    final status = await Get.find<AppPigeon>().currentAuth();
    if (status is! Authenticated) return const _BillingInfo.empty();

    final authData = status.auth.data;
    if (authData is! Map) return const _BillingInfo.empty();

    var billing = _readBillingFromMap(authData);
    final userData = authData['user'];
    if (userData is Map) {
      billing = _mergeBilling(billing, _readBillingFromMap(userData));
    }
    return billing;
  }

  Future<_BillingInfo> _readBillingFromProfileApi() async {
    if (!Get.isRegistered<ProfileInterface>()) {
      return const _BillingInfo.empty();
    }

    final result = await Get.find<ProfileInterface>().getProfile();
    return result.fold((_) => const _BillingInfo.empty(), (success) {
      final profile = success.data;
      if (profile == null) return const _BillingInfo.empty();
      ProfileData.instance.updateFromProfile(profile);
      return _BillingInfo(
        email: _readString(profile.email),
        name: _readString(profile.name),
      );
    });
  }

  Future<_BillingInfo> _resolveBillingInfo() async {
    var billing = _readBillingFromProfileData();
    if (!billing.isComplete) {
      billing = _mergeBilling(billing, await _readBillingFromAuth());
    }
    if (!billing.isComplete) {
      billing = _mergeBilling(billing, await _readBillingFromProfileApi());
    }
    return _BillingInfo(
      email: _isValidEmail(billing.email) ? billing.email : '',
      name: _isValidName(billing.name) ? billing.name : '',
    );
  }

  Future<_BillingInfo> _requireBillingInfo(
    SnackbarNotifier snackbarNotifier,
  ) async {
    final billingInfo = await _resolveBillingInfo();
    if (!billingInfo.isComplete) {
      snackbarNotifier.notify(
        message:
            'Name/email missing. You can still continue, but please update your profile later.',
      );
    }
    return billingInfo;
  }

  Future<PlanPaymentCreateResponse?> _createPayment(
    _BillingInfo billingInfo,
    SnackbarNotifier snackbarNotifier,
  ) async {
    final createResult = await _planInterface
        .createPlanPayment(
          planId: _selectedPlan!.id,
          provider: 'stripe',
          email: billingInfo.email,
          name: billingInfo.name,
        )
        .timeout(const Duration(seconds: 25));

    final paymentData = createResult.fold((failure) {
      snackbarNotifier.notifyError(
        message: failure.uiMessage.isNotEmpty
            ? failure.uiMessage
            : 'Failed to create payment',
      );
      return null;
    }, (success) => success.data);

    if (paymentData == null ||
        paymentData.clientSecret == null ||
        paymentData.clientSecret!.isEmpty) {
      snackbarNotifier.notifyError(
        message: 'Stripe client secret missing from backend response.',
      );
      return null;
    }

    return paymentData;
  }

  Future<void> _presentPaymentSheet(
    _BillingInfo billingInfo,
    PlanPaymentCreateResponse paymentData,
  ) async {
    await Stripe.instance
        .initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentData.clientSecret!,
            merchantDisplayName: StripeConfig.merchantName,
            style: ThemeMode.light,
            billingDetails: BillingDetails(
              email: billingInfo.email,
              name: billingInfo.name,
            ),
          ),
        )
        .timeout(const Duration(seconds: 25));

    await Stripe.instance.presentPaymentSheet().timeout(
      const Duration(seconds: 60),
    );
  }

  Future<bool> _confirmPayment(
    PlanPaymentCreateResponse paymentData,
    SnackbarNotifier snackbarNotifier,
  ) async {
    final confirmResult = await _planInterface
        .confirmPlanPayment(
          paymentId: paymentData.paymentId,
          providerPaymentId: paymentData.providerPaymentId,
        )
        .timeout(const Duration(seconds: 25));

    return confirmResult.fold(
      (failure) {
        snackbarNotifier.notifyError(
          message: failure.uiMessage.isNotEmpty
              ? failure.uiMessage
              : 'Payment confirmation failed',
        );
        return false;
      },
      (success) {
        snackbarNotifier.notifySuccess(message: success.message);
        _currentPlan = _selectedPlan;
        notifyListeners();
        return true;
      },
    );
  }
}

class _BillingInfo {
  final String email;
  final String name;

  const _BillingInfo({required this.email, required this.name});

  const _BillingInfo.empty() : email = '', name = '';

  bool get isComplete => email.isNotEmpty && name.isNotEmpty;
}
