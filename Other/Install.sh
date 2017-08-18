#!/bin/bash

app_name="WeChat"
shell_path="$(dirname "$0")"
wechat_path="/Applications/WeChat.app"
framework_name="WeChatPlugin"
app_bundle_path="/Applications/${app_name}.app/Contents/MacOS"
app_executable_path="${app_bundle_path}/${app_name}"
app_executable_backup_path="${app_executable_path}_backup"
framework_path="${app_bundle_path}/${framework_name}.framework"

# 对 WeChat 赋予权限
if [ ! -w "$wechat_path" ]
then
echo "请输入密码对微信赋予权限"
sudo chmod -R 777 "$wechat_path"
fi

# 备份 WeChat 原始可执行文件
if [ ! -f "$app_executable_backup_path" ]
then
cp "$app_executable_path" "$app_executable_backup_path"
result="y"
else
read -t 10 -p "已经安装过微信小助手，是否覆盖？[y/n]:" result
fi

if [[ "$result" == 'y' ]]; then
    cp -r "./${shell_path}/Products/Debug/${framework_name}.framework" ${app_bundle_path}
    ./${shell_path}/insert_dylib --all-yes "${framework_path}/${framework_name}" "$app_executable_backup_path" "$app_executable_path"
fi
