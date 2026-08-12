//
//  ImageStorageManager.swift
//  my-collection
//
//  Created by Ma Jade on 2026/8/12.
//

import UIKit
import Combine

@MainActor
final class ImageStorageManager: ObservableObject {
    
    static let shared = ImageStorageManager()
    
    private let fileManager = FileManager.default
    
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var imagesDirectory: URL {
        documentsURL.appendingPathComponent("Images")
    }
    
    private var thumbnailsDirectory: URL {
        documentsURL.appendingPathComponent("Thumbnails")
    }
    
    private init() {
        createDirectoriesIfNeeded()
    }
    
    // MARK: - 目录管理
    
    private func createDirectoriesIfNeeded() {
        createDirectoryIfNeeded(at: imagesDirectory)
        createDirectoryIfNeeded(at: thumbnailsDirectory)
    }
    
    private func createDirectoryIfNeeded(at url: URL) {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("[ImageStorageManager] 创建目录失败 \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
    
    // MARK: - 单张保存
    
    func saveImage(_ image: UIImage, withName fileName: String) -> Bool {
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else { return false }
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        do {
            try jpegData.write(to: fileURL)
            return true
        } catch {
            print("[ImageStorageManager] 保存图片失败 \(fileName): \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 批量保存（返回成功保存的文件名列表）
    
    func saveImages(_ images: [UIImage]) -> [String] {
        var savedNames: [String] = []
        for image in images {
            let fileName = "\(UUID().uuidString).jpg"
            if saveImage(image, withName: fileName) {
                // 同时生成缩略图
                _ = generateThumbnail(for: image, withName: fileName)
                savedNames.append(fileName)
            }
        }
        return savedNames
    }
    
    // MARK: - 单张加载
    
    func loadImage(withName fileName: String) -> UIImage? {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - 批量加载
    
    func loadImages(withNames fileNames: [String]) -> [UIImage] {
        fileNames.compactMap { loadImage(withName: $0) }
    }
    
    // MARK: - 单张删除
    
    func deleteImage(withName fileName: String) {
        let imageURL = imagesDirectory.appendingPathComponent(fileName)
        let thumbURL = thumbnailsDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: imageURL)
        try? fileManager.removeItem(at: thumbURL)
    }
    
    // MARK: - 批量删除
    
    func deleteImages(_ fileNames: [String]) {
        for name in fileNames {
            deleteImage(withName: name)
        }
    }
    
    // MARK: - 缩略图生成
    
    func generateThumbnail(for image: UIImage, withName fileName: String) -> Bool {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let data = thumbnail.jpegData(compressionQuality: 0.8) else { return false }
        let url = thumbnailsDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - 缩略图加载
    
    func loadThumbnail(withName fileName: String) -> UIImage? {
        let url = thumbnailsDirectory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - 便捷方法
    
    func saveImageAndGenerateThumbnail(_ image: UIImage, withName fileName: String) -> Bool {
        let saved = saveImage(image, withName: fileName)
        guard saved else { return false }
        return generateThumbnail(for: image, withName: fileName)
    }
}
