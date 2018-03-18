//
//  WorkspaceResponse.swift
//  SlackEmojiKit
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation

struct WorkspaceResponse: Codable {
    let team_name: String
    let team_id: String
}

struct WorkspaceEmojiResponse {
    let workspace: WorkspaceResponse
    let emojiResponse: EmojiResponse
}
