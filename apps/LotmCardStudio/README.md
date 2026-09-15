# LotmCardStudio

`LotmCardStudio` 是《诡秘之主》卡牌画册的 macOS 原生客户端 M1 里程碑垂直切片。
它与仓库中的卡牌生产脚手架分层：客户端当前读取隔离的 Swift 示意 fixture，
不会把示意内容写回正典、证据或美术生产数据。

## 当前状态

已实现：

- 书架画廊与动态身份卡集合；一条序列允许 0…N 张卡，同一角色可有多张独立身份卡；
- 正式收藏、候选收藏、愿望清单三个独立入口；
- 大卡面、身份面板、六维语义回读和底部故事抽屉；
- 故事页提供开始/暂停/继续、停止、重播、上一个和下一个章节的完整播放闭环；
- 故事抽屉采用正常垂直布局流，主卡面、身份面板和故事内容不会互相覆盖；
- `card_id` / `slot_id` / `character_id` / `identity_slice_id` 的分离模型；
- 台词和章节的 `source_kind`、人工审核状态及内容摘要门槛；未批准内容不会进入播放列表；
- 本机 `http://127.0.0.1:8201` SpeechRail loopback 客户端；超时、输入边界、snake_case 健康响应和重定向防护；
- SpeechRail 不可用时保留文字稿，不伪造播放成功；
- 每个已批准章节的完整正文只发起一次 TTS 请求，并按内容摘要与音色复用合成音频，不按句拼接或重复生成结果；
- 原生 `Settings` 场景提供 SpeechRail 配置文件状态和 API key 录入；API key 保存到仓库外的本机 JSON 文件，不再访问旧钥匙串；
- S00「愚者先生」、S09「克莱恩·莫雷蒂」、序列之上·诡秘之主的「福生玄黄天尊」、序列之上·星界支柱的「上帝」与序列之上·现实支柱的「堕落母神」，以及永恒之暗、恶魔之父、毁灭天灾、失序者、知识之妖、光之钥六位「序列之上」旧日（九者为非序列卡位）已绑定当前生产源的原生候选卡图；十一张卡各有 6 条新版叙事文案与本地 WAV，S00 使用 `uncle_fu`、S09 使用 `dylan`，九位「序列之上」存在各用自定义 VoiceDesign 音色 `celestial-worthy`／`god-almighty`／`mother-goddess-depravity`／`eternal-darkness`／`father-of-demons`／`destruction-calamity`／`embodiment-of-disorder`／`demon-of-knowledge`／`key-of-light`，批准文本优先播放本地资源，缺失时才回退到 SpeechRail 合成；
- macOS 26-only 界面基线：`NavigationSplitView`、系统 toolbar/search，以及卡片、面板和操作控件的 Liquid Glass 交互材质；
- debug / release `.app` 打包脚本和本机 QA 记录。

当前使用 11 张隔离 fixture 卡：S09「克莱恩·莫雷蒂」、S00「愚者先生」，以及福生玄黄天尊、上帝、堕落母神、永恒之暗、恶魔之父、毁灭天灾、失序者、知识之妖、光之钥九位「序列之上」存在。十一张卡均绑定当前生产源的 1024×1536 原生候选卡图、六维回读、6 条新版叙事和 6 个本地 WAV；九位「序列之上」存在都不占 22×10 序列卡槽、也不降格为真神。视觉候选仍需用户单独复核，不自动计入正式卡牌。正义小姐不再进入 App fixture，但其 App 外源资产继续独立保留。
这不是 220 张正式卡牌、完整内容导入器或正典核验库。SwiftData 持久化、仓库导入、
批量正式资源导入、播放缓存和游戏规则仍属于后续里程碑。

## 本地运行

需要 macOS 26+ 和 Swift 6.2+ 工具链；本客户端不维护 macOS 26 之前的兼容路径，直接使用当前 macOS 的 SwiftUI 能力。
仓库当前在 Apple silicon arm64 环境以 macOS 26.6.2、Xcode 26.6、Swift 6.3.3 验证；
这不等于已经在 M1 实机上完成硬件验收。

```bash
cd apps/LotmCardStudio

# 运行客户端单元测试
swift test

# 直接运行 SwiftPM executable
swift run LotmCardStudio

# 构建本机 .app；参数只能是 debug 或 release
./scripts/build-app.sh debug
./scripts/build-app.sh release
open .build/LotmCardStudio.app
```

如果 `Resources/AppIcon.icns` 存在，打包脚本会将其复制到 `.app` 的资源目录；`Resources/CardArt/` 中的卡图和 `Resources/Audio/` 中的已批准试听音频也会随 `.app` 一起打包。图标不是测试运行的前置条件。

## SpeechRail 边界

- 客户端默认只访问本机 loopback `127.0.0.0/8` 或 `::1`，不调用云端，也不自动启动、停止或下载 SpeechRail。
- 访问 `/v1/audio/speech` 前只发送通过人工批准摘要校验的文本。
- 已打包的批准 WAV 优先本地播放；没有本地资源时才请求 `/v1/audio/speech`。
- 远程故事按章节作为单段音频生成；当前 SpeechRail 音频响应不携带章节时间轴，因此不把整篇音频伪装成可精确跳章的单轨。
- 本地服务失败时界面显示失败状态并继续展示文字稿；失败不计为完整播放。
- API key 由仓库外的 `~/Library/Application Support/LotmCardStudio/SpeechRail.json` 提供；启动和本地 WAV 播放不读取配置文件，只有远程合成前才懒加载。
- 当前运行路径不读取旧 Keychain 条目，因此不会再弹出“登录”钥匙串密码框；旧条目保持不变。

## 配置 SpeechRail 凭据

在应用菜单打开 `LotmCardStudio > Settings… > SpeechRail`：

1. 在 SecureField 输入 API key，点击“保存到配置文件”。输入会立即从界面状态清除，文件由应用写入 `0600` 权限。
2. 文件格式固定为：

   ```json
   {"apiKey":"替换为你的 SpeechRail API key"}
   ```

   也可以直接用文本编辑器编辑该文件；若手动创建，请将文件权限设为 `0600`。
3. 旧 Keychain 条目不会被读取、迁移或删除；因此旧“登录”钥匙串密码不同步不影响新配置。需要从 SpeechRail 服务端或原始配置来源取得 API key 后重新保存。
4. API key 缺失、配置文件无效或 HTTP 401 时，文字稿仍保留，并提示回到 Settings 配置；应用不会读取 `.env`、打印 key 或将 key 写入仓库 / `.app`。

## 验收记录

自动化测试、arm64 release 构建、画廊/清单切换、详情页、故事抽屉不重叠和 SpeechRail 失败回退记录在：

[`docs/qa/m1-local-run.md`](docs/qa/m1-local-run.md)

根目录的内容生产规则仍以 [`../../AGENTS.md`](../../AGENTS.md) 为准；客户端目录增量规则见 [`../AGENTS.md`](../AGENTS.md)。
