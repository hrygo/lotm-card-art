# 精雕符号资产库

## 当前愚者途径视觉基线

当前入口是[五档资产目录](fool-five-tier-kit.json)。正式保留的层级物料位于
`artifacts/production/fool-five-tier-direct-kit-v1/`：五张 `1024×1536` 原生 Agentic
完整边框、[五档接触表](../../artifacts/production/fool-five-tier-direct-kit-v1/five-tiers.png)、
浅底诊断图和 `manifest.json`。当前映射固定为：低序列 09/08，中序列 07/06/05，圣者
04/03，天使 02/01，真神 00。

五档与十序列的统一活动入口为
[愚者分层资产基线](fool-layered-asset-baseline-v1.json)。它只引用上述五档完整框、十张
完整序列框和保留的融合圣徽参考，明确区分当前视觉基线与历史研究稿。

当前流程不保留中间 2K 图；五档源的宝石已直接嵌入完整 Agentic 画面，不另设钻石覆盖层，
也不生成五档×十序列交叉变体。正式卡牌仍需经过单卡内容、视觉批准和最终整幅 2K/4K
采样门禁。

母版原生视觉源为
`artifacts/production/fool-mother-frame-v1/studies/fool-mother-agentic-high-detail-candidate-n.png`；
十张完整序列框位于
`artifacts/production/fool-agentic-sequence-inscriptions-v2/studies/`。

## 融合圣徽参考

“途径标识 → 艺术数字 → Agentic 融合”的方法和 0–9 视觉族已保留在
[fool-fusion-family.json](fool-fusion-family.json)。每个数字当前只保留一个最新运行：
0、4、7、9 为 `v002`，1、2、3、5、6、8 为 `v001`。这些图像仍是带环境底色的视觉参考，
不是透明图层；当前母版顶部使用独立数字圆洞，不自动装配历史融合圣徽。

独立数字目录已退役；[fool-rank-numerals-v1.json](fool-rank-numerals-v1.json) 仅作退休记录。

## 生命周期与验证

明显旧四档、局部铭刻、2K 中间输出、早期候选和失败试装已按
[清理账本](../retirements/fool-failed-materials-2026-09-14.json) 移入 macOS Trash，保留可恢复性。
22 条途径的独立 `sigil-*` 原始目录、公共材质库和克莱恩主体候选未纳入本次层级清理。

当前基线检查：

```text
python3 tools/production.py check-fool-materials
python3 tools/production.py check-fool-cards
```

该检查核对现存正式物料的路径、SHA-256、原生尺寸、唯一运行目录、无中间 2K、序列一对一
映射和清理账本；历史目录中的旧路径只作为溯源，不会被当作当前生产输入。
`check-fool-cards` 另行核对当前 S09/S00 完整原生候选、任务/回执/叙事身份、摘要和待审状态；
它不会把机器通过或 Agentic 视觉候选自动升级为正式批准。
