//
//  SlackEmoji.swift
//  SlackEmojiKit
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation

public struct SlackEmoji {
    public let name: String
    public let url: URL
}

public struct SlackTeamEmojis {
    public let teamName: String
    public let emojis: [SlackEmoji]
}
