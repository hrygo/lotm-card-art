# 开始制作：先选一张，不先填满220张

## 目标核对
要做的是独立、正视、高清的序列卡牌；每张包含六维语义；图像、文字、符号与风格按信息性质分工。
本次包不包含成品图。先验证设计体系，再逐张推进；不要将结构性占位误算为内容制作完成。

## 第一次任务
选择 `fool:09`。打开该卡的 `card.json` 和当前途径 `direction.json`。
阅读 `examples/fool-09-direction-study.md`：它展示如何设计，不提供未核验的完整设定。
在中文底本中核对名称、当前扮演原则、代表能力、关键魔药要素、进入本序列的条件及限制。
将真实发现添加到当前途径 `canon.json`，按 `templates/claim.json` 建立断言并关联来源。
所有核验动作使用实际章节位置；如果资料暂不可得，可以完成概念提案，但保留 research 阶段。

## 填写一张卡的顺序
先填写 `semantics` 的六条 `intent`、`claim_refs` 和知识状态，再写 `cues`，最后写 `composition`。
为每个维度明确 `fidelity` 和 `readback`；用 `carrier_ids` 指向画面中具体的cue。
不要先生成一张通用奇幻插画，再在说明文里声称六项都藏在其中。
文本cue写入 `exact_text`；其他cue描述实现，避免让提示词即兴创造原著细节。
填写 `composition.hero_event`、`why_this_sequence`、`focal_hierarchy`，确保当前卡不能被相邻序列简单替换。

## 运行与出图
`brief --draft` 可以在资料不全时生成研究任务。补完后使用无 draft 模式；未达design门槛时工具拒绝继续。
任务编译器生成的是可交给执行Agent的单卡说明，不是直接对某一家API适配的请求。
执行Agent需按实际图像工具组织输入和参考附件，并另外完成文字/边框合成与审图；本包没有API适配器。

## 文件产生以后
保存原图及处理记录到 `artifacts/<card_id>/v001/`，并更新card.json的production。
复制 `templates/review.json` 为该卡自己的review文件，逐项填写实际观察结果。
运行 `python3 tools/cardctl.py fingerprint --card fool:09`，把当前设计摘要绑定到审核记录。
检查原图与最终图的SHA256和像素；批准记录必须真实。通过release检查后才计入正式成品集。
下一张由 `next` 输出，并结合用户明确指定的卡推进，不因目录排序误跳序列。
