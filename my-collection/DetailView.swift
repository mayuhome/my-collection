//
//  DetailView.swift
//  my-collection
//
//  全屏大图查看：左右滑动切换 + 编辑 + 横竖屏 + 分享
//

import SwiftUI
import UIKit

// MARK: - 图片条目（关联到所属藏品）

private struct ImageEntry: Identifiable {
    let id = UUID()
    let itemIndex: Int      // 在 dataManager.items 中的下标
    let fileName: String
}

struct DetailView: View {
    
    let startIndex: Int         // 藏品下标（外部传入）
    
    @ObservedObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentIndex: Int        // 在 allImages 中的下标
    @State private var loadedImages: [String: UIImage] = [:]
    
    // 编辑
    @State private var showEditSheet = false
    
    // 分享
    @State private var showShareSheet = false
    @State private var posterTitle = ""
    @State private var posterContent = ""
    @State private var showPoster = false
    @State private var posterImage: UIImage?
    
    init(startIndex: Int) {
        self.startIndex = startIndex
        // 计算该藏品第一张图在 allImages 中的位置
        let items = DataManager.shared.items
        var offset = 0
        for i in 0..<startIndex {
            offset += items[i].imageFileNames.count
        }
        _currentIndex = State(initialValue: offset)
    }
    
    private var items: [CollectionItem] { dataManager.items }
    
    /// 所有图片平铺列表
    private var allImages: [ImageEntry] {
        items.enumerated().flatMap { idx, item in
            item.imageFileNames.map { ImageEntry(itemIndex: idx, fileName: $0) }
        }
    }
    
    /// 当前图片所属藏品下标
    private var currentItemIndex: Int {
        guard currentIndex >= 0, currentIndex < allImages.count else { return 0 }
        return allImages[currentIndex].itemIndex
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if allImages.isEmpty {
                emptyState
            } else {
                // 图片幻灯片（按单张图片翻页）
                TabView(selection: $currentIndex) {
                    ForEach(Array(allImages.enumerated()), id: \.element.id) { idx, entry in
                        ZoomableImage(image: loadedImages[entry.fileName])
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // UI 浮层
                VStack { topBar; Spacer(); bottomBar }
            }
        }
        .onAppear { preloadImages() }
        .onChange(of: currentIndex) { _ in loadImage(for: currentIndex) }
        .sheet(isPresented: $showShareSheet) {
            ShareEditSheet(
                titleText: $posterTitle,
                contentText: $posterContent,
                onCancel: { showShareSheet = false },
                onPreview: {
                    showShareSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { preparePoster() }
                }
            )
        }
        .fullScreenCover(isPresented: $showPoster) {
            PosterView(
                image: posterImage ?? UIImage(),
                title: posterTitle,
                content: posterContent
            )
        }
    }
    
    // MARK: - 空状态
    
    private var emptyState: some View {
        Color.black.ignoresSafeArea()
            .onAppear { dismiss() }
    }
    
    // MARK: - 顶部栏
    
    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: "chevron.left").font(.caption2)
                Text("左右滑动切换").font(.caption2)
                Image(systemName: "chevron.right").font(.caption2)
            }
            .foregroundColor(.white.opacity(0.5))
            
            Spacer()
            
            HStack(spacing: 12) {
                // 编辑按钮
                Button { showEditSheet = true } label: {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                
                // 页码
                Text("\(currentIndex + 1)/\(allImages.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .background(
            LinearGradient(colors: [.black.opacity(0.5), .clear],
                           startPoint: .top, endPoint: .bottom)
        )
        .sheet(isPresented: $showEditSheet) {
            if let item = items[safe: currentItemIndex] {
                EditItemView(item: item)
            }
        }
    }
    
    // MARK: - 底部栏
    
    private var bottomBar: some View {
        HStack {
            if let name = items[safe: currentItemIndex]?.name, !name.isEmpty {
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button { toggleOrientation() } label: {
                Image(systemName: "rotate.right")
                    .font(.title3).foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Button { showShareSheet = true } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3).foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20).padding(.bottom, 30)
        .background(
            LinearGradient(colors: [.clear, .black.opacity(0.5)],
                           startPoint: .top, endPoint: .bottom)
        )
    }
    
    // MARK: - 图片加载
    
    private func preloadImages() {
        for offset in -1...1 {
            let idx = currentIndex + offset
            guard idx >= 0, idx < allImages.count else { continue }
            loadImage(for: idx)
        }
    }
    
    private func loadImage(for index: Int) {
        guard index >= 0, index < allImages.count else { return }
        let fileName = allImages[index].fileName
        guard loadedImages[fileName] == nil else { return }
        Task { @MainActor in
            loadedImages[fileName] = ImageStorageManager.shared.loadImage(withName: fileName)
        }
    }
    
    // MARK: - 横竖屏
    
    private func toggleOrientation() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let target: UIInterfaceOrientationMask = (scene.interfaceOrientation == .portrait) ? .landscape : .portrait
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: target))
    }
    
    // MARK: - 海报
    
    private func preparePoster() {
        guard currentIndex >= 0, currentIndex < allImages.count else { return }
        let fileName = allImages[currentIndex].fileName
        let img = loadedImages[fileName] ?? ImageStorageManager.shared.loadImage(withName: fileName)
        guard let img = img else { return }
        loadedImages[fileName] = img
        posterImage = img
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            showPoster = true
        }
    }
}

// MARK: - 安全下标

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 可缩放图片

struct ZoomableImage: View {
    let image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(mag)
                    .simultaneousGesture(scale > 1.01 ? drag : nil)
                    .onTapGesture(count: 2) { reset() }
            } else {
                ProgressView().tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var mag: some Gesture {
        MagnificationGesture()
            .onChanged { v in
                let d = v / lastScale; lastScale = v
                scale = min(max(scale * d, 1), 4)
            }
            .onEnded { _ in
                lastScale = 1
                if scale < 1 { withAnimation(.spring()) { scale = 1 } }
                if scale <= 1.01 { withAnimation(.spring()) { offset = .zero } }
            }
    }
    
    private var drag: some Gesture {
        DragGesture()
            .onChanged { v in
                offset = CGSize(width: lastOffset.width + v.translation.width,
                                height: lastOffset.height + v.translation.height)
            }
            .onEnded { _ in
                lastOffset = offset
                if scale <= 1.01 {
                    withAnimation(.spring()) { offset = .zero; lastOffset = .zero }
                }
            }
    }
    
    private func reset() {
        withAnimation(.spring()) { scale = 1; offset = .zero; lastOffset = .zero }
    }
}

// MARK: - 分享编辑 Sheet

struct ShareEditSheet: View {
    @Binding var titleText: String
    @Binding var contentText: String
    let onCancel: () -> Void
    let onPreview: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("标题（选填）").font(.subheadline).foregroundColor(.secondary)
                            Spacer()
                            Text("\(titleText.count)/20").font(.caption)
                                .foregroundColor(titleText.count >= 20 ? .red : .secondary)
                        }
                        TextField("如：清乾隆青花缠枝莲纹瓶", text: $titleText)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: titleText) { v in
                                if v.count > 20 { titleText = String(v.prefix(20)) }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("内容（选填）").font(.subheadline).foregroundColor(.secondary)
                            Spacer()
                            Text("\(contentText.count)/200").font(.caption)
                                .foregroundColor(contentText.count >= 200 ? .red : .secondary)
                        }
                        ZStack(alignment: .topLeading) {
                            if contentText.isEmpty {
                                Text("输入藏品的介绍、故事、来源等…")
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.horizontal, 4).padding(.vertical, 8)
                            }
                            TextEditor(text: $contentText)
                                .frame(minHeight: 150)
                                .scrollContentBackground(.hidden)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .onChange(of: contentText) { v in
                                    if v.count > 200 { contentText = String(v.prefix(200)) }
                                }
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    HStack(spacing: 16) {
                        Button { onCancel() } label: {
                            Text("取消").font(.headline).foregroundColor(.secondary)
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(Color(.systemGray5)).cornerRadius(12)
                        }
                        Button { onPreview() } label: {
                            Label("预览海报", systemImage: "photo.on.rectangle.angled")
                                .font(.headline).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(Color.blue).cornerRadius(12)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("生成藏品海报")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
