# 工具维护规则

Python 校验与编排只使用标准库，保持 Python 3.10+ 语法兼容，不引入自动联网、付费 API 调用或用户未授权的批量出图。用户授权的合成工具位于 `tools/render/`，使用 Swift/AppKit 原生 CLI；它只读取已校验的图层清单并输出 PNG。
检查结果必须区分结构、设计和发布；未知资料不能自动变成“不适用”，不得根据文件名假装图像已通过审核。
任何新增硬规则同步补反例测试。结构成功不能替代实际看图；源文件摘要不是身份认证。
相对路径必须防越界，不能由报告输出参数覆盖 card/canon；`brief` 只写 `generated/`，报告只写 `reports/`。
契约 pin 由 `tools/pin_seal.py` 单点重封存：`--check` 只检漂移（CI 使用，缺失文件按错误处理），`--write` 只改 `sha256` 字段、其余字节不动。`artifacts/**` 历史回执按其不可覆盖 provenance 语义排除，不参与重封存；活合同指 `production/**` 内人工维护的 `contracts[]`。
`tools/selfcheck.py` 是 fresh checkout 自证入口：`scaffold → pin 漂移 → 设计 token → 必需检查名契约 → 愚者门禁 → 全套单测`（7 步），全通过才退 0；`--list` 只列步骤不执行，`--root` 指定仓库根。打 tag 前跑它，不替代 CI。设计与契约规则不得只靠人记得运行：新增硬规则同时接进 `selfcheck.py` 与 CI，并补反例测试。
`tools/check_required_checks.py` 守卫 `.github/required-checks.json`：分支保护按『检查名』匹配，改了 workflow 里 job 的 `name` 而没有同步 ruleset，会让所有 PR 永久等待一个不会出现的检查（比失败更难排查）。因此必需检查只允许字面名字（禁止 `${{ }}` 插值——矩阵展开会改名），改名会被这个守卫在 CI 里直接判失败。改动 `.github/workflows/` 里 job name 的顺序是：先改契约与 ruleset，再改 workflow。
修复数据错误时给明确非零退出码，不隐藏异常；不要让模板里的未执行审核通过 release。
