//
//  DataManager.swift
//  my-collection
//
//  Created by Ma Jade on 2026/8/12.
//

import Foundation
import Combine
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

    // MARK: - 添加藏品

    func addItem(_ item: CollectionItem) {
        items.append(item)
        save()
    }

    // MARK: - 更新藏品

    func updateItem(_ item: CollectionItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = item
        updated.modifyDate = Date()
        items[index] = updated
        save()
    }

    // MARK: - 删除藏品（含图片文件清理）

    func deleteItem(id: String) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        // 先删图片文件
        ImageStorageManager.shared.deleteImages(item.imageFileNames)
        // 再删记录
        items.removeAll { $0.id == id }
        save()
    }

    // MARK: - 按 ID 获取

    func getItem(by id: String) -> CollectionItem? {
        items.first { $0.id == id }
    }

    // MARK: - 持久化

    private func load() -> [CollectionItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([CollectionItem].self, from: data)
        } catch {
            print("[DataManager] 加载失败: \(error.localizedDescription)")
            return []
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[DataManager] 保存失败: \(error.localizedDescription)")
        }
    }
}
