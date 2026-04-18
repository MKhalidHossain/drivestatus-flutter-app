import 'package:get/get.dart';
import '../../moduls/auth/implement/auth_interface_impl.dart';
import '../../moduls/auth/interface/auth_interface.dart';
import '../../moduls/home/implement/home_interface_impl.dart';
import '../../moduls/home/interface/home_interface.dart';
import '../../moduls/license/implement/license_interface_impl.dart';
import '../../moduls/license/interface/license_interface.dart';
import '../../moduls/notification/implement/notification_interface_impl.dart';
import '../../moduls/notification/interface/notification_interface.dart';
import '../../moduls/profile/implement/profile_interface_impl.dart';
import '../../moduls/profile/interface/profile_interface.dart';
import '../../moduls/subscribe/service/subscription_service.dart';
import '../../moduls/ticket/implement/ticket_interface_impl.dart';
import '../../moduls/ticket/interface/ticket_interface.dart';
import '../services/app_pigeon/app_pigeon.dart';

void initServices() {
  Get.put<AuthInterface>(AuthInterfaceImpl(appPigeon: Get.find<AppPigeon>()));
  Get.put<LicenseInterface>(
    LicenseInterfaceImpl(appPigeon: Get.find<AppPigeon>()),
  );
  Get.put<ProfileInterface>(
    ProfileInterfaceImpl(appPigeon: Get.find<AppPigeon>()),
  );
  Get.put<TicketInterface>(
    TicketInterfaceImpl(appPigeon: Get.find<AppPigeon>()),
  );
  Get.put<HomeInterface>(HomeInterfaceImpl(appPigeon: Get.find<AppPigeon>()));
  Get.put<NotificationInterface>(
    NotificationInterfaceImpl(appPigeon: Get.find<AppPigeon>()),
  );
  Get.put<SubscriptionService>(SubscriptionService(), permanent: true);
}
