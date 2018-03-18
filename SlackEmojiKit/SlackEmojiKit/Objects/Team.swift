//
//  Team.swift
//  SlackEmojiKit
//
//  Created by Andrew Finke on 3/18/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation

public struct Team: Codable, Equatable {

    public let teamID: String
    public let teamName: String

    private enum CodingKeys: String, CodingKey {
        case teamID = "team_id", teamName = "team_name"
    }

    //swiftlint:disable:next operator_whitespace
    public static func ==(lhs: Team, rhs: Team) -> Bool {
        return lhs.teamID == rhs.teamID
    }
}
