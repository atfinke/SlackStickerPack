//
//  AppDelegate.swift
//  SlackStickerPack
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit
import Crashlytics
import SlackEmojiKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        guard let url = Bundle.main.url(forResource: "fabric.apikey", withExtension: nil),
            let key = try? String(contentsOf: url).replacingOccurrences(of: "\n", with: "") else {
                fatalError("Failed to get API keys")
        }
        Crashlytics.start(withAPIKey: key)

        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

        if url.host == "oauth-callback" {
            SlackEmojiManager.handle(url: url)
        }
        return true
    }

}
