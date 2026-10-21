import Foundation

// iloader 2.3.10 signs both targets into group.<signed app bundle ID>.
// Resolve from the containing app so the keyboard uses exactly the same group.
enum InstallationIdentity {
  static func appBundleURL(for bundleURL: URL) -> URL {
    guard bundleURL.pathExtension == "appex" else { return bundleURL }
    return bundleURL.deletingLastPathComponent().deletingLastPathComponent()
  }

  static var appBundle: Bundle {
    Bundle(url: self.appBundleURL(for: Bundle.main.bundleURL)) ?? .main
  }

  static var keyboardBundleIdentifier: String {
    self.keyboardBundleIdentifier(in: self.appBundle)
  }

  static func keyboardBundleIdentifier(in appBundle: Bundle) -> String {
    let keyboardURL = appBundle.bundleURL.appendingPathComponent("PlugIns/SayboardKeyboard.appex")
    return Bundle(url: keyboardURL)?.bundleIdentifier
      ?? "\(appBundle.bundleIdentifier ?? "app.sayboard").keyboard"
  }

  static var sideloadAppGroupIdentifier: String {
    self.sideloadAppGroupIdentifier(in: .main)
  }

  static func sideloadAppGroupIdentifier(in bundle: Bundle) -> String {
    let app = Bundle(url: self.appBundleURL(for: bundle.bundleURL)) ?? bundle
    return "group.\(app.bundleIdentifier ?? "app.sayboard")"
  }
}
