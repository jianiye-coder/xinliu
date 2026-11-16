#!/bin/bash
# 心流岛 · macOS 定时弹窗（由 launchd 调用，页面没开也能提醒）
#   xinliu-remind.sh checkin   空闲检查：问你要不要开始一轮专注
#   xinliu-remind.sh write     每日写作提醒
#   xinliu-remind.sh anchor    学习锚点：到点了，直接开始 5 分钟热身
# 配置在同目录的 config.sh（install.sh 生成）。

DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$DIR/config.sh" ] && . "$DIR/config.sh"
URL="${XINLIU_URL:-https://example.invalid/xinliu.html}"
START_HOUR="${START_HOUR:-9}"
END_HOUR="${END_HOUR:-23}"
MODE="${1:-checkin}"

hour=$((10#$(date +%H)))

# 浏览器里有一个标题带「专注中」或「休息」的标签页 = 你正在一轮里，不打扰。
# 第一次运行时 macOS 会问「osascript 想控制 Chrome/Safari」，点允许。拒绝了也没关系，只是少了这个判断。
in_session() {
  osascript <<'AS' 2>/dev/null | grep -q yes
set hit to "no"
try
  if application "Google Chrome" is running then
    tell application "Google Chrome"
      repeat with w in windows
        repeat with t in tabs of w
          set n to title of t
          if n contains "专注中" or n contains " 休息" then set hit to "yes"
        end repeat
      end repeat
    end tell
  end if
end try
try
  if application "Safari" is running then
    tell application "Safari"
      repeat with w in windows
        repeat with t in tabs of w
          set n to name of t
          if n contains "专注中" or n contains " 休息" then set hit to "yes"
        end repeat
      end repeat
    end tell
  end if
end try
return hit
AS
}

# 屏幕锁着 / 在睡眠时就别弹了
screen_locked() {
  ioreg -n Root -d1 -a 2>/dev/null | grep -A1 "CGSSessionScreenIsLocked" | grep -q "<true/>"
}

ask() { # $1 标题 $2 正文 $3 取消按钮 $4 确认按钮
  afplay /System/Library/Sounds/Glass.aiff >/dev/null 2>&1 &
  osascript - "$1" "$2" "$3" "$4" <<'AS' 2>/dev/null
on run argv
  set r to display dialog (item 2 of argv) with title (item 1 of argv) buttons {item 3 of argv, item 4 of argv} default button 2 with icon note giving up after 300
  if gave up of r then return "timeout"
  return button returned of r
end run
AS
}

case "$MODE" in
  checkin)
    [ "$hour" -lt "$START_HOUR" ] || [ "$hour" -ge "$END_HOUR" ] && exit 0
    screen_locked && exit 0
    in_session && exit 0
    ans=$(ask "心流岛" "有一阵子没开始新一轮了。手机在手上吗？

放下它，开一轮 25 分钟。" "稍后" "开始专注")
    [ "$ans" = "开始专注" ] && open "$URL"
    ;;
  write)
    screen_locked && exit 0
    ans=$(ask "心流岛 · 写作" "今天的写作还没做吧？

花 10 分钟，写一段就好。" "今天写过了" "去写")
    [ "$ans" = "去写" ] && open "$URL#write"
    ;;
  anchor)
    screen_locked && exit 0
    in_session && exit 0
    ans=$(ask "心流岛 · 学习时间到" "${ANCHOR_PLACE:+去${ANCHOR_PLACE}，}先做 5 分钟热身。

不用想今天要学多久，只要开始就好。" "晚点" "开始热身")
    [ "$ans" = "开始热身" ] && open "${URL%#*}#warm"
    ;;
  test)
    echo "URL=$URL  时段=${START_HOUR}-${END_HOUR}点  在专注中=$(in_session && echo 是 || echo 否)  锁屏=$(screen_locked && echo 是 || echo 否)"
    ;;
esac
exit 0
