#!/bin/bash
# 重置引导页状态脚本

echo "正在重置引导页状态..."
defaults delete com.apple.dt.XcodeDeviceMonitor hasLaunchedBefore 2>/dev/null
defaults delete com.apple.iphonesimulator hasLaunchedBefore 2>/dev/null
defaults delete hasLaunchedBefore 2>/dev/null

# 如果知道具体的bundle identifier，可以使用以下命令：
# defaults delete com.yourcompany.my-collection hasLaunchedBefore

echo "重置完成！请重新运行应用。"
echo "注意：如果应用在模拟器中运行，可能需要重启模拟器。"
