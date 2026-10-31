# lark-ops

让 AI 在飞书上完成闭环：**读文档 / 读表格 → 抓网页链接 → 产出文案并写回飞书**。

一个 DSH 技能 + 一份实测过的命令清单。基于 [lark-cli](https://github.com/larksuite/cli)（用户身份读写）+ web_fetch。

## 安装

```bash
git clone https://github.com/82271617-maker/lark-ops.git ~/lark-ops
bash ~/lark-ops/install.sh
```

装完开新会话，「读一下这个飞书文档」「把网页整理成飞书文档」这类话就会触发技能。

## 前置

```bash
npm i -g @larksuite/cli      # 没装过 lark-cli
lark-cli auth login          # 勾选 docs / wiki / sheets / drive
lark-cli auth status         # user: ready 才算好
```

权限模块对照：

| 要做的事 | 勾选 |
| --- | --- |
| 读/写文档 | `docs` |
| 解析 wiki 链接 | `wiki` |
| 读/写表格 | `sheets` |
| 下载附件 | `drive` |
| 发消息 | `im` |

## 能做什么

| 动作 | 命令 |
| --- | --- |
| 解析 wiki 链接 | `lark-cli wiki +node-get --node-token <url> --as user` |
| 读文档 | `lark-cli docs +fetch --api-version v2 --doc <token>` |
| 读表格 | `lark-cli sheets +csv-get --spreadsheet-token <t> --sheet-id <id> --range A1:U60` |
| 下载附件 | `lark-cli docs +media-download --token <t> --output ./x.txt` |
| 写新文档 | `lark-cli docs +create --api-version v2 --content '<title>…</title><p>…</p>'` |
| 追加内容 | `lark-cli docs +update --doc <url> --command append --content '…'` |
| 写表格 | `lark-cli sheets +csv-put --spreadsheet-token <t> --sheet-id <id> --start-cell A1` |

完整清单见 `.agents/skills/lark-ops/references/recipes.md`。

## 一个关键认知

> **机器人身份看不到用户的个人文档/日历**，读写用户资源必须 `--as user`。
> 机器人只在「群里被 @」这种场景有用，配置入口是 DSH 的飞书桥（`lark_config_get` 可读）。

## 边界

- 不删用户文档、不改历史内容，只做追加和明确指定的替换。
- 不把 token / app secret 写进文档或对话。
- 读不到就直说读不到，并说明缺哪个权限，不编造内容。

## License

MIT
