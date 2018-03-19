//
//  MessagesViewController.swift
//  Message
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit
import Messages
import Crashlytics
import SlackEmojiKit

class MessagesViewController: MSMessagesAppViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - Properties

    @IBOutlet weak var collectionView: UICollectionView!
    private let emojiManager = SlackEmojiManager()

    // MARK: - View Life Cycle

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!

        guard let url = Bundle.main.url(forResource: "fabric.apikey", withExtension: nil),
            let key = try? String(contentsOf: url).replacingOccurrences(of: "\n", with: "") else {
                fatalError("Failed to get API keys")
        }
        Crashlytics.start(withAPIKey: key)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        (collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: 20, height: 20)
    }

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        collectionView.reloadData()
        Answers.logCustomEvent(withName: "Messages-willBecomeActive", customAttributes: nil)
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return emojiManager.workspaces.count
    }

     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojiManager.workspaces[section].emojis.count
    }

     func collectionView(_ collectionView: UICollectionView,
                         cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCell.reuseIdentifier,
                                                            for: indexPath) as? StickerCell else {
            fatalError()
        }

        do {
            let emoji = emojiManager.workspaces[indexPath.section].emojis[indexPath.row]
            let sticker = try MSSticker(contentsOfFileURL: emoji.fileURL, localizedDescription: emoji.name)
            cell.stickerView.sticker = sticker
            cell.stickerView.startAnimating()
        } catch {
            fatalError(error.localizedDescription)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        guard let headerCell = collectionView
            .dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                              withReuseIdentifier: HeaderCell.reuseIdentifier,
                                              for: indexPath) as? HeaderCell else {
            fatalError()
        }
        headerCell.label.text = emojiManager.workspaces[indexPath.section].team.teamName

        return headerCell
    }

}
