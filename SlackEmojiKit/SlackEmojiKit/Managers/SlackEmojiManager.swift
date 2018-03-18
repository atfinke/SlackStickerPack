//
//  SlackEmojiManager.swift
//  SlackEmojiKit
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation
import SafariServices
import OAuthSwift

public class SlackEmojiManager {

    // MARK: - Types

    class HandlerDelegate: NSObject, SFSafariViewControllerDelegate {

        var authenticationResult: ((AuthenticationResult) -> Void)?

        // MARK: - SFSafariViewControllerDelegate

        public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            authenticationResult?(.cancelled)
        }
    }

    // MARK: - Properties

    private let auth: OAuth2Swift
    private let decoder = JSONDecoder()

    //swiftlint:disable:next weak_delegate
    private let handlerDelegate = HandlerDelegate()

    private var model: SlackEmojiModel
    private let fileManager = SlackEmojiFileManager()

    public var workspaces: [Workspace] {
        return model.workspaces
    }

    // MARK: - Initalization

    public init() {
        auth = OAuth2Swift(
            consumerKey:    Secrets.key,
            consumerSecret: Secrets.secret,
            authorizeUrl:   "https://slack.com/oauth/authorize",
            accessTokenUrl: "https://slack.com/api/oauth.access",
            responseType:   "token"
        )

        do {
            let modelData = try Data(contentsOf: fileManager.savedModelURL)
            model = SlackEmojiModel(data: modelData)
        } catch {
            model = SlackEmojiModel(data: nil)
        }
    }

    public static func handle(url: URL) {
        OAuthSwift.handle(url: url)
    }

    public func remove(at index: Int) {
        let workspace = model.remove(at: index)
        model.save(to: fileManager.savedModelURL)
        fileManager.remove(team: workspace.team)
    }

    // MARK: - Fetch

    public func authenticateAndFetch(from controller: UIViewController,
                                     authenticationResult: @escaping ((AuthenticationResult) -> Void),
                                     fetchResult: @escaping ((FetchEmojiResult) -> Void)) {

        let handler = SafariURLHandler(viewController: controller, oauthSwift: auth)
        handler.delegate = handlerDelegate
        handlerDelegate.authenticationResult = authenticationResult
        auth.authorizeURLHandler = handler

        auth.authorize(withCallbackURL: "slack-stickers://oauth-callback/ios",
                       scope: "emoji:read",
                       state: "SlackStickers",
                       success: { (_, response, _) in

                        if let data = response?.data, let team = try? self.decoder.decode(Team.self, from: data) {
                            authenticationResult(.success)
                            self.startFetching(team: team, fetchResult: fetchResult)
                        } else {
                            authenticationResult(.error)
                        }
        }) { _ in
            authenticationResult(.error)
        }
    }

    private func startFetching(team: Team, fetchResult: @escaping ((FetchEmojiResult) -> Void)) {
        self.fetchEmojiResponse { emojiResponse in
            guard let emojiResponse = emojiResponse else {
                fetchResult(.error)
                return
            }

            self.fileManager.download(emoji: emojiResponse, for: team) { workspace in
                let result = self.model.update(workspace: workspace)
                self.model.save(to: self.fileManager.savedModelURL)
                fetchResult(result)
            }
        }
    }

    private func fetchEmojiResponse(completion: @escaping ((EmojiResponse?) -> Void)) {
        _ = auth.client.get("https://slack.com/api/emoji.list", success: { response in
            completion(try? self.decoder.decode(EmojiResponse.self, from: response.data))
        }, failure: { _ in
            completion(nil)
        })
    }

}
