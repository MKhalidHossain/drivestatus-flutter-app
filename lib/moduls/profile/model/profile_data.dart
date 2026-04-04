import 'dart:io';

import 'package:flutter/material.dart';

import 'profile_response_model.dart';

class ProfileData extends ChangeNotifier {
  ProfileData._();

  static final ProfileData instance = ProfileData._();

  static const String _defaultName = 'Profile Name';
  static const String _defaultPhone = 'N/A';
  static const String _defaultDateOfBirth = 'N/A';
  static const String _defaultEmail = 'N/A';
  static const String _defaultUserId = 'N/A';

  String name = _defaultName;
  String phone = _defaultPhone;
  String dateOfBirth = _defaultDateOfBirth;
  String email = _defaultEmail;
  String userId = _defaultUserId;
  String avatarUrl = '';
  String? avatarPath;
  bool ticketAlerts = false;
  bool licenseExpiryAlerts = false;
  bool inactiveAlerts = false;
  bool teenDriverAlerts = false;
  bool communityAlerts = false;
  bool subscribed = false;
  String planName = '';
  String subscriptionInterval = '';
  String subscriptionStartsAt = '';
  String subscriptionEndsAt = '';
  bool hasLoaded = false;

  void updateProfile({
    required String name,
    required String phone,
    required String dateOfBirth,
  }) {
    this.name = name;
    this.phone = phone;
    this.dateOfBirth = dateOfBirth;
    notifyListeners();
  }

  void updateFromProfile(ProfileResponseModel profile) {
    name = profile.name.isNotEmpty ? profile.name : _defaultName;
    phone = profile.phone.isNotEmpty ? profile.phone : _defaultPhone;
    email = profile.email.isNotEmpty ? profile.email : _defaultEmail;
    userId = profile.id.isNotEmpty ? profile.id : _defaultUserId;
    avatarUrl = profile.avatarUrl;
    avatarPath = null;
    ticketAlerts = profile.ticketAlerts;
    licenseExpiryAlerts = profile.licenseExpiryAlerts;
    inactiveAlerts = profile.inactiveAlerts;
    teenDriverAlerts = profile.teenDriverAlerts;
    communityAlerts = profile.communityAlerts;
    subscribed = profile.subscribed;
    planName = profile.planName;
    subscriptionInterval = profile.subscriptionInterval;
    subscriptionStartsAt = profile.subscriptionStartsAt;
    subscriptionEndsAt = profile.subscriptionEndsAt;
    if (profile.dateOfBirth != null) {
      final date = profile.dateOfBirth!;
      dateOfBirth =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    } else {
      dateOfBirth = _defaultDateOfBirth;
    }
    hasLoaded = true;
    notifyListeners();
  }

  void resetDefaults() {
    name = _defaultName;
    phone = _defaultPhone;
    dateOfBirth = _defaultDateOfBirth;
    email = _defaultEmail;
    userId = _defaultUserId;
    avatarUrl = '';
    avatarPath = null;
    ticketAlerts = false;
    licenseExpiryAlerts = false;
    inactiveAlerts = false;
    teenDriverAlerts = false;
    communityAlerts = false;
    subscribed = false;
    planName = '';
    subscriptionInterval = '';
    subscriptionStartsAt = '';
    subscriptionEndsAt = '';
    hasLoaded = true;
    notifyListeners();
  }

  void updateSubscription({
    required bool subscribed,
    String? planName,
    String? subscriptionInterval,
    String? subscriptionStartsAt,
    String? subscriptionEndsAt,
    bool notify = true,
  }) {
    this.subscribed = subscribed;
    this.planName = planName ?? this.planName;
    this.subscriptionInterval =
        subscriptionInterval ?? this.subscriptionInterval;
    this.subscriptionStartsAt =
        subscriptionStartsAt ?? this.subscriptionStartsAt;
    this.subscriptionEndsAt = subscriptionEndsAt ?? this.subscriptionEndsAt;
    hasLoaded = true;
    if (notify) {
      notifyListeners();
    }
  }

  void updateNotificationSettings({
    required bool ticketAlerts,
    required bool licenseExpiryAlerts,
    required bool inactiveAlerts,
    required bool teenDriverAlerts,
    required bool communityAlerts,
  }) {
    this.ticketAlerts = ticketAlerts;
    this.licenseExpiryAlerts = licenseExpiryAlerts;
    this.inactiveAlerts = inactiveAlerts;
    this.teenDriverAlerts = teenDriverAlerts;
    this.communityAlerts = communityAlerts;
    notifyListeners();
  }

  void updateAvatar(String path) {
    avatarPath = path;
    notifyListeners();
  }

  ImageProvider? get avatarImageProvider {
    if (avatarPath != null && avatarPath!.isNotEmpty) {
      return FileImage(File(avatarPath!));
    }
    if (avatarUrl.isEmpty) {
      return null;
    }
    return NetworkImage(avatarUrl);
  }
}
