//
//  ContentView.swift
//  my-collection
//
//  Created by Ma Jade on 2026/8/12.
//

import SwiftUI

struct ContentView: View {
    // 数据管理器
    @ObservedObject private var dataManager = DataManager.shared
    // 随机浏览状态
    @State private var randomItem: CollectionItem? = nil
    @State private var randomIndex: Int? = nil
    @State private var showAlert = false
    
    // 分类状态
    @State private var selectedCategory: String = "全部"
    
    /// 从所有藏品中提取不重复的分类，保持稳定顺序
    private var categories: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for item in dataManager.items {
            guard let cats = item.category else { continue }
            for cat in cats {
                if seen.insert(cat).inserted {
                    result.append(cat)
                }
            }
        }
        return ["全部"] + result.sorted()
    }
    
    // 网格布局配置
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // MARK: - 计算属性
    
    /// 根据选中分类过滤藏品
    private var filteredItems: [CollectionItem] {
        if selectedCategory == "全部" {
            return dataManager.items
        } else {
            return dataManager.items.filter { item in
                item.category?.contains(selectedCategory) ?? false
            }
        }
    }
    
    /// 计算总价（仅统计price不为空的藏品）
    private var totalPrice: Double {
        let prices = dataManager.items.compactMap { item -> Double? in
            guard let priceString = item.price else { return nil }
            // 过滤非数字字符，保留数字和小数点
            let filtered = priceString.filter { $0.isNumber || $0 == "." }
            return Double(filtered)
        }
        return prices.reduce(0, +)
    }
    
    // MARK: - 主视图
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 主内容
                VStack(spacing: 0) {
                    // 分类Tab栏
                    categoryTabs
                    
                    // 藏品网格
                    if filteredItems.isEmpty {
                        emptyStateView
                    } else {
                        collectionGrid
                    }
                    
                    // 底部统计条
                    statisticsBar
                }
                
                // 悬浮添加按钮
                addButton
            }
            .navigationTitle("我的收藏")
            // 隐藏的随机浏览导航链接
            .background {
                NavigationLink(
                    isActive: Binding(
                        get: { randomItem != nil },
                        set: { if !$0 { randomItem = nil; randomIndex = nil } }
                    ),
                    destination: {
                        if let index = randomIndex {
                            DetailView(startIndex: index)
                        }
                    },
                    label: { EmptyView() }
                )
            }
            .alert("提示", isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text("还没有藏品，先去添加一些吧")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("🎲 随便看看") {
                        // 检查是否有藏品
                        guard !dataManager.items.isEmpty else {
                            showAlert = true
                            return
                        }
                        // 随机选择一个藏品
                        let index = Int.random(in: 0..<dataManager.items.count)
                        randomIndex = index
                        randomItem = dataManager.items[index]
                    }
                }
            }
        }
    }
    
    // MARK: - 分类Tab栏
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category)
                            .font(.subheadline)
                            .fontWeight(selectedCategory == category ? .bold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategory == category ?
                                    Color.blue.opacity(0.2) :
                                    Color.gray.opacity(0.1)
                            )
                            .foregroundColor(selectedCategory == category ? .blue : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 藏品网格
    
    private var collectionGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                    if let originalIndex = dataManager.items.firstIndex(where: { $0.id == item.id }) {
                        NavigationLink(destination: DetailView(startIndex: originalIndex)) {
                            CollectionItemCell(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100) // 为底部按钮留出空间
        }
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("还没有藏品")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("点击下方＋添加")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 底部统计条
    
    private var statisticsBar: some View {
        HStack {
            Spacer()
            
            Text("共 \(dataManager.items.count) 件 ｜ 总价 ¥\(String(format: "%.2f", totalPrice))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground).shadow(color: .black.opacity(0.05), radius: 2, y: -1))
    }
    
    // MARK: - 悬浮添加按钮
    
    private var addButton: some View {
        NavigationLink(destination: AddItemView()) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 20)
    }
}

// MARK: - 藏品单元格

struct CollectionItemCell: View {
    let item: CollectionItem
    
    // 图片状态
    @State private var thumbnail: UIImage? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 缩略图
            ZStack {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 150)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
            }
            .onAppear {
                loadThumbnail()
            }
            
            // 藏品名称
            if let name = item.name, !name.isEmpty {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    // 加载缩略图
    private func loadThumbnail() {
        Task { @MainActor in
            let loadedImage = item.imageFileNames.first.flatMap { ImageStorageManager.shared.loadThumbnail(withName: $0) }
            self.thumbnail = loadedImage
        }
    }
}

// MARK: - 预览

#Preview {
    ContentView()
}
