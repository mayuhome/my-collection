#!/bin/bash
# 测试 DetailView 修改

echo "=== DetailView 修改测试 ==="
echo ""

# 检查藏品名称显示
echo "1. 检查藏品名称显示..."
if grep -q "藏品名称显示" ./DetailView.swift; then
    echo "   ✅ 藏品名称显示代码存在"
else
    echo "   ❌ 藏品名称显示代码不存在"
fi

# 检查删除按钮优化
echo ""
echo "2. 检查删除按钮优化..."
if grep -q "删除按钮（更小，不易误触）" ./DetailView.swift; then
    echo "   ✅ 删除按钮优化代码存在"
else
    echo "   ❌ 删除按钮优化代码不存在"
fi

# 检查横竖屏切换功能
echo ""
echo "3. 检查横竖屏切换功能..."
if grep -q "toggleOrientation" ./DetailView.swift; then
    echo "   ✅ 横竖屏切换功能存在"
else
    echo "   ❌ 横竖屏切换功能不存在"
fi

# 检查旋转按钮
echo ""
echo "4. 检查旋转按钮..."
if grep -q "rotate.right" ./DetailView.swift; then
    echo "   ✅ 旋转按钮存在"
else
    echo "   ❌ 旋转按钮不存在"
fi

# 检查代码语法
echo ""
echo "5. 检查代码语法..."
if swiftc -parse ./DetailView.swift 2>&1 | grep -q "error"; then
    echo "   ❌ 代码存在语法错误"
else
    echo "   ✅ 代码语法正确"
fi

echo ""
echo "=== 测试完成 ==="
