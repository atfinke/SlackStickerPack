//
//  SlackEmojiModel.swift
//  SlackEmojiKit
//
//  Created by Andrew Finke on 3/18/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation

struct SlackEmojiModel: Codable {

    private(set) var workspaces = [Workspace]()

    init(data: Data?) {
        if let data = data {
            do {
                self = try JSONDecoder().decode(SlackEmojiModel.self, from: data)
            } catch {
                print("Failed to init model from existing data")
            }
        } else {
            print("Failed to init model, no existing data")
        }
    }

    mutating func update(workspace: Workspace) -> FetchEmojiResult {
        if let existingWorkspaceIndex = workspaces.index(where: { $0 == workspace }) {
            workspaces[existingWorkspaceIndex] = workspace
            return .reloaded(index: existingWorkspaceIndex)
        } else {
            workspaces.append(workspace)
            workspaces.sort(by: { (lhs, rhs) -> Bool in
                return lhs.team.teamName < rhs.team.teamName
            })
            guard let index = workspaces.index(of: workspace) else {
                fatalError()
            }
            return .new(index: index)
        }
    }

    mutating func remove(at index: Int) -> Workspace {
        return workspaces.remove(at: index)
    }

    func save(to url: URL) {
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: url)
        } catch {
            print("Failed to save model")
        }
    }

}
