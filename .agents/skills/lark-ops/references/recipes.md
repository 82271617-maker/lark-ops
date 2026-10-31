# 可复制命令清单（都实测过）

## 0. 认证

```bash
lark-cli --version
lark-cli auth status
lark-cli auth login          # 交互：空格勾选 docs/wiki/sheets/drive，回车确认，再去浏览器授权
```

自检通过的样子：

```
user: ready
```

## 1. wiki 链接 → 文档内容

```bash
# 解析节点（拿 obj_token / obj_type / title）
lark-cli wiki +node-get --node-token "https://xxx.feishu.cn/wiki/<node>" --as user

# 读全文
lark-cli docs +fetch --api-version v2 --doc <obj_token> --as user

# 只要目录
lark-cli docs +fetch --api-version v2 --doc <obj_token> --scope outline --max-depth 3

# 按关键词定位
lark-cli docs +fetch --api-version v2 --doc <obj_token> --scope keyword --keyword "预算|排期"
```

## 2. 表格读写

```bash
# 子表列表
lark-cli api GET "/open-apis/sheets/v3/spreadsheets/<token>/sheets/query" --as user

# 读区域
lark-cli sheets +csv-get --spreadsheet-token <token> --sheet-id <sheet_id> --range "A1:U60" --as user

# 整块写入（从 A1 开始）
lark-cli sheets +csv-put --spreadsheet-token <token> --sheet-id <sheet_id> --start-cell A1 --as user
```

⚠️ 参数名是 `--spreadsheet-token`，不是 `--spreadsheet`；`--sheet-id` 必填。

## 3. 附件下载

```bash
lark-cli docs +media-download --token <file_token> --as user --output ./out/file.txt
```

`file_token` 来自文档里的 `<figure><source token="..."/></figure>`。

## 4. 写文档

```bash
# 新建（XML）
lark-cli docs +create --api-version v2 --as user --parent-position my_library \
  --content '<title>标题</title><p>正文</p>'

# 追加
lark-cli docs +update --api-version v2 --as user --doc <url> \
  --command append --content '<h1>新章节</h1><p>内容</p>'

# 精确替换（先取 block id）
lark-cli docs +fetch --api-version v2 --doc <url> --detail with-ids
lark-cli docs +update --api-version v2 --doc <url> \
  --command str_replace --block-id <blk> --content '<p>新内容</p>'
```

返回里 `data.document.url` 就是要发回对话的链接。

## 5. 抓网页（不依赖飞书）

```bash
# 常规
# 用 web_fetch 工具（Agent 侧）

# 被拦 / 需要代理
curl -s -x http://127.0.0.1:7890 -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  "<url>" -o ./out/page.html
```

## 6. 常见报错 → 处理

| 报错 | 处理 |
| --- | --- |
| `Unsupported document type 'sheet'` | 走 `sheets`，不要走 `docs` |
| `message: specift at least one of --sheet-id or --sheet-name` | 补 `--sheet-id` |
| `need_user_authorization` | `lark-cli auth login` |
| `app_scope_not_applied` | 换 `--as user` |
| `code: 3380002` | 文档类型不匹配（sheet/docx 混用） |
| 404 | 无权限时飞书也返回 404，先查账号与共享设置 |
