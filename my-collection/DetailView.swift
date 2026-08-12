//
//  DetailView.swift
//  my-collection
//
//  Created by Ma Jade on 2026/8/12.
//

import SwiftUI
import UIKit

struct DetailView: View {
    // MARK: - 属性
    
    let initialItem: CollectionItem
    let initialIndex: Int
    
    @ObservedObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // 当前显示的索引
    @State private var currentIndex: Int
    
    // 详情卡片状态
    @State private var showDetailCard = false
    @State private var dragOffset: CGFloat = 0
    
    // 删除状态
    @State private var isDeleting = false
    @State private var deletedIndex: Int? = nil
    @State private var showUndoBanner = false
    @State private var undoTimer: Timer? = nil
    @State private var undoCountdown = 5
    
    // 图片缓存
    @State private var loadedImages: [String: UIImage] = [:]
    
    // MARK: - 初始化
    
    init(item: CollectionItem, index: Int) {
        self.initialItem = item
        self.initialIndex = index
        _currentIndex = State(initialValue: index)
    }
    
    // MARK: - 计算属性
    
    /// 当前藏品
    private var currentItem: CollectionItem? {
        guard currentIndex >= 0 && currentIndex < dataManager.items.count else {
            return nil
        }
        return dataManager.items[currentIndex]
    }
    
    /// 总数量
    private var totalCount: Int {
        dataManager.items.count
    }
    
    /// 是否有上一张
    private var hasPrevious: Bool {
        currentIndex > 0
    }
    
    /// 是否有下一张
    private var hasNext: Bool {
        currentIndex < totalCount - 1
    }
    
    // MARK: - 主视图
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()
            
            // 主内容
            VStack(spacing: 0) {
                // 顶部导航栏
                topNavBar
                
                // 图片展示区
                imageGallery
                
                // 底部提示条
                bottomHint
            }
            
            // 详情卡片（从底部滑出）
            detailCard
            
            // 撤销横幅
            undoBanner
        }
        .navigationBarHidden(true)
        .onAppear {
            loadInitialImage()
        }
        .onChange(of: currentIndex) { newIndex in
            loadImageForIndex(newIndex)
        }
    }
    
    // MARK: - 顶部导航栏
    
    private var topNavBar: some View {
        HStack {
            // 返回按钮
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
            }
            
            Spacer()
            
            // 当前位置指示器
            Text("\(currentIndex + 1) / \(totalCount)")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            // 占位，保持对称
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(.clear)
                .padding(12)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - 图片画廊
    
    private var imageGallery: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(dataManager.items.enumerated()), id: \.element.id) { index, item in
                ZoomableImageView(
                    image: loadedImages[item.imageFileName],
                    isLoading: loadedImages[item.imageFileName] == nil
                )
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .opacity(isDeleting && deletedIndex == currentIndex ? 0.5 : 1.0)
        .animation(.default, value: isDeleting)
    }
    
    // MARK: - 底部提示条
    
    private var bottomHint: some View {
        VStack(spacing: 8) {
            // 拖拽手柄
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.white.opacity(0.5))
                .frame(width: 40, height: 5)
            
            Text("轻轻上拉查看详情")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .gesture(
            DragGesture()
                .onChanged { value in
                    let translation = value.translation.height
                    if translation < 0 {
                        dragOffset = max(translation, -300)
                    }
                }
                .onEnded { value in
                    if value.translation.height < -50 {
                        withAnimation(.spring()) {
                            showDetailCard = true
                            dragOffset = 0
                        }
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .offset(y: dragOffset)
    }
    
    // MARK: - 详情卡片
    
    private var detailCard: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // 拖拽手柄
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height > 0 {
                                    dragOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                if value.translation.height > 50 {
                                    withAnimation(.spring()) {
                                        showDetailCard = false
                                        dragOffset = 0
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                
                // 详情内容
                if let item = currentItem {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // 名称
                            if let name = item.name, !name.isEmpty {
                                Text(name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            // 分类标签
                            if let categories = item.category, !categories.isEmpty {
                                FlowLayout(spacing: 8) {
                                    ForEach(categories, id: \.self) { category in
                                        Text(category)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            
                            // 详细信息
                            Group {
                                if let price = item.price, !price.isEmpty {
                                    DetailRow(title: "价格", value: "¥\(price)", icon: "yensign.circle")
                                }
                                
                                if let source = item.source, !source.isEmpty {
                                    DetailRow(title: "来源", value: source, icon: "gift")
                                }
                                
                                if let location = item.location, !location.isEmpty {
                                    DetailRow(title: "位置", value: location, icon: "location")
                                }
                            }
                            
                            // 删除按钮
                            Button {
                                startDeleteProcess()
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("删除此藏品")
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .padding(.top, 20)
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(color: .black.opacity(0.2), radius: 10, y: -5)
            .offset(y: showDetailCard ? 0 : UIScreen.main.bounds.height * 0.6)
            .animation(.spring(), value: showDetailCard)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - 撤销横幅
    
    private var undoBanner: some View {
        VStack {
            Spacer()
            
            if showUndoBanner {
                HStack {
                    Text("已删除，点击撤销")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        undoDelete()
                    } label: {
                        Text("撤销 (\(undoCountdown))")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.9))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: showUndoBanner)
            }
        }
    }
    
    // MARK: - 图片加载
    
    private func loadInitialImage() {
        loadImageForIndex(initialIndex)
    }
    
    private func loadImageForIndex(_ index: Int) {
        guard index >= 0 && index < dataManager.items.count else { return }
        let item = dataManager.items[index]
        
        guard loadedImages[item.imageFileName] == nil else { return }
        
        Task { @MainActor in
            if let image = ImageStorageManager.shared.loadImage(withName: item.imageFileName) {
                loadedImages[item.imageFileName] = image
            }
        }
    }
    
    // MARK: - 删除功能
    
    private func startDeleteProcess() {
        guard let item = currentItem else { return }
        
        // 关闭详情卡片
        withAnimation(.spring()) {
            showDetailCard = false
        }
        
        // 设置删除状态
        isDeleting = true
        deletedIndex = currentIndex
        
        // 显示撤销横幅
        withAnimation {
            showUndoBanner = true
        }
        
        // 开始倒计时
        undoCountdown = 5
        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if undoCountdown > 0 {
                undoCountdown -= 1
            } else {
                timer.invalidate()
                performDelete()
            }
        }
    }
    
    private func undoDelete() {
        // 取消删除
        undoTimer?.invalidate()
        isDeleting = false
        deletedIndex = nil
        
        withAnimation {
            showUndoBanner = false
        }
    }
    
    private func performDelete() {
        guard var deletedIndex: Int? = deletedIndex else { return }
        let item = dataManager.items[deletedIndex ?? 0]
        
        // 删除图片文件
        ImageStorageManager.shared.deleteImage(withName: item.imageFileName)
        
        // 删除数据记录
        dataManager.deleteItem(id: item.id)
        
        // 更新界面
        withAnimation {
            showUndoBanner = false
        }
        
        // 切换到下一张或返回
        if totalCount == 0 {
            dismiss()
        } else if currentIndex >= totalCount {
            currentIndex = totalCount - 1
        }
        
        // 重置状态
        isDeleting = false
        deletedIndex = nil
    }
}

// MARK: - 可缩放图片视图

struct ZoomableImageView: View {
    let image: UIImage?
    let isLoading: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale *= delta
                            }
                            .onEnded { value in
                                lastScale = 1.0
                                if scale < 1.0 {
                                    withAnimation(.spring()) {
                                        scale = 1.0
                                    }
                                } else if scale > 3.0 {
                                    withAnimation(.spring()) {
                                        scale = 3.0
                                    }
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            if scale > 1.0 {
                                scale = 1.0
                            } else {
                                scale = 2.0
                            }
                        }
                    }
            } else if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - 详情行组件

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
        }
    }
}

// MARK: - 圆角扩展

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - 预览

#Preview {
    DetailView(
        item: CollectionItem(
            imageFileName: "preview.jpg",
            name: "示例藏品",
            category: ["手办", "限量版"],
            source: "淘宝",
            price: "199.99",
            location: "书架"
        ),
        index: 0
    )
}
