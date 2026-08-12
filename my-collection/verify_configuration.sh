#!/bin/bash
# 配置验证脚本

echo "=== MyCollection 配置验证 ==="
echo ""

# 检查Info.plist配置
echo "1. 检查Info.plist配置..."
if grep -q "INFOPLIST_KEY_UIApplicationExitsOnSuspend = NO" ../my-collection.xcodeproj/project.pbxproj; then
    echo "   ✅ UIApplicationExitsOnSuspend = NO"
else
    echo "   ❌ UIApplicationExitsOnSuspend 未配置"
fi

if grep -q "INFOPLIST_KEY_UIFileSharingEnabled = YES" ../my-collection.xcodeproj/project.pbxproj; then
    echo "   ✅ UIFileSharingEnabled = YES"
else
    echo "   ❌ UIFileSharingEnabled 未配置"
fi

if grep -q "INFOPLIST_KEY_LSSupportsOpeningDocumentsInPlace = NO" ../my-collection.xcodeproj/project.pbxproj; then
    echo "   ✅ LSSupportsOpeningDocumentsInPlace = NO"
else
    echo "   ❌ LSSupportsOpeningDocumentsInPlace 未配置"
fi

if grep -q "INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription" ../my-collection.xcodeproj/project.pbxproj; then
    echo "   ✅ NSPhotoLibraryAddUsageDescription 已配置"
else
    echo "   ❌ NSPhotoLibraryAddUsageDescription 未配置"
fi

if grep -q "INFOPLIST_KEY_NSPhotoLibraryUsageDescription" ../my-collection.xcodeproj/project.pbxproj; then
    echo "   ✅ NSPhotoLibraryUsageDescription 已配置"
else
    echo "   ❌ NSPhotoLibraryUsageDescription 未配置"
fi

# 检查网络权限
echo ""
echo "2. 检查网络权限..."
if grep -q "NSAppTransportSecurity" ../my-collection.xcodeproj/project.pbxproj; then
    echo "   ❌ 发现 NSAppTransportSecurity 配置"
else
    echo "   ✅ 无 NSAppTransportSecurity 配置"
fi

if grep -q "com.apple.developer.networking" ./my-collection.entitlements; then
    echo "   ❌ 发现网络相关权限"
else
    echo "   ✅ 无网络相关权限"
fi

# 检查iCloud配置
echo ""
echo "3. 检查iCloud配置..."
if [ -f "./my-collection.entitlements" ]; then
    echo "   ✅ entitlements 文件存在"
    if grep -q "com.apple.developer.icloud-container-identifiers" ./my-collection.entitlements; then
        echo "   ✅ iCloud 容器标识符已配置"
    else
        echo "   ❌ iCloud 容器标识符未配置"
    fi
else
    echo "   ❌ entitlements 文件不存在"
fi

# 检查隐私清单
echo ""
echo "4. 检查隐私清单..."
if [ -f "./PrivacyInfo.xcprivacy" ]; then
    echo "   ✅ PrivacyInfo.xcprivacy 文件存在"
    if grep -q "NSPrivacyTracking" ./PrivacyInfo.xcprivacy; then
        echo "   ✅ 声明不进行数据追踪"
    else
        echo "   ❌ 未声明数据追踪设置"
    fi
else
    echo "   ❌ PrivacyInfo.xcprivacy 文件不存在"
fi

# 检查相册权限描述
echo ""
echo "5. 检查相册权限描述..."
if grep -q "用于选择藏品图片保存到App中" ../my-collection.xcodeproj/project.pbxproj; then
    echo "   ✅ NSPhotoLibraryAddUsageDescription 内容正确"
else
    echo "   ❌ NSPhotoLibraryAddUsageDescription 内容不正确"
fi

if grep -q "用于从相册选择藏品图片" ../my-collection.xcodeproj/project.pbxproj; then
    echo "   ✅ NSPhotoLibraryUsageDescription 内容正确"
else
    echo "   ❌ NSPhotoLibraryUsageDescription 内容不正确"
fi

echo ""
echo "=== 配置验证完成 ==="
