//
//  Results.swift
//  SlackEmojiKit
//
//  Created by Andrew Finke on 3/18/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation

public enum FetchEmojiResult {
    case new(index: Int)
    case reloaded(index: Int)
    case error
}

public enum AuthenticationResult {
    case success
    case cancelled
    case error
}
