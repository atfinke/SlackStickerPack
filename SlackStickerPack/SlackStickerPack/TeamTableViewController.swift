//
//  TeamTableViewController.swift
//  SlackStickerPack
//
//  Created by Andrew Finke on 3/18/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit
import Crashlytics
import SlackEmojiKit

class TeamTableViewController: UITableViewController {

    // MARK: - Properties

    private var isDownloading = false
    private let emojiManager = SlackEmojiManager()

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emojiManager.workspaces.count + (isDownloading ? 1 : 0)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == emojiManager.workspaces.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "downloadingIdentifier", for: indexPath)
            cell.textLabel?.text = "Downloading Pack"
            cell.detailTextLabel?.text = nil
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

            let workspace = emojiManager.workspaces[indexPath.row]
            cell.textLabel?.text = workspace.team.teamName

            let emojiCount = workspace.emojis.count
            cell.detailTextLabel?.text = emojiCount.description + " Sticker" + (emojiCount == 1 ? "" : "s")
            return cell
        }
    }

    // MARK: - Table View Editing

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != emojiManager.workspaces.count
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCellEditingStyle,
                            forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            emojiManager.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // MARK: - Adding Packs

    @IBAction func addButtonPressed(_ sender: Any) {
        guard let addButton = sender as? UIBarButtonItem else { fatalError() }
        addButton.isEnabled = false
        Answers.logCustomEvent(withName: "App-addButtonPressed", customAttributes: nil)

        let lastIndex = IndexPath(row: self.emojiManager.workspaces.count, section: 0)
        emojiManager.authenticateAndFetch(from: self, authenticationResult: { result in

            switch result {

            case .success:
                DispatchQueue.main.async {
                    self.isDownloading = true
                    self.tableView.insertRows(at: [lastIndex], with: .top)
                }
                Answers.logCustomEvent(withName: "App-auth-success", customAttributes: nil)
            case .cancelled:
                addButton.isEnabled = true
                Answers.logCustomEvent(withName: "App-auth-cancelled", customAttributes: nil)
            case .error:
                addButton.isEnabled = true
                self.presentError()
                Answers.logCustomEvent(withName: "App-auth-error", customAttributes: nil)
            }

        }, fetchResult: { result in

            DispatchQueue.main.async {
                self.isDownloading = false
                addButton.isEnabled = true

                self.tableView.performBatchUpdates ({
                    switch result {

                    case .new(let index):
                        self.tableView.deleteRows(at: [lastIndex], with: .top)
                        self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .left)
                        Answers.logCustomEvent(withName: "App-fetch-new", customAttributes: nil)
                    case .reloaded(let index):
                        self.tableView.deleteRows(at: [lastIndex], with: .top)
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                        Answers.logCustomEvent(withName: "App-fetch-reloaded", customAttributes: nil)
                    case .error:
                        self.presentError()
                        self.tableView.deleteRows(at: [lastIndex], with: .fade)
                        Answers.logCustomEvent(withName: "App-fetch-success", customAttributes: nil)
                    }

                }, completion: nil)
            }
        })

    }

    private func presentError() {
        DispatchQueue.main.async {
            let title = "Issue Downloading Pack"
            let message = "There was an issue downloading the sticker pack. Please try again later."
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(action)

            self.present(alertController, animated: true, completion: nil)
        }
    }

}
