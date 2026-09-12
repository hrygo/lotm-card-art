# LotmCardStudio

本目录是《诡秘之主》卡牌画册的 macOS 原生客户端原型。

当前垂直切片包含：

- 书架画廊与动态身份卡数量；
- 详情页的大卡面、身份面板和故事抽屉；
- `card_id` / `character_id` 分离的领域模型；
- 人工批准摘要门槛；
- 本机 SpeechRail loopback HTTP 请求客户端；
- SpeechRail 不可用时仍可阅读文字稿。

当前界面使用隔离的示意内容，不代表正典卡牌已经完成或获得授权。

## 本地运行

```bash
swift test
swift run LotmCardStudio
```

构建本机 `.app`：

```bash
./scripts/build-app.sh debug
./scripts/build-app.sh release
```

首期目标是 Apple silicon。最低 macOS 版本和真实 SpeechRail 试听结果须以 QA 记录为准。
