//
//  SlackEmojiFileManager.swift
//  SlackEmojiKit
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation
import CoreImage
import MobileCoreServices

extension FileManager {
    func contents(of directory: URL) -> [URL] {
        return (try? contentsOfDirectory(at: directory,
                                         includingPropertiesForKeys: nil,
                                         options: .skipsHiddenFiles)) ?? []
    }
}

class SlackEmojiFileManager {

    // MARK: - Properties

    private let documentDirectory: URL
    private let fileManager = FileManager.default

    private var savedEmojiDirectory: URL {
        return documentDirectory.appendingPathComponent("SlackEmoji")
    }

    private var defaults: UserDefaults {
        return UserDefaults(suiteName: "group.com.andrewfinke.test")!
    }

    // MARK: - Initalization

    init() {
        guard let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.andrewfinke.test") else {
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

    func createTeamEmojiDirectory(workspace: WorkspaceResponse) -> (directory: URL, created: Bool) {
        let teamEmojiDirectory = savedEmojiDirectory.appendingPathComponent(workspace.team_id)
        let createdNewTeamDirectory = createDirectory(at: teamEmojiDirectory)

        if !createdNewTeamDirectory {
            fileManager.contents(of: teamEmojiDirectory)
                .forEach { try? fileManager.removeItem(at: $0) }
        }

        return (teamEmojiDirectory, createdNewTeamDirectory)
    }

    // MARK: - Fetch Emojis

    func fetchSavedEmojis() -> [SlackTeamEmojis] {
        guard let existingTeams = defaults.dictionary(forKey: "ExistingTeams") as? [String: String] else {
            return []
        }

        return fileManager.contents(of: savedEmojiDirectory)
            .flatMap { teamDirectory -> SlackTeamEmojis? in
                guard let teamName = existingTeams[teamDirectory.lastPathComponent] else {
                    return nil
                }

                let emojis = fileManager
                    .contents(of: teamDirectory)
                    .map { fileURL -> SlackEmoji in
                        let name = fileURL.lastPathComponent.components(separatedBy: ".")[0]
                        return SlackEmoji(name: name, url: fileURL)
                }
                return SlackTeamEmojis(teamName: teamName, emojis: emojis)
        }
    }

    // MARK: - Save Emojis

    func save(workspaceEmojiResponse: WorkspaceEmojiResponse, completion: @escaping ((SlackFetchEmojiResult) -> Void)) {
        // Set up folder structure - Documents / SlackEmoji / [Team ID]
        createDirectory(at: savedEmojiDirectory)

        let (teamDirectory, created) = createTeamEmojiDirectory(workspace: workspaceEmojiResponse.workspace)

        let downloadQueue = OperationQueue()
        downloadQueue.maxConcurrentOperationCount = 10

        let finalOperation = BlockOperation {
            var existingTeams = self.defaults.dictionary(forKey: "ExistingTeams") as? [String: String] ?? [:]
            existingTeams[workspaceEmojiResponse.workspace.team_id] = workspaceEmojiResponse.workspace.team_name
            self.defaults.set(existingTeams, forKey: "ExistingTeams")

            completion(created ? .new : .reloaded)
        }

        for emojiName in workspaceEmojiResponse.emojiResponse.emoji.keys {
            guard let emojiURLString = workspaceEmojiResponse.emojiResponse.emoji[emojiName],
                !emojiURLString.contains("alias:"),
                let emojiRemoteURL = URL(string: emojiURLString) else {
                    continue
            }

            let operation = WKROperation()
            operation.addExecutionBlock {
                let task = URLSession.shared.dataTask(with: emojiRemoteURL, completionHandler: { (data, _, _) in
                    guard let data = data else {
                        operation.state = .isFinished
                        return
                    }

                    let fileName = emojiName + "." + emojiRemoteURL.pathExtension
                    let emojiLocalURL = teamDirectory.appendingPathComponent(fileName)
                    do {
                        // TODO: Resize
                        try self.process(data: data,
                                         isGIF: emojiRemoteURL.pathExtension == "gif")
                            .write(to: emojiLocalURL)
                    } catch {
                        print("Error saving \(emojiName)")
                    }

                    operation.state = .isFinished
                })
                task.resume()
            }

            finalOperation.addDependency(operation)
            downloadQueue.addOperation(operation)
        }

        downloadQueue.addOperation(finalOperation)
    }

    func process(data: Data, isGIF: Bool) -> Data {
        if isGIF {
            return data
        } else {
            guard let image = CIImage(data: data) else {
                fatalError()
            }

            let filter = CIFilter(name: "CILanczosScaleTransform")!
            filter.setValue(image, forKey: "inputImage")
            filter.setValue(1.25, forKey: "inputScale")
            filter.setValue(1.0, forKey: "inputAspectRatio")

            guard let outputImage = filter.value(forKey: "outputImage") as? CIImage,
                let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) else {
                    fatalError()
            }

            guard let data = CIContext(options: [kCIContextUseSoftwareRenderer: false])
                .pngRepresentation(of: outputImage,
                                   format: kCIFormatRGBA8,
                                   colorSpace:colorSpace,
                                   options: [:]) else {
                                    fatalError()
            }
            return data
        }
    }

}
