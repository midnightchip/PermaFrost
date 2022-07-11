//
//  DebCreator.swift
//  PermaFrost
//
//  Created by MidnightChips on 7/10/22.
//

import Foundation

class DebCreator {
    let baseTemp = NSTemporaryDirectory() + "PermaFrost/" + UUID().uuidString + "/"
    let tempWorkingPath: String
    private let fileManager = FileManager.default
    private let initialFilePath: String
    private let appInfo: AppInfo

    init(filePath: String, appInfo: AppInfo) {
        initialFilePath = filePath
        self.appInfo = appInfo
        tempWorkingPath = baseTemp + "deb/"
    }

    func createDeb() throws {
        try createMetaData()
        try signBundle()
        try package()
    }

    private func createMetaData() throws {
        try fileManager.createDirectory(atPath: tempWorkingPath, withIntermediateDirectories: true, attributes: nil)
        // Create Applications Directory
        try fileManager.createDirectory(atPath: tempWorkingPath + "Applications", withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(atPath: tempWorkingPath + "DEBIAN", withIntermediateDirectories: true, attributes: nil)

        let controlPath = Bundle.main.url(forResource: "control", withExtension: "")
        // Read file to memory as String
        let controlString = try String(contentsOf: controlPath!, encoding: .utf8)

        let author = appInfo.CFBundleIdentifier.split(separator: ".")
        print(author)
        // Replace placeholder with app info
        var controlStringWithInfo = controlString.replacingOccurrences(of: "{APP_BUNDLE}", with: appInfo.CFBundleIdentifier)
        controlStringWithInfo = controlStringWithInfo.replacingOccurrences(of: "{APP_VERSION}", with: appInfo.CFBundleShortVersionString)
        controlStringWithInfo = controlStringWithInfo.replacingOccurrences(of: "{APP_MIN_IOS}", with: appInfo.MinimumOSVersion)
        controlStringWithInfo = controlStringWithInfo.replacingOccurrences(of: "{APP_NAME}", with: appInfo.CFBundleName)
        controlStringWithInfo = controlStringWithInfo.replacingOccurrences(of: "{APP_AUTHOR}", with: author.count >= 2 ? author[1] : "Unknown")
        // Trim whitespace
        controlStringWithInfo = controlStringWithInfo.trimmingCharacters(in: .whitespacesAndNewlines)
        // Add newline at the end of the string
        controlStringWithInfo += "\n"
        print(tempWorkingPath)

        // Write control string info to temp file
        let controlFilePath = tempWorkingPath + "DEBIAN/control"
        try controlStringWithInfo.write(toFile: controlFilePath, atomically: true, encoding: .utf8)

        // PostInst
        let postinstPath = Bundle.main.url(forResource: "postinst", withExtension: "")
        // Read file to memory as String
        let postinstString = try String(contentsOf: postinstPath!, encoding: .utf8)
        var postinstStringWithInfo = postinstString.replacingOccurrences(of: "{APP_NAME}", with: appInfo.CFBundleName)
        // Trim whitespace
        postinstStringWithInfo = postinstStringWithInfo.trimmingCharacters(in: .whitespacesAndNewlines)
        // Write to file
        let postinstFilePath = tempWorkingPath + "DEBIAN/postinst"
        try postinstStringWithInfo.write(toFile: postinstFilePath, atomically: true, encoding: .utf8)

        // Postrm
        let postRmPath = Bundle.main.url(forResource: "postrm", withExtension: "")
        // Read file to memory as String
        let postRmString = try String(contentsOf: postRmPath!, encoding: .utf8)
        var postRmStringWithInfo = postRmString.replacingOccurrences(of: "{APP_NAME}", with: appInfo.CFBundleName)
        // Trim whitespace
        postRmStringWithInfo = postRmStringWithInfo.trimmingCharacters(in: .whitespacesAndNewlines)
        // Write to file
        let postRmFilePath = tempWorkingPath + "DEBIAN/postrm"
        try postRmStringWithInfo.write(toFile: postRmFilePath, atomically: true, encoding: .utf8)
        // Get Folder name from initialFilePath
        let folderName = initialFilePath.split(separator: "/").last!
        // Recursively copy the initial file path to the Applications directory
        try fileManager.copyItem(atPath: initialFilePath, toPath: tempWorkingPath + "Applications/" + folderName)

        // Set permissions
        try fileManager.setAttributes([FileAttributeKey.posixPermissions: 0o755], ofItemAtPath: tempWorkingPath + "DEBIAN/control")
        try fileManager.setAttributes([FileAttributeKey.posixPermissions: 0o755], ofItemAtPath: tempWorkingPath + "DEBIAN/postinst")
        try fileManager.setAttributes([FileAttributeKey.posixPermissions: 0o755], ofItemAtPath: tempWorkingPath + "DEBIAN/postrm")
        try fileManager.setAttributes([FileAttributeKey.posixPermissions: 0o755], ofItemAtPath: tempWorkingPath + "Applications/" + folderName)
    }

    private func signBundle() throws {
        let folderName = initialFilePath.split(separator: "/").last!
        let appPath = tempWorkingPath + "Applications/" + folderName
        let frameworksPath = appPath + "/Frameworks"
        // Get Entitlements and dev cert from bundle
        let entitlementsPath = Bundle.main.url(forResource: "entitlements", withExtension: "plist")
        let devCertPath = Bundle.main.url(forResource: "dev_certificate", withExtension: "p12")
        // Get entitlements and dev cert from temp directory
        let entitlementsPathInTemp = baseTemp + "entitlements.plist"
        let devCertPathInTemp = baseTemp + "dev_certificate.p12"

        // Read entitlements.plist as dictionary
        var entitlementsDict = NSDictionary(contentsOf: entitlementsPath!) as! [String: Any]
        // Change the value of application-identifier
        entitlementsDict["application-identifier"] = appInfo.CFBundleIdentifier
        entitlementsDict["com.apple.security.application-groups"] = ["group.\(appInfo.CFBundleIdentifier)"]
        entitlementsDict["keychain-access-groups"] = ["\(appInfo.CFBundleIdentifier)"]

        // Write entitlements.plist to temp directory
        let entitlementsData = try PropertyListSerialization.data(fromPropertyList: entitlementsDict, format: .xml, options: 0)
        try entitlementsData.write(to: URL(fileURLWithPath: entitlementsPathInTemp))
        try fileManager.copyItem(atPath: devCertPath!.path, toPath: devCertPathInTemp)

        let task = NSTask()
        // Set task to run ldid
        task.setLaunchPath("/opt/homebrew/bin/ldid")
        // Run ldid -S<path to entitlement> -M -k<path to dev cert> '<path to app>'
        task.arguments = ["-S\(entitlementsPathInTemp)", "-M", "-K\(devCertPathInTemp)", appPath]
        task.waitUntilExit()
        task.launch()
        print("App Signed, signing frameworks")

        // Check if frameworks folder exists
        if fileManager.fileExists(atPath: frameworksPath) {
            // Get all frameworks in frameworks folder
            let frameworks = try fileManager.contentsOfDirectory(atPath: frameworksPath)
            // For each framework
            for framework in frameworks {
                // Get path to framework
                let frameworkPath = frameworksPath + "/" + framework
                // Run ldid -S<path to entitlement> -M -k<path to dev cert> '<path to framework>'
                let task = NSTask()
                task.setLaunchPath("/opt/homebrew/bin/ldid")
                task.arguments = ["-S\(entitlementsPathInTemp)", "-M", "-K\(devCertPathInTemp)", frameworkPath]
                task.waitUntilExit()
                task.launch()
            }
        }

        print("Frameworks signed")
    }

    private func package() throws {
        let dpkgPath = "/opt/procursus/bin/dpkg-deb"
        let task = NSTask()
        task.setLaunchPath(dpkgPath)
        task.arguments = ["-Zxz", "--root-owner-group", "-b", tempWorkingPath, baseTemp + "output.deb"]
        task.waitUntilExit()
        task.launch()
        print("Deb package created")
        print(baseTemp)
    }
}
