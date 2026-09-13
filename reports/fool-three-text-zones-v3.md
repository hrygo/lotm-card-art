# 愚者侧铭文带与钻石嵌入 v3 交付记录

日期：2026-09-13

## 本次变更

- 左右铭文带由柱体主体宽度的 1.15 倍升级为 1.5 倍。
- 铭文带上移至无纹理立柱区，设计坐标为左 `[38,780,108,280]`、右 `[878,780,108,280]`。
- 文字安全区为左 `[50,796,84,248]`、右 `[890,796,84,248]`，侧铭文至少支持六字竖排。
- 侧铭文采用 Agentic 研究风格指导的精确字形浮雕：凹槽阴影、抬升边、刻面字面、边缘高光；禁止平直 CoreText 作为最终侧铭文层。
- 之前的 `fool-diamond-v2` 五档钻石研究稿不再只作展示参考，按登记 crop 去除黑底连通域后，成为五个透明钻石层并嵌入固定底部锚点。

## 结构化资产

| 类型 | 路径 | 状态 |
| --- | --- | --- |
| 铭文合同 | `production/symbols/inscriptions/fool-side-inscription-v1.json` | active-deterministic-style |
| 铭文 Agentic 研究稿 | `artifacts/production/fool-side-inscription-study-v1/raw.png` | pending-user-art-approval；reference-only |
| 铭文调用记录 | `production/calls/fool-side-inscription-study-v1.json` | 已登记 |
| v3 几何方向 | `production/symbols/quality-frame-three-text-direction-v3.json` | user-confirmed-design-direction |
| v3 文字模板 | `production/templates/card-text-panels-v3.json` | active-v3-template |
| v3 合成配方 | `production/symbols/recipes/fool-three-text-zones-v3.json` | active-deterministic-v3-recipe |

## 实际输出

- `artifacts/production/fool-five-tier-kit-v4/`：五档边框、10 枚单档圣徽、10 张带圣徽边框、5 个透明钻石层、钻石五档诊断图。
- `artifacts/production/fool-three-text-sample-v7/card.png`：序列九克莱恩·莫里亚蒂试装。
- `artifacts/production/fool-three-text-empty-v5/`：无角色姓名安全试装。
- `artifacts/production/fool-three-text-tier-v5-{low,mid,saint,angel,true-god}/`：五档铭文/姓名跨档试装。

## 实测门禁

- `foolkit5-v3 selftest`：通过，包含五档映射、alpha 稳定、研究钻石嵌入标记。
- `foolkit5-v3 gate ...fool-five-tier-kit-v4`：通过；10 compositions，zero geometry/placement drift，real alpha。
- `fooltext3-v3 selftest`：通过；1.5x side band、six-character inscription capacity、exact-glyph-relief。
- `fooltext3-v3 gate ...fool-three-text-sample-v7`：通过；中心误差不超过 1 final px，无溢出。
- `fooltext3-v3 gate ...fool-three-text-empty-v5`：通过；空姓名不绘制占位符。
- `python3 -m unittest tests.test_fool_three_text_zones tests.test_fool_five_tier -v`：20 tests，全部通过。
- `python3 -m unittest discover -s tests -v`：144 tests 中本任务相关测试通过；全量结果被工作区中用户并行修改的 `tools/production.py` 旧快照失配阻断（62 个错误/2 个断言失败），未修改该无关范围。
- `python3 tools/cardctl.py check --level scaffold`：通过；22 pathways、220 card slots、220 cards checked。
- `git diff --check`：通过。

## 状态边界

机器结构、像素、alpha、摘要和几何检查已通过；图像仍标记 `visual_status: pending`，不等同于用户对新铭文外观或正式 release 的最终批准。原 v1/v2 输出未覆盖，旧四档仍仅作历史记录。
