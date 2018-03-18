//
//  SlackEmojiManager.swift
//  SlackEmojiKit
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation
import OAuthSwift

public enum SlackFetchEmojiResult {
    case new
    case reloaded
    case error
}

public class SlackEmojiManager {

    // MARK: - Properties

    private let auth: OAuth2Swift
    private let decoder = JSONDecoder()
    private let fileManager = SlackEmojiFileManager()

    // MARK: - Initalization

    public init() {
        auth = OAuth2Swift(
            consumerKey:    Secrets.key,
            consumerSecret: Secrets.secret,
            authorizeUrl:   "https://slack.com/oauth/authorize",
            accessTokenUrl: "https://slack.com/api/oauth.access",
            responseType:   "token"
        )
    }

    public static func handle(url: URL) {
        OAuthSwift.handle(url: url)
    }

    public func savedEmojis() -> [SlackTeamEmojis] {
        return fileManager.fetchSavedEmojis()
    }

    // MARK: - Fetch

    public func fetchEmoji(from controller: UIViewController, completion: @escaping ((SlackFetchEmojiResult) -> Void)) {
        print(#function)
        auth.authorizeURLHandler = SafariURLHandler(viewController: controller, oauthSwift: auth)

        auth.authorize(withCallbackURL: "slack-stickers://oauth-callback/ios",
                       scope: "emoji:read",
                       state: "SlackStickers",
                       success: { (_, response, _) in
                        self.authenticated(response: response, completion: completion)
        }) { (error) in
            completion(.error)
        }
    }

    private func authenticated(response: OAuthSwiftResponse?, completion: @escaping ((SlackFetchEmojiResult) -> Void)) {
        print(#function)
        guard let data = response?.data,
            let workspaceResponse = try? self.decoder.decode(WorkspaceResponse.self, from: data) else {
                completion(.error)
                return
        }

        self.fetchEmoji(completion: { (emojiResponse) in
            if let emojiResponse = emojiResponse {
                let workspaceEmojiResponse = WorkspaceEmojiResponse(workspace: workspaceResponse,
                                                                    emojiResponse: emojiResponse)

                self.fileManager.save(workspaceEmojiResponse: workspaceEmojiResponse,
                                      completion: completion)
            } else {
                completion(.error)
            }
        })
    }

    private func fetchEmoji(completion: @escaping ((EmojiResponse?) -> Void)) {
        print(#function)
        let _ = auth.client.get("https://slack.com/api/emoji.list", success: { response in
            completion(try? self.decoder.decode(EmojiResponse.self, from: response.data))
        }, failure: { (error) in
            completion(nil)
        })
    }

}
