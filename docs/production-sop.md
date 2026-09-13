# Agentic 卡牌生产 SOP
版本：1.0.0。执行者：Codex；授权依据：本会话采用 SOP + 结构化资产 + Agent Skills 生图 + 合成程序 + 门禁。

## 路由
| kind | Skill | 输入关注点 |
| --- | --- | --- |
| foundation | .agents/skills/lotm-foundation/SKILL.md | 材质、光照、平铺约束、复用范围 |
| hierarchy | .agents/skills/lotm-hierarchy/SKILL.md | 四档层级、几何边界、透明/留白、路径变体 |
| subject | .agents/skills/lotm-subject/SKILL.md | slot / card / character、主事件、六维来源、人物参考 |

输入模板和 schema 位于 production/tasks/ 和 production/schemas/。三个示例都是可执行概念任务，不是正式批准资料。
220 是途径×序列的覆盖数；card_id 表示独立卡片，run_id 表示某次生成，不能把人物相同或 slot 相同视作同一卡片。

## 顺序
主角姓名是核心身份组件，与途径—序列印记、序列名并列。subject.spec.protagonist 必填 kind/name_zh/name_status/evidence_refs；真人物必须有 character_id，原型须明确 archetype。姓名只在主体身份中维护，合成 nameplate 只存位置、字体、字号和颜色，程序自动取 name_zh，禁止另写姓名文案。
姓名区在1000×1500设计坐标下至少32字号；姓名过长导致溢出时修改姓名区布局，不静默截断或缩成微字。正式人物姓名需 verified 且有证据引用；未知身份不得冒称原著人物。匿名原型显示明确的原型称谓。
1. 读取当前 Skill、任务 JSON；subject 加读来源 card/canon 与相关 design/ 文档。有参考图时先观察，再核验路径/哈希。
2. 执行 compile。任务编译生成不可覆盖的快照和提示词。production mode 的 subject 必须先过现有 design 门禁；concept 可以验证管线但不能发布。
3. 读取编译的 prompt.txt，并通过当前图像工具实际传递 references。不能以路径文字代替附件。调用参数与提示词必须保存。
4. 观察工具产物。将附件传递记录、真实工具、日期、未知 model/seed=null、观察写入调用记录。生成失败不伪造文件；单任务尝试次数不得超 limits.max_attempts。
5. ingest 把真实 PNG 复制入 artifacts/production/<task_id>/<run_id>/，记录哈希及原始像素。旧 run 不覆盖。
6. composition 清单引用已登记 receipts，指定层序、位置、裁切、矢量和精确文字。执行 compose，得到独立 final.png、preview.png 和制作回执。
7. 先隐藏计划观察图片，再对照设计。记录缩略图、文字、主事件、复合印记、层级和六维结果。Agent 观察不等于真实用户盲测。
8. gate 默认检查合成一致性；--release 追加事实、批准和旧 cardctl 门禁。concept、缺批准、摘要漂移均失败。

## CLI
```bash
python3 tools/production.py compile production/tasks/foundation-paper.json --out generated/production/paper-v1
python3 tools/production.py ingest generated/production/paper-v1 /absolute/path/to/raw.png production/calls/paper-v1.json --run v001
python3 tools/production.py compose production/compositions/fool-09-pilot.json --out artifacts/production/fool-09-pilot/v001
python3 tools/production.py gate artifacts/production/fool-09-pilot/v001
python3 tools/production.py gate artifacts/production/fool-09-pilot/v001 --release
```
工具仅复制明确指定的单张外部 PNG 到仓库；后续输入/输出引用必须在仓库内。输出限定 generated/production 与 artifacts/production，不执行任务文本里的命令。

## 合成程序
Python 管理路径、哈希、记录和门禁；tools/render/compose.swift 使用 AppKit / CoreText / ImageIO，首次由 swiftc 编译到 generated/production/bin。
JSON 矢量图元与 SVG 是可编辑正本。v1 图元支持 rect、ellipse、path（M/L/C/Z）和 text，图层支持 PNG cover/contain、opacity 与矩形裁切。坐标统一 1000×1500，y 向下。
输出尺寸读取 config/project.json 的 profile。艺术层重采样与文字矢量目标尺寸重绘分别记录，declared_native=false。字体实际替代会记入回执。
透明度只在输入真实含 alpha 时使用；不得把棋盘格当透明。层级栅格可作局部装饰，正式识别仍由矢量结构承载。
检验核心只依赖 Python 标准库；渲染要求 macOS 26+、Swift 工具链，不增加 pip 依赖。

## 状态和修订
任务 mode 是 concept/production，素材 approval 是 pending/approved/rejected，生成 run 与卡片生产阶段分别记录。
每个快照/素材/合成版本只追加。内容修改新建 revision；下游摘要失配必须重新编译/合成/审核。
独立 card_id 通过只读投影继承 slot 的语义方案，最终图和 review.json 绑定本卡身份；release 调用原有 validate_release 检查此投影，不覆盖旧 card.json。人物特定事实必须先进入来源方案，不能仅靠 character_id 推导。
compose 会生成未执行的 review.json 模板；填写实际观察及真实批准后运行 --release。素材另需 rights_status=cleared 和 rights_reference。合成 manifest 的 approval 为兼容预留，发布以实际 review.json 为准。
人工批准引用绑定当前输出哈希，机器只能检查记录一致性，不能认证审批人身份。
现有 approved 卡不因新管线上线而自动重写；旧 gate 仍是旧格式唯一入口，新任务使用本 SOP 双重检查。
