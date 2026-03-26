import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        // Register our llama plugin manually
        if let registrar = registrar(forPlugin: "LlamaPlugin") {
            LlamaPlugin.register(with: registrar)
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
