//
//  ViewController.swift
//  SlackStickerPack
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit
import SlackEmojiKit

class ViewController: UIViewController {

    let emojiManager = SlackEmojiManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.blue

        let te = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        te.text = emojiManager.savedEmojis().description
        view.addSubview(te)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        emojiManager.fetchEmoji(from: self) { (result) in
            print(result)
        }
    }
}

