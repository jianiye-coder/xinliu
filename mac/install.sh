#!/bin/bash
# 安装心流岛 Mac 定时弹窗。重复运行 = 用新参数覆盖安装。
#   ./install.sh                         默认：9–23 点每 30 分钟检查一次，21:00 写作提醒
#   INTERVAL=20 WRITE_TIME=20:30 ./install.sh
#   XINLIU_URL=https://你的用户名.github.io/xinliu/ ./install.sh   部署到网上后换成网址
#   ANCHOR_TIME=19:00 ANCHOR_PLACE=图书馆 ./install.sh            学习锚点：每天到点弹「开始热身」
set -e
SRC="$(cd "$(dirname "$0")" && pwd)"
INTERVAL="${INTERVAL:-30}"           # 分钟
START_HOUR="${START_HOUR:-9}"
END_HOUR="${END_HOUR:-23}"
WRITE_TIME="${WRITE_TIME:-21:00}"
ANCHOR_TIME="${ANCHOR_TIME:-}"
ANCHOR_PLACE="${ANCHOR_PLACE:-}"
XINLIU_URL="${XINLIU_URL:-file://$(cd "$SRC/.." && pwd)/xinliu.html}"

# 脚本放到 Application Support：launchd 没有权限读「桌面」文件夹里的脚本
DEST="$HOME/Library/Application Support/xinliu"
AGENTS="$HOME/Library/LaunchAgents"
mkdir -p "$DEST" "$AGENTS"
cp "$SRC/xinliu-remind.sh" "$DEST/"
chmod +x "$DEST/xinliu-remind.sh"
cat > "$DEST/config.sh" <<CFG
XINLIU_URL="$XINLIU_URL"
START_HOUR=$START_HOUR
END_HOUR=$END_HOUR
ANCHOR_PLACE="$ANCHOR_PLACE"
CFG

WH=$((10#${WRITE_TIME%%:*})); WM=$((10#${WRITE_TIME##*:}))

plist() { # $1 label $2 mode $3 schedule-xml
cat > "$AGENTS/$1.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$1</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$DEST/xinliu-remind.sh</string><string>$2</string></array>
  $3
  <key>StandardErrorPath</key><string>$DEST/error.log</string>
</dict></plist>
PL
launchctl bootout "gui/$(id -u)/$1" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENTS/$1.plist"
}

# 不再装「要不要开始专注」的定时弹窗（用户要求永远不弹）
for old in com.xinliu.checkin com.xinliu.anchor; do launchctl bootout "gui/$(id -u)/$old" 2>/dev/null || true; rm -f "$AGENTS/$old.plist"; done
plist com.xinliu.write write "<key>StartCalendarInterval</key><dict><key>Hour</key><integer>$WH</integer><key>Minute</key><integer>$WM</integer></dict>"

echo "已安装：每天 ${WRITE_TIME} 写作提醒（不会弹窗催你开始专注）"
echo "打开地址：$XINLIU_URL"
echo "立刻试一下：bash \"$DEST/xinliu-remind.sh\" checkin"
