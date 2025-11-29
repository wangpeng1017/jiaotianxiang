# GitHub 推送指南

## 使用 Personal Access Token 推送代码

已经生成了 GitHub Personal Access Token，现在需要使用它来推送代码。

### 方法一：使用 Git Credential Manager（推荐）

在终端中运行：
```bash
git push -u origin main
```

当提示输入用户名和密码时：
- Username: `wangpeng1017`
- Password: **粘贴你刚才复制的 GitHub Token**（不是你的 GitHub 密码）

### 方法二：在 URL 中包含 Token

```bash
git remote set-url origin https://TOKEN@github.com/wangpeng1017/jiaotianxiang.git
```

将 `TOKEN` 替换为你的实际 token，然后运行：
```bash
git push -u origin main
```

### 方法三：使用 Git Credential Helper

已经配置了 Windows Credential Manager。首次推送时输入 token，之后会自动保存。

## 注意事项

⚠️ **安全提醒**：
- Token 已保存在剪贴板，可以直接粘贴
- Token 只显示一次，请妥善保存
- 不要将 token 提交到代码仓库
- `.gitignore` 已配置，会自动排除敏感文件

## 推送后的下一步

代码推送成功后，我们将：
1. 在 Leaflow 平台创建应用
2. 从 GitHub 仓库部署
3. 配置环境变量和服务
