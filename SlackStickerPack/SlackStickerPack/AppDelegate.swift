//
//  AppDelegate.swift
//  SlackStickerPack
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit
import SlackEmojiKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if (url.host == "oauth-callback") {
            SlackEmojiManager.handle(url: url)
        }
        return true
    }

}

