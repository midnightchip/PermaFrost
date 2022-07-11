//
//  ContentView.swift
//  PermaFrost
//
//  Created by MidnightChips on 7/10/22.
//

import SwiftUI

struct ContentView: View {
    @State private var showDocumentPicker = false
    @State private var fileUrl = ""
    @State private var fileTitle = ""
    @State private var progress = Progress()
    var body: some View {
        VStack {
            // Only show File Title if there is a file selected
            if fileTitle != "" && fileUrl != "" {
                Text(fileTitle)
            }
            if fileUrl == "" {
                Button(action: {
                    showDocumentPicker = true
                }, label: {
                    Text("Select Application")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(Color.white)
                        .cornerRadius(10)

                })
            } else {
                Button(action: {
                    let extractor = Extracter(filePath: fileUrl)
                    do {
                        let appPath = try extractor.extract(progress: progress)
                        print("App path: \(appPath)")
                        let appInfo = try parseAppInfo(from: appPath + "/Info.plist")
						guard appInfo.CFBundleExecutable != nil else {
                            throw UnzipError("CFBundleExecutable not found")
                        }
						try DebCreator(filePath: appPath, appInfo: appInfo).createDeb()
						try extractor.cleanUp()
                    } catch {
                        print(error)
                    }
                }, label: {
                    Text("Install Application").padding()
                        .background(Color.blue)
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                })
                // Progress bar
                ProgressView(progress)
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(fileUrl: $fileUrl, fileTitle: $fileTitle)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
