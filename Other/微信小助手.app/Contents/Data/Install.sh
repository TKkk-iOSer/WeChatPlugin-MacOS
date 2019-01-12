#!/bin/bash

wechat_path="/Applications/WeChat.app"

if [ ! -d "$wechat_path" ];then
wechat_path="/Applications/微信.app"
if [ ! -d "$wechat_path" ];then
echo -e "\n\n应用程序文件夹中未发现微信，请检查微信是否有重命名或者移动路径位置"
exit
fi
fi

app_name="WeChat"
shell_path="$(dirname "$0")"
framework_name="WeChatPlugin"
app_bundle_path="${wechat_path}/Contents/MacOS"
app_executable_path="${app_bundle_path}/${app_name}"
app_executable_backup_path="${app_executable_path}_backup"
framework_path="${app_bundle_path}/${framework_name}.framework"

# 对 WeChat 赋予权限
if [ ! -w "$wechat_path" ];then
sudo chown -R $(whoami) "$wechat_path"
fi

# 判断是否已经存在备份文件
if [ ! -f "$app_executable_backup_path" ];then
# 备份 WeChat 原始可执行文件
cp "$app_executable_path" "$app_executable_backup_path"
fi

cp -r "${shell_path}/${framework_name}.framework" ${app_bundle_path}
${shell_path}/insert_dylib --all-yes "${framework_path}/${framework_name}" "$app_executable_backup_path" "$app_executable_path"
