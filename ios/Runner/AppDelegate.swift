import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    excludeAppDataFromBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // The database and the safety backups live in these folders. Financial data must not be
  // uploaded silently to iCloud Backup: users back up explicitly.
  // Excluding a folder excludes everything inside it, including files created later.
  private func excludeAppDataFromBackup() {
    let fileManager = FileManager.default
    for directory in [FileManager.SearchPathDirectory.documentDirectory, .applicationSupportDirectory] {
      guard var url = fileManager.urls(for: directory, in: .userDomainMask).first else { continue }
      try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try? url.setResourceValues(values)
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
