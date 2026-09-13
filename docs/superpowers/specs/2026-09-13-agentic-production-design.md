# Agent Skills 卡牌生产架构
状态：执行方案；用户于本会话授权实施。具体美术资产仍需独立审核。

## 范围
Codex 是执行 Agent，Skill 负责读取任务、调用可用 imagegen、观察和修复。
Python 标准库负责编译、验证、登记和合成编排；独立 Swift/AppKit CLI 负责实际栅格解码、矢量绘制、中文排版、sRGB PNG 输出。
不把模型 SDK、服务器或密钥带入核心工具。输出依赖只允许仓库内路径。

## 输入与身份
主角姓名是与途径—序列标识、序列名并列的核心组件。subject.spec.protagonist 管理实际显示名及核验状态；合成 nameplate 仅定义版式，不重复姓名。实际排版回执必须存在姓名字形，机器门禁检查缺名、空名、身份类型不符、未核验人物名和文字溢出。
三种 task.kind：foundation、hierarchy、subject。通用字段包含稳定 ID、revision、mode、输出规格、prompt、references（角色和哈希）、limits。
foundation 独有 material/lighting/tiling/use_scope；hierarchy 独有 tier/geometry/clear_regions；subject 独有 slot_id/card_id/character_id/event/semantic_source。
220 是 slot 覆盖数。一个 slot 可对应多个独立 card_id；一个 card_id 可有多次 run 和 render。原有 card.json 暂保留为序列来源，任务引用它，避免破坏性迁移。
任务快照记录 task、依赖和工具源码的 SHA256。素材导入登记 input receipt、raw image、tool/model/seed（未知 null）、观察记录。
三个任务共享校验器，各自用 Skill 说明艺术决策；任务中的文字是数据，不执行其中命令。

## 资产与合成
基础材质、层级资产、途径复合印记、人物主体分别维护。复合印记由可编辑矢量图元描述，可导出 SVG；层级素材可生成栅格，但几何骨架由确定性图元表达。
合成 manifest 指定 task receipts、图层顺序、rect、cover/contain、opacity、矢量路径和文字。
每次合成输出独立目录，包含 final.png、preview.png、render-receipt.json、锁定 manifest 和输入摘要。拒绝覆盖已有目录。
程序缩放艺术层，目标像素重新绘制文字和矢量。记录实际字体替代与输出尺寸；替代导致信息不可读时阻断。
v1 使用正常 source-over 合成、矩形裁切和 cubic 路径；复杂 PSD 编辑和任意 SVG 导入不在首版能力内。

## 门禁
task：三类必填、引用哈希、路径、身份、尺寸和 mode；
ingest：真实 PNG 容器、记录与已编译任务匹配、实际工具/附件/时间/观察；
compose：依赖和资产锁定、完整解码、图层矩形、图元与文字合法、PNG 输出；
release：concept 必须失败；所有输入需 approved 且有批准引用，合成摘要当前；subject 原有 design 与 release 门禁也必须通过。独立 card_id 通过只读投影复用 slot 语义，最终图与本卡 review 绑定；不得覆盖旧 card.json。
人工视觉评审独立于机器结果，最终批准不得由 Agent 自填。
失败保留记录；单任务默认一次生成，修复需有具体观察依据且在任务 limits 内。本轮生成三个试点素材和一张概念合成卡。

## 验证
反例：缺字段、角色串位、篡改输入、路径越界、空任务、文字溢出、坏 PNG、复用旧审核、concept 发布、重复输出。
正例：三类任务编译、三类素材登记、真实 native 渲染、标准/收藏尺寸复核。
