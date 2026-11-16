#!/bin/bash
# 卸载心流岛 Mac 定时弹窗
for l in com.xinliu.checkin com.xinliu.write com.xinliu.anchor; do
  launchctl bootout "gui/$(id -u)/$l" 2>/dev/null || true
  rm -f "$HOME/Library/LaunchAgents/$l.plist"
done
rm -rf "$HOME/Library/Application Support/xinliu"
echo "已卸载"
