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
    
    // MARK: - Directory Management
    
    private func createDirectoriesIfNeeded() {
        createDirectoryIfNeeded(at: imagesDirectory)
        createDirectoryIfNeeded(at: thumbnailsDirectory)
    }
    
    private func createDirectoryIfNeeded(at url: URL) {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("[ImageStorageManager] Failed to create directory \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Image Saving
    
    func saveImage(_ image: UIImage, withName fileName: String) -> Bool {
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            print("[ImageStorageManager] Failed to convert image to JPEG data")
            return false
        }
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        do {
            try jpegData.write(to: fileURL)
            return true
        } catch {
            print("[ImageStorageManager] Failed to save image \(fileName): \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Image Loading
    
    func loadImage(withName fileName: String) -> UIImage? {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("[ImageStorageManager] Image file not found: \(fileName)")
            return nil
        }
        guard let data = try? Data(contentsOf: fileURL) else {
            print("[ImageStorageManager] Failed to load image data for \(fileName)")
            return nil
        }
        return UIImage(data: data)
    }
    
    // MARK: - Image Deletion
    
    func deleteImage(withName fileName: String) -> Bool {
        let imageFileURL = imagesDirectory.appendingPathComponent(fileName)
        let thumbnailFileURL = thumbnailsDirectory.appendingPathComponent(fileName)
        var success = true
        
        // Delete original image
        if fileManager.fileExists(atPath: imageFileURL.path) {
            do {
                try fileManager.removeItem(at: imageFileURL)
            } catch {
                print("[ImageStorageManager] Failed to delete image \(fileName): \(error.localizedDescription)")
                success = false
            }
        }
        
        // Delete thumbnail
        if fileManager.fileExists(atPath: thumbnailFileURL.path) {
            do {
                try fileManager.removeItem(at: thumbnailFileURL)
            } catch {
                print("[ImageStorageManager] Failed to delete thumbnail \(fileName): \(error.localizedDescription)")
                success = false
            }
        }
        
        return success
    }
    
    // MARK: - Thumbnail Generation
    
    func generateThumbnail(for image: UIImage, withName fileName: String) -> Bool {
        let thumbnailSize = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        }
        guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8) else {
            print("[ImageStorageManager] Failed to convert thumbnail to JPEG data")
            return false
        }
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(fileName)
        do {
            try thumbnailData.write(to: thumbnailURL)
            return true
        } catch {
            print("[ImageStorageManager] Failed to save thumbnail \(fileName): \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Thumbnail Loading
    
    func loadThumbnail(withName fileName: String) -> UIImage? {
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: thumbnailURL.path) else {
            print("[ImageStorageManager] Thumbnail not found: \(fileName)")
            return nil
        }
        guard let data = try? Data(contentsOf: thumbnailURL) else {
            print("[ImageStorageManager] Failed to load thumbnail data for \(fileName)")
            return nil
        }
        return UIImage(data: data)
    }
    
    // MARK: - Convenience Methods
    
    func saveImageAndGenerateThumbnail(_ image: UIImage, withName fileName: String) -> Bool {
        let saved = saveImage(image, withName: fileName)
        guard saved else { return false }
        return generateThumbnail(for: image, withName: fileName)
    }
}
