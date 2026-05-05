//
//  GoalPersistence.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/4/26.
//

import Foundation

struct GoalPersistence {
    private let fileURL: URL
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        fileURL: URL = Self.defaultFileURL,
        fileManager: FileManager = .default,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.decoder = decoder
        self.encoder = encoder
    }

    func loadGoals() throws -> [Goal] {
        guard fileManager.fileExists(atPath: fileURL.path()) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([Goal].self, from: data)
    }

    func saveGoals(_ goals: [Goal]) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
        )
        let data = try encoder.encode(goals)
        try data.write(to: fileURL, options: [.atomic])
    }

    private static var defaultFileURL: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Goals", directoryHint: .isDirectory)
            .appending(path: "goals.json")
    }
}
