import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override var window: UIWindow? {
    get { super.window }
    set { super.window = newValue }
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    window = resolveKeyWindow()
    GeneratedPluginRegistrant.register(with: self)
    DispatchQueue.main.async { [weak self] in
      self?.window = self?.resolveKeyWindow()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    window = resolveKeyWindow()
    super.applicationDidBecomeActive(application)
  }

  private func resolveKeyWindow() -> UIWindow? {
    if #available(iOS 13.0, *) {
      let scenes = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
      for scene in scenes {
        if let key = scene.windows.first(where: { $0.isKeyWindow }) {
          return key
        }
      }
      return scenes.first?.windows.first
    }

    return UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first
  }
}
