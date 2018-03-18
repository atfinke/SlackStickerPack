//
//  WorkspaceResponse.swift
//  SlackEmojiKit
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation

public struct Workspace: Codable, Equatable {

    public let team: Team
    public var emojis: [SlackEmoji]

    //swiftlint:disable:next operator_whitespace
    public static func ==(lhs: Workspace, rhs: Workspace) -> Bool {
        return lhs.team == rhs.team
    }
}
