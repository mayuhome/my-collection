//
//  OnboardingView.swift
//  my-collection
//
//  Created by Ma Jade on 2026/8/12.
//

import SwiftUI

struct OnboardingView: View {
    // 绑定到App的显示状态
    @Binding var isOnboardingCompleted: Bool
    
    // 当前页面索引
    @State private var currentPage = 0
    
    // 引导页数据
    private let pages = [
        OnboardingPage(
            icon: "📷",
            title: "拍下你的藏品",
            description: "从相册选择图片，一键添加"
        ),
        OnboardingPage(
            icon: "🔒",
            title: "数据只在你手里",
            description: "所有照片只存于本机，绝不联网"
        ),
        OnboardingPage(
            icon: "👆",
            title: "简单查看，随时回顾",
            description: "点击图片放大，滑动切换"
        )
    ]
    
    // 颜色配置
    private let backgroundColor = Color(.systemBackground)
    private let primaryColor = Color.blue
    private let secondaryColor = Color.secondary
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部跳过按钮
            HStack {
                Spacer()
                if currentPage < pages.count - 1 {
                    Button("跳过") {
                        completeOnboarding()
                    }
                    .foregroundColor(secondaryColor)
                    .padding()
                }
            }
            
            // 引导页内容
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index], primaryColor: primaryColor)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // 底部区域
            VStack(spacing: 20) {
                // 页面指示器（底部）
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? primaryColor : secondaryColor.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)
                
                // 最后一页显示"开始使用"按钮
                if currentPage == pages.count - 1 {
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("开始使用")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(primaryColor)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .transition(.opacity)
                }
                
                // 下一页按钮（如果不是最后一页）
                if currentPage < pages.count - 1 {
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        HStack {
                            Text("下一页")
                            Image(systemName: "arrow.right")
                        }
                        .font(.subheadline)
                        .foregroundColor(primaryColor)
                    }
                }
            }
            .padding(.bottom, 40)
            .animation(.easeInOut, value: currentPage)
        }
        .background(backgroundColor)
    }
    
    // 完成引导
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        isOnboardingCompleted = true
    }
}

// MARK: - 引导页数据模型

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

// MARK: - 单页视图

struct OnboardingPageView: View {
    let page: OnboardingPage
    let primaryColor: Color
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 图标
            Text(page.icon)
                .font(.system(size: 80))
            
            // 标题
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // 描述
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - 预览

#Preview {
    OnboardingView(isOnboardingCompleted: .constant(false))
}
