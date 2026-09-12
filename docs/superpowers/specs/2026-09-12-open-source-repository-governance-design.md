# 开源仓库治理初始化设计

## 目标

将 `hrygo/lotm-card-art` 建设为一个可公开协作、可复现检查、权利边界清楚的 GitHub 仓库，同时保持项目当前“Python 3.10+、标准库、无外部依赖、先研究后制卡”的定位。

## 当前背景

- 仓库已有 `main` 分支、公开 GitHub 远端和 220 个序列卡位脚手架。
- 当前没有社区健康文件、贡献入口、Issue/PR 模板、CI 或 Dependabot 配置。
- 项目包含两类内容：`tools/`、`tests/` 中的原创软件代码；以及围绕《诡秘之主》的设定字段、视觉提案、模板和研究说明。
- 根项目规则明确：现有内容不代表官方授权，不应把未核验设定、图像或批准记录包装成已完成事实。

## 许可证与权利边界

采用已确认的分层方案：

1. `LICENSE-CODE.md` 使用 MIT，适用范围明确限定为本项目原创软件代码，主要包括 `tools/` 和 `tests/`，以及未来明确标注为代码的文件。
2. `NOTICE.md` 说明仓库不是对《诡秘之主》及其角色、世界观、名称、原著文本或第三方素材的再授权；主题内容不额外授予复制、改编、商业使用或素材再分发许可。
3. `README.md` 增加“许可与权利”入口，避免 GitHub 页面或读者将代码许可证误解为全仓库许可证。
4. MIT 版权标识使用仓库维护者 GitHub 身份 `Hrygo`，年份为 2026；不公开提交邮箱或其他私人联系方式。

不添加一个无范围说明的根目录 `LICENSE`，也不使用全仓库 MIT，避免产生覆盖第三方知识产权内容的错误暗示。

## 总体方案

治理配置分成四个边界，文件各自只承担一个职责：

### 1. 社区规则与维护入口

新增：

- `CONTRIBUTING.md`：贡献前检查、单卡工作流、证据与版权要求、运行检查命令、提交和 PR 约定。
- `CODE_OF_CONDUCT.md`：中文社区行为标准、执行范围和私下报告路径。
- `SECURITY.md`：禁止公开披露凭据，使用 GitHub 私密漏洞报告能力，报告时提供影响范围、复现步骤和修复建议。
- `SUPPORT.md`：问题分流规则；使用 Issue 讨论可复现问题和项目改进，不把安全事件或原著全文放入公开讨论。
- `LICENSE-CODE.md`：原创代码的 MIT 文本和范围说明。
- `NOTICE.md`：第三方 IP、素材授权、研究证据和本项目原创内容边界。

### 2. 协作输入质量

新增：

- `.github/ISSUE_TEMPLATE/bug.yml`：检查器、任务编译器或数据结构问题的结构化表单。
- `.github/ISSUE_TEMPLATE/content-evidence.yml`：设定、来源或语义表达问题的结构化表单，要求标明作品范围、来源状态和事实/解释区分。
- `.github/ISSUE_TEMPLATE/config.yml`：关闭空白 Issue，提供贡献指南、安全政策和支持入口。
- `.github/PULL_REQUEST_TEMPLATE.md`：变更范围、证据、测试、版权和六维语义影响清单。
- `.github/CODEOWNERS`：默认由 `@hrygo` 负责审阅仓库变更。

Issue Forms 只收集必要信息，不自动添加未在仓库中确认存在的 label，也不要求贡献者填写私人邮箱。

### 3. 可重复检查与依赖维护

新增：

- `.github/workflows/ci.yml`：在 `push`、面向 `main` 的 `pull_request` 和手动触发时运行。
  - 使用 `ubuntu-latest`。
  - 测试 Python `3.10`、`3.11`、`3.12`、`3.13`、`3.14`。
  - 使用 `actions/checkout` 和 `actions/setup-python` 的当前稳定 major tag，由 Dependabot 跟踪更新。
  - 运行 `python tools/cardctl.py check --level scaffold`。
  - 运行 `python -m unittest discover -s tests -v`。
  - 设置 `permissions: contents: read`、并发取消旧运行和 job 超时，避免不必要的权限和资源消耗。
- `.github/dependabot.yml`：只跟踪 GitHub Actions，每周生成更新 PR；当前无 `requirements.txt`、`pyproject.toml` 或其他第三方依赖清单，不虚构 pip 依赖生态。
- `.editorconfig`：统一 UTF-8、LF、末尾换行、JSON/Python/Markdown 缩进约定。
- `.gitattributes`：标记文本文件、统一换行，并将未来的 PNG 等二进制资源标记为 binary。

不引入 pre-commit、Ruff、pytest、打包元数据或第三方 CI 依赖；项目已有标准库检查器和 `unittest`，保持贡献者零安装成本。

### 4. GitHub 仓库设置

配置文件提交并通过 CI 后，使用已授权的 GitHub 管理入口应用以下设置：

- 保持 `main` 为默认分支。
- 启用 Issues。
- 关闭 Wiki，避免文档分散在仓库之外。
- 开启合并后自动删除 head branch。
- 开启 Dependabot alerts 和 automated security fixes（若当前账户/仓库能力允许）。
- 依赖公开仓库平台提供的 secret scanning；不在仓库中保存任何 token 或凭据。

本阶段不启用要求 PR 才能合并的分支保护或规则集，不设置强制审阅人数，避免维护者在单人生产阶段被自己配置阻塞。贡献量增加后单独评估规则集。

## README 调整

只增加面向公开协作所需的入口，不重写现有项目事实：

- 在顶部增加 CI 状态链接。
- 增加“参与贡献”“报告安全问题”“获得支持”“许可与权利”链接。
- 明确当前是制作脚手架，不是 220 张完成卡面、完整原著核验库或官方授权素材包。
- 保留现有命令和“design/release 在空脚手架阶段应失败”的说明。

不增加“全仓库 MIT”徽章，不宣称作品设定或视觉素材已获得授权。

## 不在本阶段做的事项

- 不创建 Python 可安装包、PyPI 发布流程或版本自动发布。
- 不添加 CodeQL、Scorecard、复杂供应链证明或第三方扫描器；当前没有服务端、依赖网络或发布制品，收益不足以抵消维护成本。
- 不自动生成 Issue label、项目看板、Wiki 页面或讨论区内容。
- 不修改 `card.json`、`canon.json`、视觉方向、原著证据、图片资产或现有测试逻辑。
- 不替用户选择商用授权、原著许可、字体许可或图像素材许可。

## 验收标准

### 文件验收

- GitHub Community Health 能识别行为准则、贡献指南、安全政策和 Issue/PR 模板。
- README 的许可证表述不会把 MIT 误读成全仓库授权。
- `.gitignore` 继续排除 `.omo/`、`.DS_Store`、环境文件和派生任务快照。
- 新增 YAML、Markdown 和配置文件不包含 token、密码、私钥、个人邮箱或未经授权的原著长摘录。

### 自动化验收

- `python3 tools/cardctl.py check --level scaffold` 通过并报告 220 个卡位。
- `python3 -m unittest discover -s tests -v` 报告 48 项测试、0 个失败。
- CI workflow 的触发器、矩阵、最小权限和命令与本地项目说明一致。
- Dependabot 配置是合法的 version 2 格式，并只声明 `github-actions` 生态。

### 远端设置验收

- GitHub API/CLI 查询确认仓库公开、默认分支为 `main`、Issues 开启、Wiki 关闭、合并后删除分支开启。
- 本地 `main` 与 `origin/main` 指向同一提交，新增治理改动通过一次独立提交推送。

## 依据

- GitHub 社区健康文件与模板：<https://docs.github.com/en/communities>
- GitHub Issue Forms：<https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms>
- GitHub Python Actions：<https://docs.github.com/en/actions/tutorials/build-and-test-code/python>
- GitHub Actions Dependabot：<https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/auto-update-actions>
- GitHub 安全能力：<https://docs.github.com/en/code-security/getting-started/github-security-features>
