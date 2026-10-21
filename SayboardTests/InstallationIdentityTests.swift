import Foundation
import Testing

@Suite("Sideload installation identity")
struct InstallationIdentityTests {
  @Test
  func `app and keyboard resolve the same containing app`() {
    let appURL = URL(
      fileURLWithPath: "/private/var/containers/Bundle/Application/example/Sayboard.app",
      isDirectory: true,
    )
    let keyboardURL = appURL.appendingPathComponent("PlugIns/SayboardKeyboard.appex")
    #expect(InstallationIdentity.appBundleURL(for: appURL) == appURL)
    #expect(InstallationIdentity.appBundleURL(for: keyboardURL) == appURL)
  }

  @Test
  func `keyboard identifier comes from the embedded extension`() throws {
    let keyboardURL = InstallationIdentity.appBundle.bundleURL.appendingPathComponent("PlugIns/SayboardKeyboard.appex")
    let keyboard = try #require(Bundle(url: keyboardURL))
    #expect(InstallationIdentity.keyboardBundleIdentifier == keyboard.bundleIdentifier)
  }

  @Test(arguments: ["app.sayboard", "app.sayboard.TESTTEAM01"])
  func `renamed installations share a group and detect the signed keyboard`(appIdentifier: String) throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let appURL = root.appendingPathComponent("Sayboard.app")
    let keyboardURL = appURL.appendingPathComponent("PlugIns/SayboardKeyboard.appex")
    try FileManager.default.createDirectory(at: keyboardURL, withIntermediateDirectories: true)
    for (url, identifier) in [(appURL, appIdentifier), (keyboardURL, "\(appIdentifier).keyboard")] {
      let plist = try PropertyListSerialization.data(
        fromPropertyList: ["CFBundleIdentifier": identifier],
        format: .xml,
        options: 0,
      )
      try plist.write(to: url.appendingPathComponent("Info.plist"))
    }
    let app = try #require(Bundle(url: appURL))
    let keyboard = try #require(Bundle(url: keyboardURL))
    #expect(InstallationIdentity.keyboardBundleIdentifier(in: app) == "\(appIdentifier).keyboard")
    #expect(InstallationIdentity.sideloadAppGroupIdentifier(in: app) == "group.\(appIdentifier)")
    #expect(InstallationIdentity.sideloadAppGroupIdentifier(in: keyboard) == "group.\(appIdentifier)")
  }

  @Test
  func `shared group matches the installation configuration`() throws {
    #if SAYBOARD_SIDELOAD
    let appIdentifier = try #require(InstallationIdentity.appBundle.bundleIdentifier)
    #expect(AppGroup.identifier == "group.\(appIdentifier)")
    #else
    #expect(AppGroup.identifier == "group.app.sayboard.shared")
    #endif
  }
}
