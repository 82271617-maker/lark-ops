---
name: lark-ops
description: 让 AI 在飞书上完成「读文档/表格 → 抓网页链接 → 产出文案并写回飞书」的闭环。当用户说「读一下这个飞书文档/表格」「把网页整理成飞书文档」「把结果写进飞书」「发我飞书」「在飞书里做一份…」时使用。基于 lark-cli（用户身份读写）+ web_fetch（抓链接）。
---

# 飞书读写（读文档/表格 → 抓链接 → 写文案）

把飞书当输入和输出：文档读得了、表格读得了、网页抓得回来、结果写得回去。

## 两种接入形态（先分清）

| 形态 | 是什么 | 什么时候用 |
| --- | --- | --- |
| **A. lark-cli**（本技能主打） | 命令行，AI 直接调 API 读写 | 做内容、批量处理、结构化产出 |
| **B. DSH 飞书机器人** | 群里 @ 就干活，入口是 DSH 的飞书桥 | 团队在群里丢需求 |

B 的当前配置可以用工具 `lark_config_get` 读出来，关键字段：

- `groupPolicy: mention` —— 群里必须 @ 机器人才触发
- `groupKeywords: ["lark", "小斯"]` —— 或命中关键词
- `alsoOnReply: true` —— 引用机器人消息也能触发
- `credentialRef: LARK_LINK_APP` —— 凭据引用名

> 机器人身份看不到用户个人资源（日历、个人云文档），**读写用户文档必须用用户身份**（`--as user`）。这是最常见的困惑点。

## 前置检查（每次先做）

```bash
lark-cli --version                  # 需要 >= 1.0.50
lark-cli auth status                # 看 user 是否 ready
```

未安装：`npm i -g @larksuite/cli`

未登录：`lark-cli auth login`，按提示勾选权限模块（空格选择、回车确认）：

| 要做的事 | 必须勾选 |
| --- | --- |
| 读/写文档 | `docs` |
| 解析 wiki 链接 | `wiki` |
| 读/写表格 | `sheets` |
| 下载文档附件 | `drive` |
| 发消息 | `im` |

勾完会打开浏览器授权一次；`auth status` 显示 `user: ready` 才算好。

## 读

### 文档 / wiki

```bash
# wiki 链接先解析成 obj_token（拿到 obj_type 和 title）
lark-cli wiki +node-get --node-token "<wiki-url>" --as user

# 读正文（XML 默认；要 Markdown 加 --doc-format markdown）
lark-cli docs +fetch --api-version v2 --doc <obj_token|url> --as user

# 只要目录，别拉全文
lark-cli docs +fetch --api-version v2 --doc <token> --scope outline --max-depth 3
```

### 电子表格

```bash
# 1) 列出子表（拿 sheet_id）
lark-cli api GET "/open-apis/sheets/v3/spreadsheets/<spreadsheet_token>/sheets/query" --as user

# 2) 读区域（sheet-id 是子表 id，不是表格 token）
lark-cli sheets +csv-get --spreadsheet-token <token> --sheet-id <sheet_id> --range "A1:U60" --as user
```

### 附件 / 图片

```bash
# token 来自文档里的 <source token="..."> 或 <figure>
lark-cli docs +media-download --token <token> --as user --output ./out/file.txt
```

### 网页链接

先用 `web_fetch`；被拦或需要 JS 时退回 curl + 代理：

```bash
curl -s -x http://127.0.0.1:7890 -A "Mozilla/5.0 ..." "<url>" -o ./out/page.html
```

## 写

### 新文档

```bash
lark-cli docs +create --api-version v2 --as user --parent-position my_library \
  --content '<title>标题</title><p>正文</p><h1>小节</h1><ul><li>要点</li></ul>'
```

返回 `data.document.url`，把链接发回对话。

### 追加到已有文档

```bash
lark-cli docs +update --api-version v2 --as user --doc <url> \
  --command append --content '<h1>新增章节</h1><p>内容</p>'
```

### 精确改写某段

```bash
# 先取 block id
lark-cli docs +fetch --api-version v2 --doc <url> --detail with-ids
# 再按 block 改
lark-cli docs +update --api-version v2 --doc <url> --command str_replace \
  --block-id <blk> --content '<p>新内容</p>'
```

### 表格

```bash
lark-cli sheets +csv-put --spreadsheet-token <token> --sheet-id <id> --start-cell A1 --as user
```

## 标准动作：网页 → 飞书文档

```text
1. web_fetch 抓正文（失败 → curl + 代理）
2. 提炼结构：结论 / 证据 / 风险 / 行动（按用户要的形态）
3. 生成 XML（标题唯一、表格有表头、不编造数据）
4. docs +create → 拿 url
5. 把 url 发回对话，不伪造链接
```

## 排错表（都是真遇到的）

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `Unsupported document type 'sheet'` | 用 docs 接口读表格 | 改用 `sheets +csv-get` |
| `app_scope_not_applied: sheets:spreadsheet` | 机器人没开表格权限 | 换 `--as user`，或后台开 scope |
| `need_user_authorization` | 用户 token 过期 | `lark-cli auth login` 重新授权 |
| 浏览器打开私有仓库/文档 404 | 无权限时飞书/GitHub 都返回 404 而非 403 | 先查登录账号，再查共享权限 |
| `keychain ... operation not permitted` | 沙盒限制访问 Keychain | 在普通终端里跑 `auth login` |
| 写入成功但用户看不到 | 文档建在机器人空间 | 用 `--as user` 创建，或给用户授权 |
| `--spreadsheet` 被拒 | 参数名是 `--spreadsheet-token` | 按报错提示改名 |

## 边界

- **不删**用户文档/表格，不改历史内容；只做追加和明确指定的替换。
- 不把 token、app secret 写进文档或对话；凭据留在本机 `lark-cli` 存储里。
- 不编造链接、不假装读到了没读到的内容；读不到就说读不到，并给出需要什么权限。
- 表格写入前先读一次当前区域，确认不会覆盖别人正在维护的数据。

## 自检

```bash
lark-cli auth status | head -20                 # user: ready
lark-cli docs +fetch --api-version v2 --doc <任一可读文档> --scope outline
lark-cli sheets +csv-get --spreadsheet-token <token> --sheet-id <id> --range "A1:D5"
```

更多可复制命令见 `references/recipes.md`。
