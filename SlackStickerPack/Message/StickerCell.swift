//
//  StickerCell.swift
//  SlackStickerPack
//
//  Created by Andrew Finke on 3/19/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit
import Messages

class StickerCell: UICollectionViewCell {

    static let reuseIdentifier = "reuseIdentifier"

    @IBOutlet weak var stickerView: MSStickerView!
}
