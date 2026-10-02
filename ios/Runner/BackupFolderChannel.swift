import Flutter
import UIKit
import UniformTypeIdentifiers

/// The folder automatic backups go to: the user picks it once in the Files picker and a
/// security-scoped bookmark keeps the access. The app only creates, lists and deletes its
/// own backup files in it.
///
/// Errors: `unreachable` when the bookmark no longer resolves or the folder can't be used.
final class BackupFolderChannel: NSObject, UIDocumentPickerDelegate {
  private let channel: FlutterMethodChannel
  private var pending: FlutterResult?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "open_sky_finance/backup_folder", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result) }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let folder = args["folder"] as? String
    switch call.method {
    case "pick":
      pick(result)
    case "write":
      Self.background(folder, result) { url in
        let data = (args["bytes"] as! FlutterStandardTypedData).data
        try data.write(to: url.appendingPathComponent(args["name"] as! String), options: .atomic)
        return nil
      }
    case "list":
      Self.background(folder, result) { url in
        try FileManager.default.contentsOfDirectory(atPath: url.path)
      }
    case "delete":
      Self.background(folder, result) { url in
        let file = url.appendingPathComponent(args["name"] as! String)
        if FileManager.default.fileExists(atPath: file.path) {
          try FileManager.default.removeItem(at: file)
        }
        return nil
      }
    case "release":
      // Dropping the bookmark is all there is to release.
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Runs [work] on the granted folder off the main thread; any failure means it can't be reached.
  private static func background(
    _ bookmark: String?,
    _ result: @escaping FlutterResult,
    _ work: @escaping (URL) throws -> Any?
  ) {
    DispatchQueue.global(qos: .utility).async {
      do {
        let value = try withFolder(bookmark, work)
        DispatchQueue.main.async { result(value) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "unreachable", message: String(describing: type(of: error)), details: nil))
        }
      }
    }
  }

  private static func withFolder(_ bookmark: String?, _ work: (URL) throws -> Any?) throws -> Any? {
    guard let bookmark, let data = Data(base64Encoded: bookmark) else { throw CocoaError(.fileNoSuchFile) }
    var stale = false
    let folder = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale)
    guard folder.startAccessingSecurityScopedResource() else { throw CocoaError(.fileReadNoPermission) }
    defer { folder.stopAccessingSecurityScopedResource() }
    return try work(folder)
  }

  private func pick(_ result: @escaping FlutterResult) {
    pending?(nil)
    pending = result
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder])
    picker.delegate = self
    picker.allowsMultipleSelection = false
    var top = UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
      .first
    while let presented = top?.presentedViewController { top = presented }
    guard let top else {
      pending = nil
      result(nil)
      return
    }
    top.present(picker, animated: true)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = pending, let folder = urls.first else { return }
    pending = nil
    guard folder.startAccessingSecurityScopedResource() else {
      result(FlutterError(code: "unreachable", message: nil, details: nil))
      return
    }
    defer { folder.stopAccessingSecurityScopedResource() }
    do {
      let bookmark = try folder.bookmarkData()
      result(["ref": bookmark.base64EncodedString(), "name": folder.lastPathComponent])
    } catch {
      result(FlutterError(code: "unreachable", message: nil, details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pending?(nil)
    pending = nil
  }
}
