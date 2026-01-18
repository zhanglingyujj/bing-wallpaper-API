# 基于 Cloudflare Workers 和 D1 的 Bing 壁纸 API 项目

这是一个运行在 Cloudflare Workers 上的无服务器应用，它能自动抓取并归档必应（Bing）每日壁纸。项目使用 Cloudflare D1 数据库存储壁纸信息，并提供丰富的 API 接口供外部调用。

## 功能特性

*   **每日自动抓取**：通过 Cron 触发器，每天自动获取 Bing 最新壁纸并存入数据库。
*   **API 支持**：
    *   获取今日壁纸（支持重定向或返回 JSON 元数据）。
    *   获取随机历史壁纸（支持重定向或返回 JSON 元数据）。
    *   浏览历史壁纸归档（分页列表）。
*   **无服务器架构**：完全运行在 Cloudflare Edge 网络，速度快，成本低。
*   **SQLite 数据库**：使用 D1 (基于 SQLite) 存储数据，查询灵活。

## 部署指南

请按照以下步骤将项目部署到您的 Cloudflare 账户。

### 1. 环境准备

确保您的电脑上已安装：
*   [Node.js](https://nodejs.org/) (建议版本 v16 或更高)
*   npm (通常随 Node.js 一起安装)

### 2. 安装依赖

在项目根目录打开终端（命令行），运行以下命令安装 Wrangler (Cloudflare 的命令行工具)：

```bash
npm install
```

### 3. 登录 Cloudflare

如果您之前没有在本地登录过，请运行：

```bash
npx wrangler login
```

浏览器会弹出授权页面，请点击 "Allow" 授权 Wrangler 访问您的 Cloudflare 账户。

### 4. 创建 D1 数据库

我们需要创建一个 D1 数据库来存储壁纸数据。在终端运行：

```bash
npx wrangler d1 create bing-wallpapers
```

**关键步骤**：
命令执行成功后，终端会输出一段类似如下的信息：

```toml
[[d1_databases]]
binding = "DB"
database_name = "bing-wallpapers"
database_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

请复制其中的 `database_id` 值（即 `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` 部分）。

### 5. 修改配置文件

打开项目目录下的 `wrangler.toml` 文件：

1.  找到 `[[d1_databases]]` 配置块。
2.  将 `database_id` 的值替换为您在上一步复制的真实 ID。
3.  保存文件。

### 6. 初始化数据库表结构 (重要)

您需要为运行环境创建表结构。

**情况 A：如果您要部署到线上 (Deploy)**
```bash
npx wrangler d1 execute bing-wallpapers --remote --file=./schema.sql
```

**情况 B：如果您要在本地测试 (Dev)**
```bash
npx wrangler d1 execute bing-wallpapers --local --file=./schema.sql
```

> **注意**：如果遇到 `no such table: wallpapers` 错误，就是因为漏掉了这一步。

### 7. 部署项目

最后，将代码发布到 Cloudflare Workers：

```bash
npx wrangler deploy
```

部署成功后，控制台会显示您的 Worker 访问链接（例如 `https://bing-wallpaper.<您的子域名>.workers.dev`）。

---

## API 使用说明

假设您的 Worker 域名为 `https://bing-wallpaper.example.workers.dev`。

### 1. 获取今日壁纸

*   **图片重定向**：
    *   地址：`GET /` 或 `GET /latest`
    *   效果：直接跳转（302 Redirect）到 Bing 今日的高清壁纸图片 URL。适用于直接在 `<img>` 标签中使用。
*   **JSON 元数据**：
    *   地址：`GET /api/today`
    *   效果：返回今日壁纸的详细信息（日期、标题、版权、原始 URL 等）。
    *   响应示例：
        ```json
        {
          "date": "20231027",
          "title": "Autumn colors",
          "copyright": "© ...",
          "url": "/th?id=OHR.Example_EN-US123456789_1920x1080.jpg",
          "raw": { ... }
        }
        ```

### 2. 获取随机壁纸

*   **图片重定向**：
    *   地址：`GET /random`
    *   效果：从数据库已归档的壁纸中随机选一张，并跳转到图片 URL。
*   **JSON 元数据**：
    *   地址：`GET /api/random`
    *   效果：返回随机一张壁纸的详细元数据。

### 3. 获取归档列表

*   **列表查询**：
    *   地址：`GET /api/archive`
    *   参数：
        *   `page`: 页码（默认为 1）
        *   `limit`: 每页数量（默认为 10）
    *   示例：`https://.../api/archive?page=1&limit=20`
    *   效果：返回按日期倒序排列的历史壁纸列表。

## 自动更新机制

项目配置了 Cron Triggers（定时触发器），设置在 `wrangler.toml` 中：
```toml
[triggers]
crons = ["0 8 * * *"]
```
这意味着 Worker 会在每天 **UTC 时间 08:00**（北京时间 16:00）自动运行一次，检查并抓取 Bing 最新的壁纸存入数据库。

> **注意**：刚部署时数据库是空的。您可以手动访问一次 `/api/today`，这会触发一次即时的抓取并写入数据库操作，之后即可使用 `/random` 等功能。
