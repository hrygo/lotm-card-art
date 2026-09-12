# M1 本机验收记录

日期：2026-09-13

## 验收范围

- 书架画廊：动态身份卡数量、已确认/正式/候选统计和未填充卡位。
- 卡牌详情：大卡面、身份语义面板、故事抽屉与 SpeechRail 失败回退。
- 布局修复：故事抽屉作为详情主内容的垂直兄弟节点参与正常布局，不覆盖身份面板。

## 自动化结果

在仓库根目录的 `apps/LotmCardStudio` 执行：

```text
swift test
Executed 17 tests, with 0 failures
Target Platform: arm64e-apple-macos14.0
```

```text
./scripts/build-app.sh debug
输出：apps/LotmCardStudio/.build/LotmCardStudio.app
```

```text
./scripts/build-app.sh release
输出：apps/LotmCardStudio/.build/LotmCardStudio.app
产物：Mach-O 64-bit executable arm64
```

仓库级回归：

```text
python3 -m unittest discover -s tests -v
Ran 48 tests in 32.723s
OK
```

## 本机手动结果

- `.app` 可启动并显示书架画廊；统计数字显示为实际值，不再出现 Swift 插值字面量。
- “我的收藏”“候选收藏”“愿望清单”三个入口分别能筛出对应卡牌；未实现的途径入口明确置灰。
- 点击示意卡进入详情页后，主卡面与身份面板正常显示。
- 打开“查看故事”后，故事抽屉出现在身份面板下方并可通过滚动查看，没有容器重叠。
- 唤醒问候语失败时不会覆盖故事抽屉中的第三人称章节文字。
- 点击“唤醒卡牌”会真实尝试 loopback SpeechRail；本次服务端返回失败，界面显示 `SpeechRail 合成失败`，仍保留文字稿，未伪造播放成功。

## 环境与限制

- 本次执行主机为 Apple silicon arm64，实测系统为 macOS 26.5.1、Swift 6.3.3；不是 M1 实机验收，因此不能把本记录表述为 M1 硬件验证。
- 当前内容为示意 fixture，不代表 220 张正式卡牌或正典资料已完成核验。
- 尚未加入 Xcode 签名、正式资源导入、真实 SpeechRail 服务健康检查和发行包公证。
