//
//  Extracter.swift
//  PermaFrost
//
//  Created by MidnightChips on 7/10/22.
//

import Foundation
import ZIPFoundation

struct UnzipError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
}

class Extracter {
    let tempWorkingPath = NSTemporaryDirectory() + "PermaFrost/" + UUID().uuidString + "/"
    private let fileManager = FileManager.default
    private let initialFilePath: String

    init(filePath: String) {
        initialFilePath = filePath
    }

    func extract(progress: Progress?) throws -> String {
        try fileManager.createDirectory(atPath: tempWorkingPath, withIntermediateDirectories: true, attributes: nil)
        // Create sourceUrl
        let sourceUrl = URL(fileURLWithPath: initialFilePath)
        // Create destinationUrl
        let destinationUrl = URL(fileURLWithPath: tempWorkingPath)
        // Unzip
        try fileManager.unzipItem(at: sourceUrl, to: destinationUrl, progress: progress)
        return try validateExtraction()
    }

    func cleanUp() throws {
        try fileManager.removeItem(atPath: tempWorkingPath)
    }

    private func validateExtraction() throws -> String {
        // File folder named "Payload" exists
        let payloadFolder = tempWorkingPath + "Payload/"
        if !fileManager.fileExists(atPath: payloadFolder) {
            throw UnzipError("Payload folder not found")
        }

        // Search all folders in "Payload" for a folder name ending with ".app"
        let enumerator = fileManager.enumerator(atPath: payloadFolder)
        while let element = enumerator?.nextObject() as? String {
            if element.hasSuffix(".app") {
                // Found an app folder
                let appFolder = payloadFolder + element
                // Check if the app folder contains a "Info.plist" file
                if fileManager.fileExists(atPath: appFolder + "/Info.plist") {
                    // Found an app
                    print("Found an app")
                    return appFolder
                }
            }
        }
        throw UnzipError("No app found")
    }
}
