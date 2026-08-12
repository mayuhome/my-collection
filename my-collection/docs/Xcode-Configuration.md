# Xcode 项目配置指南

## 概述
本文档说明如何为 MyCollection 应用配置 Xcode 项目设置，确保隐私优先的设计。

## 1. Info.plist 配置

项目已自动配置以下 Info.plist 键值（通过 `GENERATE_INFOPLIST_FILE = YES`）：

### 已配置的键值：
- `UIApplicationExitsOnSuspend` = NO
- `UIFileSharingEnabled` = YES  
- `LSSupportsOpeningDocumentsInPlace` = NO
- `NSPhotoLibraryAddUsageDescription` = "用于选择藏品图片保存到App中"
- `NSPhotoLibraryUsageDescription` = "用于从相册选择藏品图片"

### 未配置的键值（符合隐私要求）：
- 不包含 `NSAppTransportSecurity`（无网络权限）
- 不包含任何网络相关权限

## 2. 网络权限配置

### 物理层面关闭网络权限：
1. 在 `.entitlements` 文件中不包含：
   - `com.apple.developer.networking.networkextension`
   - `com.apple.developer.networking.wifi-info`
2. 不添加任何网络相关的 Capability

## 3. iCloud 配置

### 3.1 添加 iCloud Capability
1. 在 Xcode 中打开项目
2. 选择项目 Target → "my-collection"
3. 选择 "Signing & Capabilities" 标签
4. 点击 "+ Capability" 按钮
5. 搜索并添加 "iCloud"

### 3.2 配置 iCloud 服务
在 iCloud 配置面板中：
1. 勾选 "iCloud Drive"
2. 勾选 "iCloud Documents"
3. 在 Containers 部分，确保已添加：
   - `iCloud.jade.my-collection`

### 3.3 验证 entitlements 文件
确保 `my-collection.entitlements` 文件包含：
```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.jade.my-collection</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudDocuments</string>
</array>
```

## 4. 相册访问权限

已在 Info.plist 中配置：
- `NSPhotoLibraryAddUsageDescription` = "用于选择藏品图片保存到App中"
- `NSPhotoLibraryUsageDescription` = "用于从相册选择藏品图片"

## 5. 隐私清单文件

### 5.1 PrivacyInfo.xcprivacy
已创建隐私清单文件，声明：
- 不收集任何用户数据
- 不进行数据追踪
- 使用的 API 仅为相册选择和文件读写

### 5.2 隐私清单内容
```xml
<key>NSPrivacyTracking</key>
<false/>
<key>NSPrivacyTrackingDomains</key>
<array/>
<key>NSPrivacyCollectedDataTypes</key>
<array/>
```

## 6. 验证配置

### 6.1 检查 Info.plist
1. 在 Xcode 中，选择项目 Target
2. 选择 "Info" 标签
3. 确认所有必要的键值已添加

### 6.2 检查 Capabilities
1. 选择 "Signing & Capabilities" 标签
2. 确认 iCloud 已添加并配置正确
3. 确认没有添加任何网络相关的 Capability

### 6.3 检查 entitlements 文件
1. 在项目导航器中找到 `my-collection.entitlements`
2. 确认文件内容正确

## 7. 隐私合规性检查

### 7.1 确保无网络权限
- 检查 Info.plist 中无 `NSAppTransportSecurity`
- 检查 entitlements 文件中无网络相关权限
- 确认没有添加网络相关的 Capability

### 7.2 确保数据本地化
- 所有数据存储在本地文件系统
- 使用 iCloud 私有容器进行同步
- 不包含任何数据追踪代码

### 7.3 确保隐私清单完整
- 声明不收集数据
- 声明不进行追踪
- 声明使用的 API 类型

## 8. 测试配置

### 8.1 测试 iCloud 同步
1. 在真机上运行应用
2. 添加藏品数据
3. 在另一设备上验证数据同步

### 8.2 测试相册权限
1. 首次运行时应请求相册权限
2. 权限授予后应能正常选择图片
3. 权限拒绝时应有适当提示

### 8.3 测试隐私合规
1. 使用 App Privacy Report 检查
2. 验证无网络请求
3. 验证无数据收集

## 9. 常见问题

### Q1: 为什么需要 iCloud 权限？
A: 用于在用户私有的 iCloud 容器中同步藏品数据，确保数据在多设备间可用。

### Q2: 为什么需要相册权限？
A: 用于从用户相册选择藏品图片，保存到应用本地存储。

### Q3: 为什么不需要网络权限？
A: 应用完全离线运行，所有数据存储在本地和用户私有的 iCloud 容器，不进行任何网络通信。

### Q4: 如何验证隐私合规性？
A: 使用 Xcode 的 App Privacy Report 功能，检查应用的网络活动和数据收集情况。

## 10. 维护建议

### 10.1 定期检查
- 定期检查隐私清单文件
- 确保权限配置符合最新要求
- 验证 iCloud 同步功能

### 10.2 更新配置
- 当添加新功能时，更新相应的权限配置
- 定期审查权限使用情况
- 确保最小权限原则

### 10.3 用户沟通
- 在应用描述中说明隐私保护措施
- 提供清晰的权限使用说明
- 响应用户隐私相关询问

## 11. 相关文件

### 项目文件
- `project.pbxproj` - 项目配置
- `my-collection.entitlements` - 权限配置
- `PrivacyInfo.xcprivacy` - 隐私清单

### 文档文件
- `PRD.md` - 产品需求文档
- `Onboarding-Test.md` - 测试指南
- `Xcode-Configuration.md` - 本文档

## 12. 联系支持

如有配置问题，请参考：
1. Apple 开发者文档
2. Xcode 帮助文档
3. 项目源代码注释
