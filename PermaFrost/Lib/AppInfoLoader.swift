import Foundation

struct AppInfo: Decodable {
    // Decode the app info from the plist file
    let CFBundleName: String
    let CFBundleIdentifier: String
    let CFBundleShortVersionString: String
    let MinimumOSVersion: String
    let CFBundleExecutable: String?
    private enum CodingKeys: String, CodingKey {
        case CFBundleName
        case CFBundleIdentifier
        case CFBundleShortVersionString
        case MinimumOSVersion
        case CFBundleExecutable
    }
}

func parseAppInfo(from plistPath: String) throws -> AppInfo {
    let data = try Data(contentsOf: URL(fileURLWithPath: plistPath))
    let decoder = PropertyListDecoder()
    return try decoder.decode(AppInfo.self, from: data)
}
