//
//  AddItemView.swift
//  my-collection
//
//  Created by Ma Jade on 2026/8/12.
//

import SwiftUI
import PhotosUI
import UIKit

struct AddItemView: View {
    // MARK: - 环境与状态
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    
    // 图片选择状态
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    
    // 表单字段
    @State private var name: String = ""
    @State private var selectedCategories: Set<String> = []
    @State private var source: String = ""
    @State private var price: String = ""
    @State private var location: String = ""
    
    // 折叠区域状态
    @State private var isExpanded: Bool = false
    
    // 预设分类
    private let categories = ["手办", "邮票", "钱币", "书籍"]
    
    // 保存状态
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // MARK: - 主视图
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 图片选择区
                    imageSelectionSection
                    
                    // 名称输入框
                    nameSection
                    
                    // 分类选择区
                    categorySection
                    
                    // 折叠区域
                    additionalInfoSection
                    
                    // 保存按钮
                    saveButton
                }
                .padding()
            }
            .navigationTitle("添加藏品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImages: $selectedImages, maxSelection: 9)
            }
            .alert("提示", isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - 图片选择区
    
    private var imageSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("藏品图片")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 已选图片预览
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedImages.indices, id: \.self) { index in
                            Image(uiImage: selectedImages[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // 图片选择区域
            Button {
                showImagePicker = true
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("📷 点击选择图片（可多选）")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Text("最多选择9张")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                        .foregroundColor(.blue.opacity(0.3))
                )
                .background(Color.blue.opacity(0.05))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - 名称输入框
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("名称")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("给它起个名（选填）", text: $name)
                .textFieldStyle(.plain)
                .padding()
                .frame(height: 44)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - 分类选择区
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类（选填，可多选）")
                .font(.headline)
                .foregroundColor(.primary)
            
            FlowLayout(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    CategoryButton(
                        title: category,
                        isSelected: selectedCategories.contains(category)
                    ) {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - 折叠区域
    
    private var additionalInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 折叠标题
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("补充更多信息（选填）")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            // 展开内容
            if isExpanded {
                VStack(spacing: 16) {
                    FormField(title: "从哪儿来的？", text: $source, placeholder: "例如：淘宝、朋友赠送")
                    FormField(title: "花了多少钱？", text: $price, placeholder: "例如：199.99")
                    FormField(title: "现在放在哪？", text: $location, placeholder: "例如：书架第二层")
                }
                .padding(.horizontal)
                .padding(.bottom)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - 保存按钮
    
    private var saveButton: some View {
        Button {
            saveItems()
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                }
                
                Text("保存")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedImages.isEmpty ? Color.gray : Color.green)
            )
        }
        .disabled(selectedImages.isEmpty || isSaving)
        .padding(.top, 20)
    }
    
    // MARK: - 保存逻辑
    
    private func saveItems() {
        guard !selectedImages.isEmpty else {
            alertMessage = "请至少选择一张图片"
            showAlert = true
            return
        }
        
        isSaving = true
        
        Task { @MainActor in
            let imageStorage = ImageStorageManager.shared
            var successCount = 0
            
            for image in selectedImages {
                // 生成UUID文件名
                let fileName = "\(UUID().uuidString).jpg"
                
                // 保存图片和缩略图
                let saved = imageStorage.saveImageAndGenerateThumbnail(image, withName: fileName)
                
                if saved {
                    // 创建CollectionItem
                    let item = CollectionItem(
                        imageFileName: fileName,
                        name: name.isEmpty ? nil : name,
                        category: selectedCategories.isEmpty ? nil : Array(selectedCategories),
                        source: source.isEmpty ? nil : source,
                        price: price.isEmpty ? nil : price,
                        location: location.isEmpty ? nil : location
                    )
                    
                    // 保存到DataManager
                    dataManager.addItem(item)
                    successCount += 1
                }
            }
            
            isSaving = false
            
            if successCount == selectedImages.count {
                // 全部保存成功，返回首页
                dismiss()
            } else {
                alertMessage = "保存失败，请重试"
                showAlert = true
            }
        }
    }
}

// MARK: - 表单字段组件

struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding()
                .frame(height: 44)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

// MARK: - 分类按钮组件

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 流式布局

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }
        
        return (CGSize(width: maxX - spacing, height: currentY + lineHeight), positions)
    }
}

// MARK: - 图片选择器（PHPickerViewController包装）

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let maxSelection: Int
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = maxSelection
        config.selection = .ordered
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            parent.selectedImages.removeAll()
            
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    defer { group.leave() }
                    
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(image)
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                // 所有图片加载完成
            }
        }
    }
}

// MARK: - 预览

#Preview {
    AddItemView()
}
