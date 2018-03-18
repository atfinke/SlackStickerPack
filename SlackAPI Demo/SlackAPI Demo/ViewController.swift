//
//  ViewController.swift
//  SlackAPI Demo
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit
import OAuthSwift

struct AuthResponse: Codable {
    let team_name: String
    let team_id: String
}

struct EmojiResponse: Codable {
    let emoji: [String: String]
}

protocol SlackEmoji {
    var name: String { get }
    var url: URL { get }
}

struct RemoteSlackEmoji: SlackEmoji {
    var name: String
    var url: URL

    static func create(from response: EmojiResponse) -> [RemoteSlackEmoji] {
        var emoji = [RemoteSlackEmoji]()
        for emojiName in response.emoji.keys {
            if let emojiURLString = response.emoji[emojiName],
                !emojiURLString.contains("alias:"),
                let emojiURL = URL(string: emojiURLString) {
                emoji.append(RemoteSlackEmoji(name: emojiName, url: emojiURL))
            }
        }
        return emoji
    }
}

struct LocalSlackEmoji: SlackEmoji {
    var name: String
    var url: URL
}

class SlackEmojiManager {

    // MARK: - Properties

    private let auth: OAuth2Swift
    private let decoder = JSONDecoder()

    // MARK: - Initalization

    init() {
        auth = OAuth2Swift(
            consumerKey:    Secrets.key,
            consumerSecret: Secrets.secret,
            authorizeUrl:   "https://slack.com/oauth/authorize",
            accessTokenUrl: "https://slack.com/api/oauth.access",
            responseType:   "token"
        )
    }

    func fetchNewEmoji(from controller: UIViewController) {
        auth.authorizeURLHandler = SafariURLHandler(viewController: controller, oauthSwift: auth)

        auth.authorize(withCallbackURL: "slack-stickers://oauth-callback/ios",
                       scope: "emoji:read",
                       state: "SlackStickers",
                       success: { (_, response, _) in

                        guard let data = response?.data,
                            let authResponse = try? self.decoder.decode(AuthResponse.self, from: data) else {
                                return
                        }

                        self.fetchEmoji(completion: { (emoji) in
                            print(emoji)
                        })
        }) { (error) in
            print(error)
        }
    }

    func fetchEmoji(completion: @escaping (([RemoteSlackEmoji]?) -> Void)) {
        let _ = auth.client.get("https://slack.com/api/emoji.list", success: { response in
            guard let emojiResponse = try? self.decoder.decode(EmojiResponse.self, from: response.data) else {
                completion(nil)
                return
            }
            completion(RemoteSlackEmoji.create(from: emojiResponse))
        }, failure: { (error) in
            completion(nil)
        })
    }

}

class ViewController: UIViewController {



}

