#!/bin/bash

# 定义变量
# 使用方式: upload.sh -u <用户名> -p <密码> -r <仓库URL>
while getopts ":r:u:p:" opt; do
   case $opt in
           r) REPO_URL="$OPTARG"
           ;;
           u) USERNAME="$OPTARG"
           ;;
           p) PASSWORD="$OPTARG"
           ;;
   esac
done

# 检查必要参数
if [[ -z "$REPO_URL" || -z "$USERNAME" || -z "$PASSWORD" ]]; then
    echo "用法: $0 -u <用户名> -p <密码> -r <仓库URL>"
    echo "示例: ./upload.sh -u admin -p admin123 -r https://nexus.jtx-biotech.com/repository/maven-releases/"
    exit 1
fi

# 执行上传命令
# 查找当前目录及子目录下的所有.jar文件（排除一些无关文件）
find . -type f -name "*.jar" -not -path '*/\.*' | sed "s|^\./||" | while read -r file; do
    echo "正在上传: $file"
    # 使用curl的PUT命令上传文件
    curl -u "$USERNAME:$PASSWORD" -X PUT -T "$file" "${REPO_URL}/${file}"
    echo "" # 换行
done

echo "批量上传完成！"