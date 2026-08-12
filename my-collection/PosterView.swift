//
//  PosterView.swift
//  my-collection
//
//  海报全屏预览：标题 + 画框图片 + 内容 + 导出操作
//

import SwiftUI
import UIKit

struct PosterView: View {
    
    let image: UIImage
    let title: String
    let content: String
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isRendering = false
    @State private var toastMessage: String?
    @State private var showToast = false
    
    private let goldColor = Color(red: 0.79, green: 0.66, blue: 0.43)
    private let bgColor   = Color(red: 0.96, green: 0.95, blue: 0.92)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                
                ScrollView(.vertical, showsIndicators: false) {
                    posterCard
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                }
                
                bottomBar
            }
            
            if isRendering {
                loadingOverlay
            }
            
            if showToast, let msg = toastMessage {
                toast(msg)
            }
        }
    }
    
    // MARK: - 顶部栏
    
    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text("海报预览").font(.headline).foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - 海报卡片（不用 GeometryReader，避免布局死循环）
    
    private var posterCard: some View {
        VStack(spacing: 0) {
            // 标题
            if !title.isEmpty {
                Text(title)
                    .font(.custom("Georgia-Bold", size: 28))
                    .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
            }
            
            // 图片区
            imageFrame
                .padding(.horizontal, 16)
            
            // 内容
            if !content.isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundColor(Color(red: 0.24, green: 0.24, blue: 0.24))
                    .lineSpacing(6)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .background(bgColor)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
    }
    
    // MARK: - 图片 + 画框
    
    private var imageFrame: some View {
        // 直接用图片自身 aspectRatio，不套 GeometryReader
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.55)
            .background(Color.white)
            .overlay(frameCorners)
    }
    
    // 角标
    private var frameCorners: some View {
        GeometryReader { geo in
            let s = geo.size
            let len: CGFloat = 20
            let lw: CGFloat = 4
            
            Canvas { context, size in
                var path = Path()
                // 左上
                path.move(to: CGPoint(x: 0, y: len))
                path.addLine(to: .zero)
                path.addLine(to: CGPoint(x: len, y: 0))
                // 右上
                path.move(to: CGPoint(x: s.width - len, y: 0))
                path.addLine(to: CGPoint(x: s.width, y: 0))
                path.addLine(to: CGPoint(x: s.width, y: len))
                // 左下
                path.move(to: CGPoint(x: 0, y: s.height - len))
                path.addLine(to: CGPoint(x: 0, y: s.height))
                path.addLine(to: CGPoint(x: len, y: s.height))
                // 右下
                path.move(to: CGPoint(x: s.width - len, y: s.height))
                path.addLine(to: CGPoint(x: s.width, y: s.height))
                path.addLine(to: CGPoint(x: s.width, y: s.height - len))
                
                context.stroke(path, with: .color(goldColor), lineWidth: lw)
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - 底部操作栏
    
    private var bottomBar: some View {
        HStack(spacing: 16) {
            Button { saveToAlbum() } label: {
                Label("保存到相册", systemImage: "photo.on.rectangle")
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Color(.systemGray)).cornerRadius(12)
            }
            Button { shareImage() } label: {
                Label("分享", systemImage: "square.and.arrow.up")
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Color.blue).cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Toast
    
    private func toast(_ msg: String) -> some View {
        VStack {
            Spacer()
            Text(msg)
                .font(.subheadline).foregroundColor(.white)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(Color.black.opacity(0.75))
                .cornerRadius(20)
                .padding(.bottom, 100)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: showToast)
    }
    
    // MARK: - 加载遮罩
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().scaleEffect(1.4).tint(.white)
                Text("正在生成海报…").font(.headline).foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - 渲染 + 导出
    
    private func renderPoster() -> UIImage? {
        let w = UIScreen.main.bounds.width * 2
        let h = w * 4.0 / 3.0
        return ShareManager.shared.renderPoster(
            image: image, title: title, content: content,
            posterSize: CGSize(width: w, height: h)
        )
    }
    
    private func saveToAlbum() {
        isRendering = true
        DispatchQueue.global(qos: .userInitiated).async {
            let poster = renderPoster()
            DispatchQueue.main.async {
                isRendering = false
                guard poster != nil else {
                    showToast("生成失败，请重试"); return
                }
                UIImageWriteToSavedPhotosAlbum(poster!, nil, nil, nil)
                showToast("已保存到相册 ✓")
            }
        }
    }
    
    private func shareImage() {
        isRendering = true
        DispatchQueue.global(qos: .userInitiated).async {
            let poster = renderPoster()
            DispatchQueue.main.async {
                isRendering = false
                guard let poster = poster else {
                    showToast("生成失败，请重试"); return
                }
                ShareManager.shared.shareImage(poster, from: ShareManager.shared.topViewController())
            }
        }
    }
    
    private func showToast(_ msg: String) {
        toastMessage = msg
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showToast = false }
        }
    }
}
