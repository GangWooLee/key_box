import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Concealed-clipboard bridge (보안 — CSO F6): write copied secrets to the
    // pasteboard tagged org.nspasteboard.ConcealedType so clipboard managers
    // (Paste, Maccy, …) skip persisting/syncing them. Dart calls this via the
    // ClipboardService; see lib/services/clipboard_service.dart.
    let secureClipboardChannel = FlutterMethodChannel(
      name: "keybox/secure_clipboard",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    secureClipboardChannel.setMethodCallHandler { (call, result) in
      guard call.method == "copyConcealed" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let value = args["value"] as? String
      else {
        result(FlutterError(
          code: "bad_args",
          message: "copyConcealed expects { value: String }",
          details: nil
        ))
        return
      }

      let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
      let pasteboard = NSPasteboard.general
      // Declare both types in one call, then write both — a second declare
      // would clear the first. .string is the readable value; the concealed
      // marker signals managers to skip it.
      pasteboard.declareTypes([.string, concealed], owner: nil)
      pasteboard.setString(value, forType: .string)
      pasteboard.setString(value, forType: concealed)
      result(nil)
    }

    super.awakeFromNib()
  }
}
