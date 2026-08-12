//
//  ItemFormView.swift
//  my-collection
//
//  添加/编辑藏品共用表单组件
//

import SwiftUI
import PhotosUI

// MARK: - 共用表单

struct ItemFormView: View {
    
    // ---- 图片状态 ----
    /// 用户新选的 UIImage（待保存）
    @Binding var newImages: [UIImage]
    /// 已有图片的文件名（编辑模式下预加载）
    @Binding var existingFileNames: [String]
    /// 编辑模式下被删除的文件名（保存时物理删除）
    @Binding var deletedFileNames: [String]
    
    // ---- 文字字段 ----
    @Binding var name: String
    @Binding var selectedCategories: [String]
    @Binding var source: String
    @Binding var price: String
    @Binding var location: String
    
    // ---- 配置 ----
    let isEditMode: Bool
    let maxImages: Int = 9
    let onSave: () -> Void
    let onCancel: () -> Void
    let onDelete: (() -> Void)?
    
    // ---- 内部状态 ----
    @State private var showImagePicker = false
    @State private var showDeleteConfirm = false
    @State private var previewImage: UIImage? = nil
    @State private var showPreview = false
    @State private var isExpanded = false
    
    // 已有图片的缩略图缓存
    @State private var existingThumbnails: [String: UIImage] = [:]
    
    private let allCategories = ["手办", "邮票", "钱币", "书籍"]
    
    // 当前总图片数
    private var totalImageCount: Int {
        existingFileNames.count + newImages.count
    }
    
    // 是否还能添加图片
    private var canAddMore: Bool {
        totalImageCount < maxImages
    }
    
    // 是否可以保存（至少一张图）
    private var canSave: Bool {
        totalImageCount > 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                imageSection
                nameSection
                categorySection
                additionalSection
                saveButton
            }
            .padding()
        }
    }
    
    // MARK: - 图片区
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("藏品图片").font(.headline)
                Spacer()
                Text("\(totalImageCount)/\(maxImages)")
                    .font(.caption).foregroundColor(.secondary)
            }
            
            // 图片缩略图滚动区
            if totalImageCount > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // 已有图片
                        ForEach(existingFileNames, id: \.self) { fileName in
                            thumbnailView(
                                image: existingThumbnails[fileName],
                                isNew: false,
                                onDelete: { deleteExistingImage(fileName) },
                                onTap: {
                                    if let img = existingThumbnails[fileName] {
                                        previewImage = img; showPreview = true
                                    }
                                }
                            )
                        }
                        // 新增图片
                        ForEach(Array(newImages.enumerated()), id: \.offset) { _, img in
                            thumbnailView(
                                image: img,
                                isNew: true,
                                onDelete: { newImages.removeAll { $0 === img } },
                                onTap: { previewImage = img; showPreview = true }
                            )
                        }
                    }
                }
            }
            
            // 添加图片按钮
            if canAddMore {
                Button { showImagePicker = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                        Text("点击添加图片（可多选）")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                            .foregroundColor(.blue.opacity(0.4))
                    )
                    .background(Color.blue.opacity(0.03))
                }
                .buttonStyle(.plain)
            }
            
            if !canSave {
                Text("请至少添加一张图片")
                    .font(.caption).foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .onAppear { loadExistingThumbnails() }
        .sheet(isPresented: $showImagePicker) {
            MultiImagePicker(
                maxSelection: maxImages - totalImageCount,
                onPicked: { images in newImages.append(contentsOf: images) }
            )
        }
        .fullScreenCover(isPresented: $showPreview) {
            imagePreviewOverlay
        }
    }
    
    // 单个缩略图
    private func thumbnailView(image: UIImage?, isNew: Bool, onDelete: @escaping () -> Void, onTap: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .overlay(ProgressView().scaleEffect(0.6))
            }
            
            // 新增角标
            if isNew {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("新")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }
                .frame(width: 80, height: 80)
            }
            
            // 删除按钮
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.red))
            }
            .offset(x: 6, y: -6)
        }
        .onTapGesture(perform: onTap)
    }
    
    // 全屏预览
    private var imagePreviewOverlay: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let img = previewImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            }
            VStack {
                HStack {
                    Spacer()
                    Button { showPreview = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(20)
                    }
                }
                Spacer()
            }
        }
    }
    
    // MARK: - 名称
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("名称").font(.headline)
            TextField("给它起个名（选填）", text: $name)
                .textFieldStyle(.plain)
                .padding().frame(height: 44)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - 分类
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类（选填，可多选）").font(.headline)
            
            FlowLayout(spacing: 10) {
                ForEach(allCategories, id: \.self) { cat in
                    let selected = selectedCategories.contains(cat)
                    Button {
                        toggleCategory(cat)
                    } label: {
                        Text(cat)
                            .font(.subheadline)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(selected ? Color.blue : Color.clear)
                            .foregroundColor(selected ? .white : .primary)
                            .overlay(
                                Capsule().stroke(selected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - 补充信息
    
    private var additionalSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("补充更多信息（选填）").font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 16) {
                    formField("从哪儿来的？", text: $source, placeholder: "如：淘宝、朋友赠送")
                    formField("花了多少钱？", text: $price, placeholder: "如：199.99")
                    formField("现在放在哪？", text: $location, placeholder: "如：书架第二层")
                }
                .padding(.horizontal).padding(.bottom)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - 保存按钮
    
    private var saveButton: some View {
        VStack(spacing: 12) {
            Button { onSave() } label: {
                Text(isEditMode ? "保存修改" : "保存")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(canSave ? Color.green : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!canSave)
            
            // 编辑模式下的删除按钮
            if isEditMode, let onDelete = onDelete {
                Button { showDeleteConfirm = true } label: {
                    Text("删除此藏品")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(12)
                }
                .alert("确认删除", isPresented: $showDeleteConfirm) {
                    Button("取消", role: .cancel) {}
                    Button("删除", role: .destructive) { onDelete() }
                } message: {
                    Text("删除后不可恢复，确定要删除吗？")
                }
            }
        }
    }
    
    // MARK: - 辅助
    
    private func formField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .padding().frame(height: 44)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }
    
    private func toggleCategory(_ cat: String) {
        if let idx = selectedCategories.firstIndex(of: cat) {
            selectedCategories.remove(at: idx)
        } else {
            selectedCategories.append(cat)
        }
    }
    
    private func deleteExistingImage(_ fileName: String) {
        existingFileNames.removeAll { $0 == fileName }
        deletedFileNames.append(fileName)
        existingThumbnails.removeValue(forKey: fileName)
    }
    
    private func loadExistingThumbnails() {
        for name in existingFileNames {
            if existingThumbnails[name] == nil {
                Task { @MainActor in
                    if let img = ImageStorageManager.shared.loadThumbnail(withName: name) {
                        existingThumbnails[name] = img
                    } else if let img = ImageStorageManager.shared.loadImage(withName: name) {
                        existingThumbnails[name] = img
                    }
                }
            }
        }
    }
}

// MARK: - 多图选择器

struct MultiImagePicker: UIViewControllerRepresentable {
    let maxSelection: Int
    let onPicked: ([UIImage]) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = max(1, maxSelection)
        config.selection = .ordered
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiImagePicker
        init(_ parent: MultiImagePicker) { self.parent = parent }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else { return }
            
            var images: [UIImage] = []
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                    defer { group.leave() }
                    if let img = obj as? UIImage {
                        images.append(img)
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.parent.onPicked(images)
            }
        }
    }
}

// MARK: - 流式布局

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (i, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[i].x,
                                      y: bounds.minY + result.positions[i].y),
                          proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0, maxX: CGFloat = 0
        
        for subview in subviews {
            let s = subview.sizeThatFits(.unspecified)
            if x + s.width > maxWidth { x = 0; y += lineH + spacing; lineH = 0 }
            positions.append(CGPoint(x: x, y: y))
            lineH = max(lineH, s.height)
            x += s.width + spacing
            maxX = max(maxX, x)
        }
        return (CGSize(width: maxX - spacing, height: y + lineH), positions)
    }
}
