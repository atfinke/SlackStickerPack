//
//  SlackEmojiFileManager.swift
//  SlackEmojiKit
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation
import CoreImage

class SlackEmojiFileManager {

    // MARK: - Properties

    private let documentDirectory: URL
    private let fileManager = FileManager.default
    private let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])

    private var defaults: UserDefaults {
        return UserDefaults(suiteName: "group.com.andrewfinke.test")!
    }

    internal var savedModelURL: URL {
        return documentDirectory.appendingPathComponent("SlackEmoji.model")
    }

    private var savedEmojiDirectory: URL {
        return documentDirectory.appendingPathComponent("SlackEmoji")
    }

    // MARK: - Initalization

    init() {
        guard let directory = fileManager
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.andrewfinke.SlackStickerPack") else {
            fatalError()
        }
        documentDirectory = directory
    }

    // MARK: - Directory Helpers

    @discardableResult func createDirectory(at url: URL) -> Bool {
        if fileManager.fileExists(atPath: url.path) {
            return false
        } else {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
                return true
            } catch {
                fatalError()
            }
        }
    }

    func createDirectory(for team: Team) -> URL {
        let teamEmojiDirectory = savedEmojiDirectory.appendingPathComponent(team.teamID)
        let createdNewTeamDirectory = createDirectory(at: teamEmojiDirectory)

        if !createdNewTeamDirectory {
            fileManager.contents(of: teamEmojiDirectory)
                .forEach { try? fileManager.removeItem(at: $0) }
        }

        return teamEmojiDirectory
    }

    func remove(team: Team) {
        let directory = savedEmojiDirectory.appendingPathComponent(team.teamID)
        try? fileManager.removeItem(at: directory)
    }

    // MARK: - Save Emojis

    func download(emoji emojiResponse: EmojiResponse, for team: Team, completion: @escaping ((Workspace) -> Void)) {
        // Set up folder structure - Documents / SlackEmoji / [Team ID]
        createDirectory(at: savedEmojiDirectory)
        let workspaceDirectory = createDirectory(for: team)

        var workspaceEmojis = [SlackEmoji?]()
        let downloadQueue = OperationQueue()
        downloadQueue.maxConcurrentOperationCount = 10

        let finalOperation = BlockOperation {
            let emojis = workspaceEmojis.flatMap({ $0 }).sorted(by: { $0.name < $1.name })
            let workspace = Workspace(team: team, emojis: emojis)
            completion(workspace)
        }

        let operations = emojiResponse.emoji.flatMap { (emojiName, emojiRemoteURLString) -> WKROperation? in
            guard !emojiRemoteURLString.contains("alias:"),
                let emojiRemoteURL = URL(string: emojiRemoteURLString) else { return nil }

            let operation = WKROperation()
            operation.addExecutionBlock {
                let task = URLSession.shared.dataTask(with: emojiRemoteURL, completionHandler: { (data, _, _) in
                    let fileName = emojiName + "." + emojiRemoteURL.pathExtension
                    let emojiLocalURL = workspaceDirectory.appendingPathComponent(fileName)

                    let emoji = self.saveEmoji(with: data, named: fileName, to: emojiLocalURL, from: emojiRemoteURL)
                    workspaceEmojis.append(emoji)
                    operation.state = .isFinished
                })
                task.resume()
            }

            finalOperation.addDependency(operation)
            return operation
        }

        downloadQueue.addOperations(operations, waitUntilFinished: false)
        downloadQueue.addOperation(finalOperation)
    }

    private func saveEmoji(with emojiData: Data?,
                           named name: String,
                           to localURL: URL,
                           from sourceURL: URL) -> SlackEmoji? {

        guard let data = emojiData else { return nil }
        do {
            let resizedImage =  self.process(data: data, isGIF: sourceURL.pathExtension == "gif")
            try resizedImage.write(to: localURL)
            return SlackEmoji(name: name, fileURL: localURL)
        } catch {
            print("Error saving \(name)")
            return nil
        }
    }

    private func process(data: Data, isGIF: Bool) -> Data {
        if isGIF {
//            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
//                let sourceProperties = CGImageSourceCopyProperties(source, nil) else {
//                fatalError()
//            }
//
//            let frameCount = CGImageSourceGetCount(source)
//            let data = NSMutableData()
//
//            guard let destination =  CGImageDestinationCreateWithData(data as CFMutableData,
//                                                                      kUTTypeGIF,
//                                                                      frameCount,
//                                                                      nil) else {
//                    fatalError()
//            }
//            CGImageDestinationSetProperties(destination, sourceProperties)
//
//            for imageIndex in 0..<frameCount {
//
//                guard let frameImage = CGImageSourceCreateImageAtIndex(source, imageIndex, nil),
//                    var frameProperties = ... as? [String: Any] else {
//                        continue
//                }
//
//                let image = CIImage(cgImage: frameImage)
//                scaleFilter.setValue(image, forKey: "inputImage")
//                guard let outputImage = scaleFilter.value(forKey: "outputImage") as? CIImage,
//                    let newImage = context.createCGImage(outputImage, from: outputImage.extent ) else {
//                    fatalError()
//                }
//
//                frameProperties["PixelWidth"] = newImage.width
//                frameProperties["PixelHeight"] = newImage.height
//                frameProperties[kCGImageDestinationLossyCompressionQuality as String] = 0.0
//
//                CGImageDestinationAddImage(destination, newImage, frameProperties as CFDictionary)
//            }
//
//            guard CGImageDestinationFinalize(destination) else {
//                fatalError()
//            }

            return data as Data
        } else {
            guard let image = CIImage(data: data) else {
                fatalError()
            }

            let filter = CIFilter(name: "CILanczosScaleTransform")!
            filter.setValue(2.0, forKey: "inputScale")
            filter.setValue(1.0, forKey: "inputAspectRatio")
            filter.setValue(image, forKey: "inputImage")

            guard let outputImage = filter.value(forKey: "outputImage") as? CIImage,
                let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) else {
                    fatalError()
            }

            guard let data = context.pngRepresentation(of: outputImage,
                                                       format: kCIFormatRGBA8,
                                                       colorSpace: colorSpace,
                                                       options: [:]) else {
                                                        fatalError()
            }
            return data
        }
    }

}

extension FileManager {
    func contents(of directory: URL) -> [URL] {
        return (try? contentsOfDirectory(at: directory,
                                         includingPropertiesForKeys: nil,
                                         options: .skipsHiddenFiles)) ?? []
    }
}
