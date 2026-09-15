# AGENTS.md — tests/ · 回归与反例测试

> 目录级契约：只约束 `tests/`；全局规则见根 `AGENTS.md`。
> Python 套件与 Swift 客户端套件是两条独立门禁，互不替代。

## 概览 OVERVIEW
- `tests/` 是 Python 回归 + 反例套件：`test_*.py` 平铺、无 `__init__.py`，由仓库根 `python3 -m unittest discover -s tests -v` 发现；用例以 `Path(__file__).resolve().parents[1]` 定位仓库根，执行目录无关。
- 套件必须 **0 failures / 0 errors**；CI（`.github/workflows/ci.yml`）在 ubuntu-latest、Python 3.10–3.14 矩阵（`fail-fast: false`）依次跑 `check --level scaffold` 与全套件。
- 门禁分三层：scaffold（结构）→ design（六维与证据）→ release（真实图像 + 人工批准）。刚检出时 design/release 失败是发布阻断预期，不是故障。
- `tests/WorldOfMysteries*Tests/` 目录为空；Swift 测试实际位于 `apps/WorldOfMysteries/Tests/`，用 `swift test` 运行，不计入 Python 套件。

## 查哪里 WHERE TO LOOK
| 关心点 | 测试文件 |
|---|---|
| cardctl 三级检查、brief、fingerprint、路径越界、JSON 严格性 | `test_cardctl.py` |
| production 任务契约、不可变输出、哈希锁、release 模式、shape 校验 | `test_production.py` |
| 五档→10 序列质量映射、narrative 批准、快照依赖 | `test_production_contracts.py` |
| 已交付 pilot 的隔离副本读通与篡改失效 | `test_production_pipeline.py` |
| 9–0 层级标签、半神/圣者/天使/真神、序列 0 政策 | `test_sequence_hierarchy.py` |
| 五档 retained 物料门禁（`check-fool-materials`） | `test_materials_pipeline.py` |
| 符号/徽记清单、精确计数、历史登记边界 | `test_symbols_library.py` |
| 愚者五档物料、三文字区、agentic 管线、材料基线 | `test_fool_five_tier.py`、`test_fool_three_text_zones.py`、`test_fool_agentic_pipeline.py`、`test_fool_material_validation.py` |
| 原生合成器像素回归（compose 后端） | `test_native_compositor.py` |
| Swift 客户端 Core/Features 领域与交互 | `apps/WorldOfMysteries/Tests/`（`swift test`） |

## 约定 CONVENTIONS
- 新增硬规则必须配对反例用例：正例断言直接通过，反例断言**具体错误码**（`validate_card` 返回的 `code` 集合）或异常类型（`cardctl.DataError`、`production.Invalid`），不写宽泛断言。
- 三层分别断言；伪造 `stage=approved` 也不得绕过 scaffold/design 检查（如 `release.review_missing` 类用例）。
- 合成 fixture 必须显式标注 SYNTHETIC / 非原著 / 非人工批准；记录字段通过只证明结构，不认证像素含义或真人签署。
- 写操作与工作流用例用 `tempfile.TemporaryDirectory()` + 仓库副本隔离（忽略 `__pycache__`、`reports`、`generated`、`SHA256SUMS`、`.build`）；清单/契约用例直接读仓库现值，并用 `subTest` 遍历目录项。
- 原生渲染用例实际 `swiftc` 编译并运行 `tools/render/*.swift`，断言退出码、stderr 关键字与探测器像素；溢出必须报错且不产出 `final.png`。
- macOS/Swift 用例必须以 `skipUnless(sys.platform == "darwin" and shutil.which("swiftc"))` 守卫；Linux CI 上缺依赖应 skip 而非 fail。
- 资产增删要同步 exact-count 契约（5 档、10 序列、10 徽记等）；交付物重生成要同步清单与回执哈希，否则报 `missing/stale`。
- 用例离线、零第三方依赖、不读 `.env`/key；除原生 Swift 与真实文件产物场景外，直接 `sys.path.insert(0, ROOT/'tools')` 导入工具模块做单元断言，命名区分正负例（`..._fails` / `..._rejected`）。

## 反模式 ANTI-PATTERNS
- 不为绿灯删弱断言、伪造审核/批准/退出码接住失败；synthetic 批准不得冒充真人。
- 不把 design/release 的预期阻断当代码故障修（应补研究、真实图像与审核，而非改测试）。
- 不用纯结构 JSON 检查冒充"图像表达清楚"与人工视觉审核。
- 不写依赖 `generated/`、`.build` 缓存、网络或密钥的用例。
- 不在无平台守卫的用例里直接调用 `swiftc`/macOS 工具（Linux CI 会失败）。
- 不把客户端 fixture 当作 220 卡事实核验；两条套件互不替代。

## 命令 COMMANDS
```bash
# 内容套件（仓库根；Python 3.10+，零第三方依赖）
python3 -m unittest discover -s tests -v
python3 tools/cardctl.py check --level scaffold
python3 tools/cardctl.py check --level design --card fool:09    # 未完成研究时预期失败
python3 tools/cardctl.py check --level release --card fool:09   # 无真实图档与批准时预期失败

# Swift 客户端套件（独立门禁）
cd apps/WorldOfMysteries && swift test
```