import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bighustle/main.dart';
import 'package:flutter_bighustle/moduls/subscribe/service/subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MyApp accepts a SubscriptionService dependency', () {
    final subscriptionService = SubscriptionService();
    final app = MyApp(subscriptionService: subscriptionService);

    expect(app.subscriptionService, same(subscriptionService));
  });
}
