//
//  EmojiResponse.swift
//  SlackEmojiKit
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation

struct EmojiResponse: Codable {
    let emoji: [String: String]
}
