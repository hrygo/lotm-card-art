# Agentic Production 实施结果
日期：2026-09-13。

已完成三类任务契约、三个仓库 Skills、离线任务编译与素材登记、Swift 原生合成、机器检验和真实三类素材试点。
入口：docs/production-sop.md。当前有效合成：
- artifacts/production/fool-09-pilot/named-v002/final.png
- artifacts/production/fool-09-pilot/named-collector-v002/final.png

四档矢量骨架：production/assets/tiers；愚者十个复合印记原型：production/assets/fool。
精确提示词和调用观察：production/calls；当前 PNG 原图、task、prompt、snapshot、receipt：artifacts/production/*/v004。
v001 是工具搭建时的历史产物；v002 对相同原图重新登记完整自包含快照，不代表再次生图。旧版本保留，当前依赖改变使旧快照按预期失效。
此轮真实生图共三次，均内置 imagegen；没有可用的模型/种子精确值，留 null。

## 实际观察
标准 360px 缩略图与收藏整图已观察：中文标题、当前艺术数字 9、帷幕根形和主体动作可见；人物/摆锤/纸面构成清楚的事件。边框完整。顶部装饰为深色不透明横条，与纸纹有可见接合，这属于下一轮美术融合改进点。
复合印记目前仍可看出数字和根形各自的线条，属于第一版可编辑字形，不能声称达到最终艺术融合质量或跨途径高辨识度。
旧版小句“静观微光，辨认未知。”为原创文案；新版已将这一区域改为核心主角姓名“无名占卜者”，因为主体为匿名原型，不能擅自标记克莱恩。
四档骨架与 0–9 字形可编辑，但尚未完成四档并排人工视觉批准与真实用户混淆矩阵。
六维来源中该卡仍有未研究内容，故样卡带 concept 标记，review.json 保持 not_run/pending。Agent 已观察的视觉结果写在本报告，不伪造正式六维通过或用户批准。

## 实现与限制
用户补充的主角姓名已进入 task schema、必需 nameplate、主体 Skill、SOP、合成与排版回执检查。正式角色必须有 character_id 和经核验姓名证据，原型必须显式标为 archetype。姓名版式字号至少32设计单位，本样卡为44；不允许在合成清单另写一个不同姓名。
视觉基线升级为 proposal-003，仍为 proposed。其变动使旧设计指纹失效；受影响卡须重审，旧样卡与素材登记版本保留。当前 v004 素材为同一组三次真实生成输出的重新绑定，不代表再次调用生图。
Python 核心仅标准库；Swift 合成调用系统 AppKit/CoreText/ImageIO；CGImageSource 实际解码输入。支持 PNG 栅格、矩形裁切、cover/contain、opacity、矢量 rect/ellipse/cubic path、中文文字自动换行和溢出阻断。
矢量和文字以目标尺寸重绘；艺术源图1024×1536，层级饰条2172×724。收藏图经过程序重采样，不是原生4K艺术细节。
字体使用 Songti SC，实际解析和字形 run 字体保存在 renderer.json；PNG 明确带 sRGB 标记。
素材 approval、rights 与最终 review 独立；正式门禁仍需原有 design 与 release 语义审核。当前概念样卡无法发布。

## 验证记录
2026-09-13 补齐主角姓名后本地运行：全量 unittest 79 项全部通过，无跳过；其中本轮新增24项（15项协议/姓名/路径/摘要，3项原生解码/中文/溢出，6项真实合成包隔离测试）。
scaffold 核对22途径、220卡位，0错误。标准/收藏两份合成 gate 均通过；概念样卡 --release 返回退出码2并明确阻断。三个仓库 Skills 的 quick_validate 均通过。
验证的是程序、合同与当前概念样卡文件，不是原著事实、用户盲测或正式美术批准。

## 下一次实际生产
选定任务类型，复制 production/tasks 中对应样例为新 task_id；填写 spec 和引用哈希，运行 compile 到新目录；Skill 执行实际生图，ingest 登记，组合 manifest 并 compose。
已有输出不能覆盖；版本更新使用新 out/run。相同原图与相同调用可再次登记依赖快照，reused_run 指向此前记录。
所有结构化规则都可以用于其他21条途径，但它们的实际根标识、独立0–9字形仍需要艺术创作和审核。
