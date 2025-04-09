AOSP迁移工具，用于将AOSP源码迁移到私有GitLab中，并保留了repo拉取结构。
## 脚本说明：
1. makeGroup.sh：用于创建子群组和项目
2. new_pushGitProject.sh：用于上传源码到GitLab中
3. default.xml：示例文件，用于配置子群组和项目
4. 脚本执行时会自动创建子群组和项目，并且上传源码到GitLab中
5. 注意代码中的注释，里面的信息不要填错或者填漏了！
6. 已在AOSP Android13源码上测试通过

## 使用方法：
1. 找到aosp源码中的default.xml文件，默认路径在.repo/manifests
2. 将makeGroup.sh，new_pushGitProject.sh文件放入从aosp源码中的.repo/manifests文件夹中
3. 修改default.xml文件，如果修改请查看本仓库中的default.xml示例文件
4. GitLab中创建群组
5. 首先执行makeGroup.sh创建子群组和项目
6. 执行new_pushGitProject.sh上传源码
7. 上传完源码后在顶级群组中创建manifests项目，在初始化中将默认分支改成master，删除掉原来的分支------这一步一定需要注意
8. 拉取时候执行repo init -u <manifests项目url，最好使用ssh拉取>

### 执行脚本的时候一定要看我在脚本里面写的注释！里面的信息不要填错或者填漏了！
