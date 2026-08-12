//
//  DataManager.swift
//  my-collection
//
//  Created by Ma Jade on 2026/8/12.
//

import Foundation
import UIKit

@MainActor
final class DataManager: ObservableObject {

    static let shared = DataManager()

    @Published private(set) var items: [CollectionItem] = []

    private let fileName = "data.json"

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var fileURL: URL {
        documentsURL.appendingPathComponent(fileName)
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        items = load()
    }

    // MARK: - Public API

    func addItem(_ item: CollectionItem) {
        items.append(item)
        save()
    }

    func updateItem(_ item: CollectionItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = item
        updated.modifyDate = Date()
        items[index] = updated
        save()
    }

    func deleteItem(id: String) {
        // Find the item to get its image file name
        if let item = items.first(where: { $0.id == id }) {
            // Delete associated image and thumbnail
            let imageStorage = ImageStorageManager.shared
            imageStorage.deleteImage(withName: item.imageFileName)
        }
        items.removeAll { $0.id == id }
        save()
    }

    // MARK: - Persistence

    private func load() -> [CollectionItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([CollectionItem].self, from: data)
        } catch {
            print("[DataManager] Failed to load data.json: \(error.localizedDescription)")
            return []
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[DataManager] Failed to save data.json: \(error.localizedDescription)")
        }
    }
}
