//
//  EditItemView.swift
//  my-collection
//
//  使用 ItemFormView 实现编辑藏品
//

import SwiftUI

struct EditItemView: View {
    
    let item: CollectionItem
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    
    // 图片状态
    @State private var newImages: [UIImage] = []
    @State private var existingFileNames: [String]
    @State private var deletedFileNames: [String] = []
    
    // 文字字段
    @State private var name: String
    @State private var selectedCategories: [String]
    @State private var source: String
    @State private var price: String
    @State private var location: String
    
    // 状态
    @State private var showCancelConfirm = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var isSaving = false
    
    init(item: CollectionItem) {
        self.item = item
        _existingFileNames = State(initialValue: item.imageFileNames)
        _name = State(initialValue: item.name ?? "")
        _selectedCategories = State(initialValue: item.category ?? [])
        _source = State(initialValue: item.source ?? "")
        _price = State(initialValue: item.price ?? "")
        _location = State(initialValue: item.location ?? "")
    }
    
    // 是否有未保存的修改
    private var hasChanges: Bool {
        if !newImages.isEmpty { return true }
        if deletedFileNames.count > 0 { return true }
        if name != (item.name ?? "") { return true }
        if selectedCategories != (item.category ?? []) { return true }
        if source != (item.source ?? "") { return true }
        if price != (item.price ?? "") { return true }
        if location != (item.location ?? "") { return true }
        return false
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ItemFormView(
                    newImages: $newImages,
                    existingFileNames: $existingFileNames,
                    deletedFileNames: $deletedFileNames,
                    name: $name,
                    selectedCategories: $selectedCategories,
                    source: $source,
                    price: $price,
                    location: $location,
                    isEditMode: true,
                    onSave: { save() },
                    onCancel: { cancelTapped() },
                    onDelete: { deleteItem() }
                )
                
                if showToast {
                    toast
                }
            }
            .navigationTitle("编辑藏品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { cancelTapped() }
                }
            }
            .alert("放弃修改？", isPresented: $showCancelConfirm) {
                Button("继续编辑", role: .cancel) {}
                Button("放弃", role: .destructive) { dismiss() }
            } message: {
                Text("你有未保存的修改，确定要放弃吗？")
            }
        }
    }
    
    // MARK: - 取消
    
    private func cancelTapped() {
        if hasChanges {
            showCancelConfirm = true
        } else {
            dismiss()
        }
    }
    
    // MARK: - 保存逻辑
    
    private func save() {
        let totalImages = existingFileNames.count + newImages.count
        guard totalImages > 0 else { return }
        isSaving = true
        
        Task { @MainActor in
            // 1. 物理删除被移除的图片
            if !deletedFileNames.isEmpty {
                ImageStorageManager.shared.deleteImages(deletedFileNames)
            }
            
            // 2. 保存新增图片
            var allFileNames = existingFileNames
            if !newImages.isEmpty {
                let saved = ImageStorageManager.shared.saveImages(newImages)
                allFileNames.append(contentsOf: saved)
            }
            
            // 3. 更新藏品
            var updated = item
            updated.imageFileNames = allFileNames
            updated.name = name.isEmpty ? nil : name
            updated.category = selectedCategories.isEmpty ? nil : selectedCategories
            updated.source = source.isEmpty ? nil : source
            updated.price = price.isEmpty ? nil : price
            updated.location = location.isEmpty ? nil : location
            updated.modifyDate = Date()
            
            dataManager.updateItem(updated)
            isSaving = false
            showToastMessage("已更新 ✓")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                dismiss()
            }
        }
    }
    
    // MARK: - 删除藏品
    
    private func deleteItem() {
        dataManager.deleteItem(id: item.id)
        dismiss()
    }
    
    // MARK: - Toast
    
    private var toast: some View {
        VStack {
            Spacer()
            Text(toastMessage)
                .font(.subheadline).foregroundColor(.white)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(Color.black.opacity(0.75))
                .cornerRadius(20)
                .padding(.bottom, 40)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: showToast)
    }
    
    private func showToastMessage(_ msg: String) {
        toastMessage = msg
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showToast = false }
        }
    }
}
