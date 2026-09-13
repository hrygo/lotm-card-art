# Klein Seer 单卡执行计划

执行更新（2026-09-13）：下方清单保留初始方案；用户已改为人物与背景一体生成，并要求调整顶部框徽结合。当前试装已交付至 `artifacts/production/klein-seer-crest-study-v2/`；测试与审图结果以 `docs/research/2026-09-13-klein-integrated-crest-study.md` 为准。专用门禁通过，全库8项历史依赖过期错误仍在；未批准，未固化新SOP。

**Goal:** 交付一张克莱恩序列9独立卡牌候选，不自动批准发布。
**Architecture:** 新增隔离的单卡原生合成器，固定原框徽、遮罩、采样与姓名内区；生成纹理与场景不提供定位结构。旧合成程序、框徽和历史回执不改。
**Tech Stack:** Swift/AppKit/CoreText/ImageIO/CryptoKit；Python标准库测试；内置 image_gen。
**Spec:** `docs/pathway-carrier-sop.md` v0.2 与 `docs/research/2026-09-13-klein-seer-card.md`。

用户已授权在本会话执行，采用当前工作区的隔离新增文件，不切换分支、不提交、不新建并行任务。所引用的using-git-worktrees、subagent-driven-development和finishing-a-development-branch技能不在本次可用清单，沿用项目原生测试与交付流程。

## Tasks

- [x] 补齐单卡六维与中文来源，design 检查通过。
- [ ] 创建 `tests/test_klein_carrier.py`，测试原生合成器 `selftest` 返回结构移位、越界、采样、alpha与姓名居中正反例结果。实现前运行失败。
- [ ] 创建 `tools/render/klein_carrier.swift`：`prepare ROOT OUT` 导出冻结遮罩与参考；`render ROOT OUT BASE SCENE NAME` 输出独立层、最终图、诊断与摘要；`gate ROOT OUT` 按实际依赖重建并比较，禁止覆盖、越界和源摘要漂移。
- [ ] 运行原生测试并观察空载体诊断，通过后 compile→实际生图→观察→call→ingest，分别生成底材、主体、姓名；每个任务最多两次，不扩大到其他卡。
- [ ] 执行 render / gate，检查全图、768px与姓名细节；必要时只返修缺陷层。
- [ ] 运行全库 unittest、scaffold、design及差异检查，保存实际审图和未批准状态，不用专用 gate 冒充旧 release。

## 测试与接口

```python
result = subprocess.run([binary, 'selftest'], capture_output=True, text=True)
assert result.returncode == 0
assert json.loads(result.stdout)['passed'] is True
```

反例覆盖：实际像素移动1px、内部结构变化、隐藏域贡献、半透明边缘污染、源摘要错误、输出覆盖；正例覆盖：冻结区域内合法材质和姓名透明留白不影响本体定位。自动测试只证明实现覆盖的确定性链；复制框与材质接合仍需实际视觉拒收。

```bash
python3 -m unittest discover -s tests -p test_klein_carrier.py -v
python3 -m unittest discover -s tests -v
python3 tools/cardctl.py check --level scaffold
python3 tools/cardctl.py check --level design --card fool:09
git diff --check
```
