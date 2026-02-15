import 'package:flutter/foundation.dart';

base class ApiEndpoints {
  static const String socketUrl = _LiveHostUrls.socketUrl;
  // static const String socketUrl = _LiveHostUrls.socketUrl;

  static const String baseUrl = _LiveHostUrls.baseUrl;

  /// ### post
  static const String login = _Auth.login;

  static const String signup = _Auth.signup;

  static const String logout = _Auth.logout;

  static const String me = _Auth.me;

  static const String verifyCode = _Auth.verifyCode;

  static const String verifyEmail = _Auth.verifyEmail;

  //static const String registerVerify = _Auth.registerVerify;

  //static const String resetPassword = _Auth.resetPassword;

  static const String forgetPassword = _Auth.forgetPassword;

  static const String changePassword = _Auth.changePassword;

  static const String resetPassword = _Auth.resetPassword;

  static const String createNewPassword = _Auth.resetPassword;

  /// ### post
  static const String refreshToken = _Auth.refreshToken;

  //------------interest----------------
  /// ### get
  static const String getInterests = _Interest.getallInterests;

  //----------------verification----------------
  /// ### post
  static const String verification = _Verification.verification;

  //-----------------badges----------------
  static const String getMyBadges = _Badges.getMyBadges;
  static const String allBadges = _Badges.allBadges;
  static const String giveBadges = _Badges.giveBadges;

  //---------------report----------------

  /// ### post
  static const String sendReport = _Report.sendReport;

  //------------notification----------------
  /// ### get
  static const String getAllNotifications = _Notification.getAllNotifications;

  /// ### get
  static String getUserNotifications(String userId) =>
      _Notification.getUserNotifications(userId);

  /// ### get
  static String getNotificationById(String notificationId) =>
      _Notification.getNotificationById(notificationId);

  /// ### post
  static const String readAllNotifications = _Notification.readAllNotifications;

  /// ### patch
  static String markNotificationAsRead({required String notificationId}) =>
      _Notification.markNotificationAsRead(notificationId);

  /// ### patch
  static const String markAllAsRead = _Notification.markAllAsRead;

  /// ### patch
  static String markAllNotificationsAsRead(String userId) =>
      _Notification.markAllAsReadByUser(userId);

  // ---------------------- USER -----------------------------

  /// ### get
  static String getuserbyId(String id) => _User.getuserbyId(id);

  /// ### get
  static const String getCurrentProfile = _User.getCurrentProfile;

  /// ### put
  static const String editProfile = _User.updateProfile;

  /// ### put
  static const String uploadProfileAvatar = _User.uploadProfileAvatar;

  /// ### put
  static const String updateNotificationSettings = _User.updateSettings;

  /// ### get
  static const String history = _User.history;

  /// ### get
  static const String allUser = _User.allUser;

  static const String setVisibility = _User.setVisibility;

  static const String status = _User.status;

  // ---------------------- LICENSE -----------------------------
  /// ### post
  static const String createLicense = _License.create;

  /// ### put
  static String updateLicense(String userId) => _License.update(userId);

  // ---------------------- RIDE -----------------------------
  /// ### post
  static const String createRide = _Ride.createRide;
  static String updateRide(String id) => _Ride.updateRide(id);
  static String leaveRide(String id) => _Ride.leaveRide(id);
  static String finishRide(String id) => _Ride.finishRide(id);
  static String getRideById(String id) => _Ride.getRideById(id);
  static String joinRide(String id) => _Ride.joinRide(id);
  static String voteForKick(String id) => _Ride.voteForKick(id);
  static String deleteRide(String id) => _Ride.deleteRide(id);
  static const String filterRide = _Ride.filterRide;

  // ---------------------- Booking -----------------------------
  static String getAllBookingsForARide(String rideId) =>
      _Booking.getAllBookingsForARide(rideId);
  static const String getMyBookings = _Booking.getMyBookings;

  // ---------------------- Message -----------------------------
  /// ### Get
  static const String getAllChat = _Message.getAllChat;

  /// ### Get
  static String getMessages(String chatId) => _Message.getMessages(chatId);

  static String getSingleChat(String chatId) => _Message.getSingleChat(chatId);

  /// ### Post
  static String sendMessage(String chatId) => _Message.sendMessage(chatId);

  /// ### Put
  static String messageRead(String messageId) =>
      _Message.messageRead(messageId);

  /// ### Put
  static String editMessage(String messageId) =>
      _Message.editMessage(messageId);

  /// ### Delete
  static String deleteMessage(String messageId) =>
      _Message.deleteMessage(messageId);

  ////////////
  ///
  static String getUselAllChat(String chatId) =>
      _Message.getUselallChat(chatId);

  ///////////
  ///
  static String timeExtend(String chatId) => _Message.timeExtend(chatId);

  // ---------------------- LICENSE -----------------------------
  /// ### get
  static const String getLicense = _License.get;

  // ---------------------- TEEN DRIVER EXPERIENCE -----------------------------
  /// ### post
  static const String createTeenDriverExperience =
      _TeenDriverExperience.createExperience;

  /// ### get
  static const String getTeenDriverPosts =
      _TeenDriverExperience.teenDriverPosts;

  /// ### post
  static String addTeenDriverPostComment(String postId) =>
      _TeenDriverExperience.addComment(postId);

  /// ### get
  static String getTeenDriverPostComments(String postId) =>
      _TeenDriverExperience.getComments(postId);

  /// ### post
  static String likeTeenDriverPost(String postId) =>
      _TeenDriverExperience.likePost(postId);

  /// ### get
  static const String getAlerts = _Alerts.getAlerts;

  // ---------------------- HOME -----------------------------
  /// ### get
  static const String getHome = _Home.getHome;

  // ---------------------- TICKET -----------------------------
  /// ### get
  static String getMyTickets({String? status}) =>
      _Ticket.getMyTickets(status: status);

  /// ### get
  static String getTicketById(String ticketId) =>
      _Ticket.getTicketById(ticketId);
}

class _LocalHostWifi { 
   static const String socketUrl = 'https://backend-bigghustle-icpx.onrender.com';
   static const String baseUrl = 'https://backend-bigghustle-icpx.onrender.com/api/v1';
  //static const String baseUrl = 'http://10.10.5.85:5000/api/v1';

  // static const String baseUrl = 'http://10.10.5.85:5000/api/v1';
}



class _LiveHostUrls {
  // static const String socketUrl = 'https://backend-bigghustle-icpx.onrender.com';
  //  static const String baseUrl = 'https://backend-bigghustle-icpx.onrender.com/api/v1';
   static const String socketUrl = 'https://api.drivestatusllc.com';
   static const String baseUrl = 'https://api.drivestatusllc.com/api/v1';
  // static const String baseUrl = 'http://10.10.5.94:5000/api/v1';
}

class _Auth {
  @protected
  static const String _authRoute = '${ApiEndpoints.baseUrl}/auth';
  static const String login = '$_authRoute/login';
  static const String signup = '$_authRoute/register';
  static const String logout = '$_authRoute/logout';
  static const String me = '$_authRoute/me';
  static const String forgetPassword = '$_authRoute/forget';
  static const String refreshToken = '$_authRoute/refresh-token';
  static const String verifyCode = '$_authRoute/verify';
  static const String verifyEmail = '$_authRoute/verify';
  //static const String registerVerify = '$_authRoute/verify-otp';
  static const String changePassword = '$_authRoute/change-password';
  static const String resetPassword = '$_authRoute/reset-password';
}

//------------------------------ Interest -----------------------------
class _Interest {
  static const String _interestRoute = '${ApiEndpoints.baseUrl}/interest';
  static const String getallInterests = '$_interestRoute/';
}

// ---------------------- Verification -----------------------------
class _Verification {
  static const String _verificationRoute =
      '${ApiEndpoints.baseUrl}/verification';
  static const String verification = '$_verificationRoute/create';
}

// ---------------------- Badges -----------------------------
class _Badges {
  static const String _badgesRoute = '${ApiEndpoints.baseUrl}/badges';
  static const String getMyBadges = '$_badgesRoute/all-badges';
  static const String allBadges = '$_badgesRoute/';
  static const String giveBadges = '$_badgesRoute/give';
}

// ---------------------- Report -----------------------------
class _Report {
  static const String _reportRoute = '${ApiEndpoints.baseUrl}/reports';
  static const String sendReport = '$_reportRoute/';
}

// ---------------------- Notification -----------------------------
class _Notification {
  static const String _notificationRoute =
      '${ApiEndpoints.baseUrl}/notifications';
  static String markNotificationAsRead(String notificationId) =>
      '$_notificationRoute/mark-as-read/$notificationId';
  static const String readAllNotifications =
      '$_notificationRoute/mark-all-as-read';
  static const String markAllAsRead = '$_notificationRoute/mark-all-as-read';
  static String markAllAsReadByUser(String userId) =>
      '$_notificationRoute/read/$userId';
  static const String getAllNotifications = '$_notificationRoute/';
  static String getUserNotifications(String userId) =>
      '$_notificationRoute/$userId';
  static String getNotificationById(String notificationId) =>
      '$_notificationRoute/$notificationId';
}

// ---------------------- USER -----------------------------
class _User {
  static const String _userRoute = '${ApiEndpoints.baseUrl}/user';
  static String getuserbyId(String id) => '$_userRoute/single-user/$id';
  static const String getCurrentProfile = '$_userRoute/profile';

  static const String updateProfile = '$_userRoute/profile';
  static const String uploadProfileAvatar = '$_userRoute/upload-avatar';
  static const String updateSettings = '$_userRoute/settings';
  static const String history = '$_userRoute/history';
  static const String allUser = '$_userRoute/all-user';
  static const String setVisibility = '$_userRoute/visibility';
  static const String status = '$_userRoute/status';
}

// ---------------------- LICENSE -----------------------------
class _License {
  static const String _licenseRoute = '${ApiEndpoints.baseUrl}/license';
  static const String get = '$_licenseRoute/';
  static const String create = '$_licenseRoute/create';
  static String update(String userId) => '$_licenseRoute/$userId';
}

// ---------------------- TEEN DRIVER EXPERIENCE -----------------------------
class _TeenDriverExperience {
  static const String _teenDriverExperienceRoute =
      '${ApiEndpoints.baseUrl}/teen/posts';
  static const String createExperience = _teenDriverExperienceRoute;
  static const String teenDriverPosts = _teenDriverExperienceRoute;
  static String addComment(String postId) =>
      '$_teenDriverExperienceRoute/$postId/comments';
  static String getComments(String postId) =>
      '$_teenDriverExperienceRoute/$postId/comments';
  static String likePost(String postId) =>
      '$_teenDriverExperienceRoute/$postId/like';
}

// ---------------------- ALERTS -----------------------------
class _Alerts {
  static const String _alertsRoute = '${ApiEndpoints.baseUrl}/alerts';
  static const String getAlerts = '$_alertsRoute/me';
}

// ---------------------- HOME -----------------------------
class _Home {
  static const String _homeRoute = '${ApiEndpoints.baseUrl}/user/home';
  static const String getHome = _homeRoute;
}

// ---------------------- TICKET -----------------------------
class _Ticket {
  static const String _ticketRoute = '${ApiEndpoints.baseUrl}/tickets';
  static String getMyTickets({String? status}) {
    final baseUrl = '$_ticketRoute/me';
    if (status != null) {
      return '$baseUrl?status=$status';
    }
    return baseUrl;
  }

  static String getTicketById(String ticketId) => '$_ticketRoute/$ticketId';
}

// ---------------------- RIDE -----------------------------
class _Ride {
  static const String _rideRoute = '${ApiEndpoints.baseUrl}/ride';
  static const String createRide = _rideRoute;
  static String updateRide(String id) => "$_rideRoute/$id";
  static String leaveRide(String id) => "$_rideRoute/$id/leave";
  static String finishRide(String id) => "$_rideRoute/$id/filter";
  static const String filterRide = _rideRoute;
  static String getRideById(String id) => "$_rideRoute/$id";
  static String joinRide(String id) => "$_rideRoute/$id/join";
  static String voteForKick(String id) => "$_rideRoute/$id/kick";
  static String deleteRide(String id) => "$_rideRoute/$id";
}

class _Booking {
  static const String _bookingRoute = '${ApiEndpoints.baseUrl}/booking';
  static const String getMyBookings = "$_bookingRoute/my";
  static String getAllBookingsForARide(String rideId) =>
      "$_bookingRoute/ride/$rideId";
}

// ---------------------- MESSAGE -----------------------------
class _Message {
  static const String _messageRoute = '${ApiEndpoints.baseUrl}/chat';

  static const String getAllChat = "$_messageRoute/get-chat";

  static String getSingleChat(String chatId) =>
      "$_messageRoute/get-single-chat/$chatId";

  /// Get
  static String getMessages(String chatId) => "$_messageRoute/messages/$chatId";

  /// Post
  static String sendMessage(String chatId) => "$_messageRoute/send-message";

  /// Put
  static String messageRead(String messageId) =>
      "$_messageRoute/read/$messageId";

  /// Put
  static String editMessage(String messageId) => "$_messageRoute/$messageId";

  /// Delete
  static String deleteMessage(String messageId) => "$_messageRoute/$messageId";

  static String getUselallChat(String chatId) => "$_messageRoute/get-chat";

  static String timeExtend(String chatId) =>
      "$_messageRoute/extend-time/$chatId";
}

// ---------------------- LICENSE -----------------------------
// class _License {
//   static const String _licenseRoute = '${ApiEndpoints.baseUrl}/license';
//   static const String getLicense = _licenseRoute;
// }
