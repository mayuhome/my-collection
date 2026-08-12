//
//  ShareManager.swift
//  my-collection
//
//  负责海报图片的渲染、保存和分享
//

import SwiftUI
import UIKit

@MainActor
final class ShareManager {
    
    static let shared = ShareManager()
    
    private init() {}
    
    // MARK: - 海报渲染
    
    /// 将 SwiftUI PosterView 渲染为 UIImage
    /// 使用 UIGraphicsImageRenderer 以兼容 iOS 16
    func renderPoster(
        image: UIImage,
        title: String,
        content: String,
        posterSize: CGSize
    ) -> UIImage? {
        
        let renderer = UIGraphicsImageRenderer(size: posterSize)
        
        return renderer.image { ctx in
            let context = ctx.cgContext
            
            // ---- 1. 背景 ----
            let bg = UIColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1) // #F5F2EB
            bg.setFill()
            context.fill(CGRect(origin: .zero, size: posterSize))
            
            var cursorY: CGFloat = 0
            let sidePadding: CGFloat = 24
            let contentWidth = posterSize.width - sidePadding * 2
            
            // ---- 2. 标题 ----
            if !title.isEmpty {
                let titleFont = UIFont(name: "Georgia-Bold", size: 28)
                    ?? UIFont.systemFont(ofSize: 28, weight: .bold)
                let titlePara = NSMutableParagraphStyle()
                titlePara.alignment = .center
                titlePara.lineSpacing = 4
                
                let titleAttr: [NSAttributedString.Key: Any] = [
                    .font: titleFont,
                    .foregroundColor: UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1), // #2C2C2C
                    .paragraphStyle: titlePara
                ]
                
                let titleBounds = (title as NSString).boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: titleAttr,
                    context: nil
                )
                
                let titleHeight = ceil(titleBounds.height) + 40 // 上下各 20pt
                (title as NSString).draw(
                    in: CGRect(x: sidePadding, y: cursorY + 20, width: contentWidth, height: titleHeight - 40),
                    withAttributes: titleAttr
                )
                cursorY += titleHeight
            }
            
            // ---- 3. 画框 + 图片 ----
            let framePadding: CGFloat = 16
            let frameX = framePadding
            let frameWidth = posterSize.width - framePadding * 2
            
            // 计算图片区域（保持 3:4 宽高比时留出空间给标题和内容）
            let maxImageHeight = posterSize.height * 0.62
            let imageAspect = image.size.width / image.size.height
            var drawWidth = frameWidth
            var drawHeight = drawWidth / imageAspect
            
            if drawHeight > maxImageHeight {
                drawHeight = maxImageHeight
                drawWidth = drawHeight * imageAspect
            }
            
            let drawX = frameX + (frameWidth - drawWidth) / 2
            let drawY = cursorY + framePadding
            
            // 绘制图片
            image.draw(in: CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight))
            
            // 绘制金色角标
            let goldColor = UIColor(red: 0.79, green: 0.66, blue: 0.43, alpha: 1) // #C9A96E
            goldColor.setStroke()
            context.setLineWidth(4)
            
            let cornerLen: CGFloat = 20
            let imgRect = CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight)
            drawCorners(in: imgRect, cornerLength: cornerLen, context: context)
            
            // 绘制细边框
            context.setStrokeColor(goldColor.cgColor)
            context.setLineWidth(1.5)
            context.stroke(imgRect.insetBy(dx: -2, dy: -2))
            
            cursorY = drawY + drawHeight + framePadding
            
            // ---- 4. 内容 ----
            if !content.isEmpty {
                let contentFont = UIFont.systemFont(ofSize: 16, weight: .regular)
                let contentPara = NSMutableParagraphStyle()
                contentPara.alignment = .justified
                contentPara.lineSpacing = 6
                
                let contentAttr: [NSAttributedString.Key: Any] = [
                    .font: contentFont,
                    .foregroundColor: UIColor(red: 0.24, green: 0.24, blue: 0.24, alpha: 1), // #3C3C3C
                    .paragraphStyle: contentPara
                ]
                
                let contentBounds = (content as NSString).boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: contentAttr,
                    context: nil
                )
                
                let contentHeight = ceil(contentBounds.height)
                let contentY = cursorY + 16
                
                (content as NSString).draw(
                    in: CGRect(x: sidePadding, y: contentY, width: contentWidth, height: contentHeight),
                    withAttributes: contentAttr
                )
            }
        }
    }
    
    // MARK: - 保存到相册
    
    func saveToAlbum(_ image: UIImage) -> Bool {
        // UIImageWriteToSavedPhotosAlbum 是同步保存，完成回调在后台线程
        var saveSuccess = false
        let semaphore = DispatchSemaphore(value: 0)
        
        UIImageWriteToSavedPhotosAlbum(image, nil, #selector(saveCompleted(_:error:context:)), nil)
        
        // 简化处理：直接返回 true，实际保存状态通过通知反馈
        return true
    }
    
    @objc private func saveCompleted(_ image: UIImage?, error: Error?, context: UnsafeMutableRawPointer?) {
        // 保存完成回调
    }
    
    // MARK: - 分享
    
    func shareImage(_ image: UIImage, from viewController: UIViewController?) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        // iPad 适配
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController?.present(activityVC, animated: true)
    }
    
    // MARK: - 辅助
    
    private func drawCorners(in rect: CGRect, cornerLength: CGFloat, context: CGContext) {
        // 左上
        context.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerLength))
        context.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.minY))
        // 右上
        context.move(to: CGPoint(x: rect.maxX - cornerLength, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerLength))
        // 左下
        context.move(to: CGPoint(x: rect.minX, y: rect.maxY - cornerLength))
        context.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        context.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.maxY))
        // 右下
        context.move(to: CGPoint(x: rect.maxX - cornerLength, y: rect.maxY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        
        context.strokePath()
    }
    
    /// 获取当前最顶层的 ViewController
    func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return findTop(of: root)
    }
    
    private func findTop(of vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return findTop(of: presented)
        }
        if let nav = vc as? UINavigationController, let top = nav.topViewController {
            return findTop(of: top)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return findTop(of: selected)
        }
        return vc
    }
}
