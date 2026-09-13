# apps/ 目录工作约定

## 范围与当前状态

本目录承载《诡秘之主》卡牌画册的 macOS 客户端代码、资源和运行说明。
当前 `LotmCardStudio` 已完成 M1 里程碑原生垂直切片：画廊、详情页、三类清单、故事抽屉和 SpeechRail 接口均可运行。
导入、SwiftData 用户库、批量正式资源、音频缓存和卡牌游戏规则尚未实现；当前仅含 S00 一组用户批准的本地试听音频 fixture，不要把 M1 fixture 描述为完整产品。

### macOS 开发基线

- 客户端最低部署版本为 macOS 26 Tahoe；不维护 macOS 14 兼容路径或旧系统 fallback。
- 面向当前 SDK 直接使用 macOS 26 的 SwiftUI 能力，包括 Liquid Glass、系统导航、toolbar 和搜索语义；只有目标高于 macOS 26 时才增加显式可用性分支。
- 构建、QA 和 `.app` 元数据必须以 macOS 26.0 为最低版本，不能用宿主机能运行作为 deployment target 已切换的替代证据。

## 数据边界

- 客户端示意内容必须保持为合成 fixture，不得冒充已核验正典、正式卡牌或人工批准素材。
- `card_id`、`slot_id`、`character_id`、`identity_slice_id`、内容状态和叙事审批状态各自承担独立职责。
- App 是内容源的运行时投影；不得把用户收藏、笔记、密钥、缓存或运行状态写回公开卡牌源文件。
- SpeechRail 仅允许本机 loopback（默认 `http://127.0.0.1:8201`），不调用云端，不自动启动/停止/下载服务。
- 未通过人工批准摘要校验的台词或章节不得播放；服务失败时保留文字稿，不伪造播放成功。

## UI 施工约定

- 详情页的主卡面、身份面板和故事抽屉必须使用正常布局流；不得用固定高度、绝对定位或隐式叠放掩盖容器重叠。
- 故事抽屉独立维护章节显示文本，唤醒问候语不能覆盖第三人称故事文字。
- 同一角色可以有多张独立身份卡；聚合展示不能合并 `card_id`、收藏记录或播放状态。
- 新增交互优先补领域/视图模型测试，再修改界面；避免空操作按钮，未实现的途径入口应明确置灰。

## 验证与提交

- 在 `apps/LotmCardStudio` 执行 `swift test`、`./scripts/build-app.sh debug` 和 `./scripts/build-app.sh release`。
- 修改布局或播放流程后，必须进行一次 `.app` 手动验收，并更新 `LotmCardStudio/docs/qa/m1-local-run.md` 或对应阶段记录。
- `.build/`、`.swiftpm/` 和本机签名产物是生成物，不提交到 Git；资源文件是否存在必须由打包脚本显式处理。
- 不在客户端源码、fixture 或日志中写入令牌、私钥或真实人物隐私资料；API key 不从 `.env` 自动读取。
