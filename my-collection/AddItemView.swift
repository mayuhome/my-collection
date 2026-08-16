//
//  AddItemView.swift
//  my-collection
//
//  使用 ItemFormView 实现添加藏品
//

import SwiftUI

struct AddItemView: View {
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    
    // 图片状态
    @State private var newImages: [UIImage] = []
    @State private var existingFileNames: [String] = []
    @State private var deletedFileNames: [String] = []  // 添加模式下不会用到
    
    // 文字字段
    @State private var name = ""
    @State private var selectedCategories: [String] = []
    @State private var source = ""
    @State private var price = ""
    @State private var location = ""
    
    // 提示
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var isSaving = false
    
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
                    isEditMode: false,
                    currentItemID: nil,
                    onSave: { save() },
                    onCancel: { dismiss() },
                    onDelete: nil
                )
                
                if showToast {
                    toast
                }
            }
            .navigationTitle("添加藏品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - 保存逻辑
    
    private func save() {
        guard !newImages.isEmpty else { return }
        isSaving = true
        
        Task { @MainActor in
            // 保存所有新图片，获取文件名列表
            let savedNames = ImageStorageManager.shared.saveImages(newImages)
            
            guard !savedNames.isEmpty else {
                showToastMessage("保存失败，请重试")
                isSaving = false
                return
            }
            
            // 构建藏品
            let item = CollectionItem(
                imageFileNames: savedNames,
                name: name.isEmpty ? nil : name,
                category: selectedCategories.isEmpty ? nil : selectedCategories,
                source: source.isEmpty ? nil : source,
                price: price.isEmpty ? nil : price,
                location: location.isEmpty ? nil : location
            )
            
            dataManager.addItem(item)
            isSaving = false
            showToastMessage("已保存 ✓")
            
            // 延迟关闭
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                dismiss()
            }
        }
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
