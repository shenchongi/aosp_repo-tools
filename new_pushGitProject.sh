#!/bin/bash

set -e

IFS=$'\n'
manifest_path=default.xml 
project_local_root_path=/home/shenchong/MyData/android-aosp/aosp-13_r78 # 代码路径

# 获取GitLab用户名和密码（从环境变量获取）
gitlab_username="shenchong" # 如果未设置环境变量，则使用默认值
gitlab_password="5201314sc."

echo '' > "${project_local_root_path}/fail.txt"

# 定义一个函数来处理Git初始化和推送逻辑
initialize_and_push() {
    local url_name="$1"
    local local_path="$2"
    local local_remote="$3"

    echo "url_name: ${url_name}"
    echo "local_path: ${local_path}"
    echo "local_remote: ${local_remote}"
    
    cd "${project_local_root_path}/${local_path}"
    echo "path: ${project_local_root_path}/${local_path}"

    # 更安全地处理文件移动
    find . -name .gitignore -exec mv {} {}.bak \;
    # 更精确地删除.git目录
    if [ -d .git ]; then
        rm -rf .git
    fi
    
    git config --global user.name "${gitlab_username}"
    git config --global user.password "${gitlab_password}"
    git config --global credential.helper 'cache --timeout=6000'

    git init
    git remote add origin "http://192.168.100.222:4567/new-aosp-13-r78/${url_name}.git" # 替换为你的GitLab仓库地址
    git add .
    if ! git status --porcelain | grep -q .; then
        echo "在 ${local_path} 中没有发现需要提交的变更，将跳过此目录..."
        return
    fi
    git commit -m "Initial commit"
    git branch -M master

    git push -uf origin master || {
        echo "${url_name} ${local_path}" >> "${project_local_root_path}/fail.txt"
    }
    
    if [ $? -ne 0 ]; then
        echo "${url_name} ${local_path}" >> "${project_local_root_path}/fail.txt"
    fi
}

for line in $(grep "<project" "${manifest_path}"); do
    url_name=$(echo "${line}" | egrep -o "name=[-\"._a-zA-Z0-9/]*" | awk -F'=' '{print $2}' | sed 's@"@@g')
    local_path=$(echo "${line}" | egrep -o "path=[-\"._a-zA-Z0-9/]*" | awk -F'=' '{print $2}' | sed 's@"@@g')
    local_remote=$(echo "${line}" | egrep -o "remote=[-\"._a-zA-Z0-9/]*" | awk -F'=' '{print $2}' | sed 's@"@@g')

    [ ! "${local_path}" ] && local_path="${url_name}"
    [ ! "${local_remote}" ] && local_remote=origin

    initialize_and_push "${url_name}" "${local_path}" "${local_remote}"
done