

# 检查是否安装了screen
if ! command -v screen &> /dev/null; then
    echo "正在安装 screen..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y screen
    elif command -v yum &> /dev/null; then
        sudo yum install -y screen
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y screen
    else
        echo "错误：无法自动安装screen，请手动安装"
        exit 1
    fi
    echo "screen 安装完成！"
fi

# 安装nexus-cli（如果未安装）
if ! command -v nexus-network &> /dev/null; then
    echo "正在安装 nexus-cli..."
    curl https://cli.nexus.xyz/ | sh
    source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null
    echo "安装完成！"
fi

# 获取节点ID
echo ""
echo "请输入您的节点ID（纯数字，如：7366937）:"
read -p "节点ID: " NODE_ID

# 清理输入（去除空格和特殊字符）
NODE_ID=$(echo "$NODE_ID" | tr -d '[:space:]')

# 验证节点ID
if [ -z "$NODE_ID" ]; then
    echo "❌ 错误：节点ID不能为空"
    echo "请重新运行脚本并输入有效的节点ID"
    exit 1
fi

# 检查是否只包含数字
if ! [[ "$NODE_ID" =~ ^[0-9]+$ ]]; then
    echo "❌ 错误：节点ID应该只包含数字"
    echo "您输入的ID: $NODE_ID"
    echo "请重新运行脚本并输入正确的节点ID"
    exit 1
fi

echo "✅ 节点ID验证通过: $NODE_ID"

# 检查是否已有同名screen会话
SESSION_NAME="nexus_${NODE_ID}"
if screen -list | grep -q "$SESSION_NAME"; then
    echo "发现已存在的会话: $SESSION_NAME"
    read -p "是否要连接到现有会话？(y/n): " choice
    if [[ $choice == "y" || $choice == "Y" ]]; then
        echo "连接到现有会话..."
        screen -r "$SESSION_NAME"
        exit 0
    else
        echo "终止现有会话并创建新会话..."
        screen -S "$SESSION_NAME" -X quit 2>/dev/null
    fi
fi

echo "开始运行节点: $NODE_ID"
echo "Screen会话名称: $SESSION_NAME"
echo ""
echo "=== Screen 使用说明 ==="
echo "• 分离会话: Ctrl+A 然后按 D"
echo "• 重新连接: screen -r $SESSION_NAME"
echo "• 查看会话: screen -list"
echo "• 停止脚本: 在会话中按 Ctrl+C"
echo "========================"
echo ""

# 在screen会话中运行脚本
screen -dmS "$SESSION_NAME" bash -c "
echo '=== Nexus 节点运行中 ==='
echo '节点ID: $NODE_ID'
echo '会话名称: $SESSION_NAME'
echo '开始时间: \$(date)'
echo ''

# 主循环
while true; do
    echo \"\$(date): 启动节点 $NODE_ID\"
    nexus-network start --node-id \"$NODE_ID\"  --max-threads 8
    echo \"\$(date): 节点停止，1小时后重启...\"
    sleep 3600
done
"

echo "✅ 节点已在Screen会话中启动！"
echo ""
echo "📋 常用命令："
echo "• 查看会话状态: screen -list"
echo "• 连接到会话: screen -r $SESSION_NAME"
echo "• 分离会话: 在会话中按 Ctrl+A 然后按 D"
echo "• 停止节点: screen -S $SESSION_NAME -X quit"
echo ""
echo "🌐 现在您可以安全地关闭SSH连接，节点会继续运行！" 
