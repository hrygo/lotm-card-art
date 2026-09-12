# 开源仓库治理初始化实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 hrygo/lotm-card-art 建立可公开协作、可重复检查、权利边界清楚的 GitHub 开源仓库基础设施。

**Architecture:** 将治理拆成政策文档、协作输入、自动化检查和 GitHub 远端设置四个边界。仓库继续保持 Python 3.10+、标准库、无第三方依赖；原创代码与《诡秘之主》相关主题内容采用分层权利声明。

**Tech Stack:** Markdown、YAML、GitHub Actions、GitHub Dependabot、GitHub CLI、Python unittest、现有 tools/cardctl.py。

**Spec:** docs/superpowers/specs/2026-09-12-open-source-repository-governance-design.md

## Global Constraints

- 项目最低 Python 版本为 3.10+；不得因为仓库治理引入运行时依赖。
- CI 矩阵固定覆盖 3.10、3.11、3.12、3.13、3.14，运行现有脚手架检查和 48 项 unittest。
- LICENSE-CODE.md 的 MIT 许可只覆盖明确属于本项目原创软件的代码，NOTICE.md 不对主题内容和第三方 IP 额外授权。
- 不修改 card.json、canon.json、视觉方向、原著证据、图片资产或现有测试逻辑。
- 不添加 Python 包发布、pre-commit、Ruff、pytest、CodeQL、Scorecard、供应链证明或第三方扫描依赖。
- GitHub Actions 使用最小 contents: read 权限、并发取消旧运行和 job 超时。
- Issue Forms 不引用未确认存在的 label，不索取私人邮箱，不接收原著长摘录或秘密材料。
- 持久化文档使用普通 python3、git、gh 等可移植命令，不写入本机工具缓存绝对路径。

---

## 文件清单与职责

### 政策和版权

- Create: LICENSE-CODE.md — 原创软件代码的 MIT 许可与范围。
- Create: NOTICE.md — 第三方 IP、素材、研究证据和主题内容边界。
- Create: CONTRIBUTING.md — 单卡工作流、证据规范、检查命令和 PR 规则。
- Create: CODE_OF_CONDUCT.md — 中文社区行为标准与执行入口。
- Create: SECURITY.md — 私密漏洞报告和凭据处理规则。
- Create: SUPPORT.md — 公开支持问题的分流方式。
- Modify: README.md — 增加 CI、贡献、支持、安全和许可证入口，不改写现有项目事实。

### 编辑器和 Git 约定

- Create: .editorconfig — UTF-8、LF、末尾换行和基础缩进。
- Create: .gitattributes — 文本/二进制属性与换行策略。

### GitHub 协作入口

- Create: .github/CODEOWNERS — 默认由 @hrygo 审阅。
- Create: .github/PULL_REQUEST_TEMPLATE.md — 变更、证据、测试和版权清单。
- Create: .github/ISSUE_TEMPLATE/config.yml — Issue 入口配置。
- Create: .github/ISSUE_TEMPLATE/bug.yml — 工具和数据结构问题表单。
- Create: .github/ISSUE_TEMPLATE/content-evidence.yml — 设定、来源和六维语义问题表单。

### 自动化

- Create: .github/workflows/ci.yml — Python 版本矩阵和脚手架质量门禁。
- Create: .github/dependabot.yml — 每周更新 GitHub Actions 引用。

### 实施记录

- Create and commit: docs/superpowers/plans/2026-09-12-open-source-repository-governance.md — 本执行计划本身。

## 依赖关系

LICENSE-CODE.md 和 NOTICE.md 先确定 README、贡献指南和安全政策的权利用语；编辑器配置与 GitHub 模板互不依赖；CI 需要现有 tools/cardctl.py 和 tests/；远端设置必须在配置文件提交并推送后应用，最后用远端 API 核对。

### Task 1: 添加许可证、版权声明与社区政策

**Files:**
- Create: LICENSE-CODE.md
- Create: NOTICE.md
- Create: CONTRIBUTING.md
- Create: CODE_OF_CONDUCT.md
- Create: SECURITY.md
- Create: SUPPORT.md
- Modify: README.md

**Interfaces:**
- Consumes: 根 AGENTS.md、README.md、docs/LIMITATIONS.md、docs/DECISIONS.md、docs/source-policy.md。
- Produces: 所有公开协作入口可通过相对链接互相到达；代码许可和主题内容边界有单一、可复核的表述。

- [ ] **Step 1: 写入代码许可证**

LICENSE-CODE.md 使用标准 MIT 条款，开头增加以下范围说明，再放置完整的 MIT 授权正文：

~~~markdown
# MIT License — Original Software Code Only

Copyright (c) 2026 Hrygo

This license applies only to original software source code in this
repository, including tools/ and tests/, unless a file states a
more specific license. It does not grant rights to third-party works,
fictional settings, names, characters, quotations, or visual assets.
~~~

- [ ] **Step 2: 写入主题内容声明**

NOTICE.md 明确列出：《诡秘之主》及其角色、世界观、名称和原著文本属于相应权利人；仓库没有官方授权；sources/ 只记录研究范围和访问状态；references/ 的素材授权必须逐项核对；主题设定和视觉提案不因代码 MIT 而获得额外复制、改编、商业使用或再分发许可。

- [ ] **Step 3: 写入贡献指南**

CONTRIBUTING.md 至少包含以下固定流程：

1. 先阅读 AGENTS.md、pathways/AGENTS.md 和相关设计文档。
2. 单卡修改前确认 card.json、canon.json、sources/registry.json 的证据关系。
3. 对精确名称、配方、晋升条件和限制区分 canon、interpretation、knowledge_gap。
4. 运行 python3 tools/cardctl.py check --level scaffold 和 python3 -m unittest discover -s tests -v。
5. 不提交 .env、token、私钥、运行缓存、原著长摘录、无授权图片或伪造批准记录。
6. PR 说明动机、影响范围、证据来源、测试结果和未完成事项。

- [ ] **Step 4: 写入行为准则、安全政策和支持政策**

三份文件分别落实以下边界：

- CODE_OF_CONDUCT.md：尊重、就事论事、禁止骚扰和歧视；执行问题使用 GitHub 私密联系入口，不在公开 Issue 展开私人冲突。
- SECURITY.md：不要在公开 Issue、PR 或 Discussion 发布凭据；优先使用 GitHub 的私密漏洞报告；报告内容包括影响范围、复现步骤、受影响版本和修复建议；泄露凭据先撤销/轮换。
- SUPPORT.md：可复现的脚手架问题用 Issue；设定事实、来源和语义问题使用专门表单；使用问题前先阅读 README 和项目限制；安全事件不走公开 Issue。

- [ ] **Step 5: 更新 README 入口**

在标题附近增加只读 CI badge：

~~~markdown
[![CI](https://github.com/hrygo/lotm-card-art/actions/workflows/ci.yml/badge.svg)](https://github.com/hrygo/lotm-card-art/actions/workflows/ci.yml)
~~~

在现有“权利边界”附近增加相对链接：CONTRIBUTING.md、SECURITY.md、SUPPORT.md、NOTICE.md、LICENSE-CODE.md。保持现有脚手架状态、未完成卡面和非官方授权说明，不添加全仓库 MIT badge。

- [ ] **Step 6: 检查文档链接与敏感内容**

运行：

~~~bash
rg -n "LICENSE-CODE|NOTICE|CONTRIBUTING|CODE_OF_CONDUCT|SECURITY|SUPPORT" README.md CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md SUPPORT.md NOTICE.md
rg -n -i "gho_|github_pat_|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]+ PRIVATE KEY-----" LICENSE-CODE.md NOTICE.md CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md SUPPORT.md README.md
~~~

Expected: 第一条命令显示所有入口，第二条命令无匹配。

- [ ] **Step 7: Commit**

~~~bash
git add LICENSE-CODE.md NOTICE.md CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md SUPPORT.md README.md
git diff --cached --check
git commit -m "docs: add licensing and community policies"
~~~

### Task 2: 统一编辑器和 Git 属性

**Files:**
- Create: .editorconfig
- Create: .gitattributes

**Interfaces:**
- Consumes: 当前 Markdown、JSON、Python 文件布局和 .gitignore。
- Produces: 新贡献在常见编辑器中默认使用统一编码、换行和末尾换行；PNG 等未来制品不会被当作文本 diff。

- [ ] **Step 1: 写入 .editorconfig**

~~~ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2
trim_trailing_whitespace = true

[*.py]
indent_size = 4

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab
~~~

- [ ] **Step 2: 写入 .gitattributes**

~~~gitattributes
* text=auto eol=lf
*.md text
*.json text
*.py text
*.yml text
*.yaml text
*.png binary
*.jpg binary
*.jpeg binary
*.webp binary
~~~

- [ ] **Step 3: 验证属性和空白**

~~~bash
git check-attr text eol -- README.md config/project.json tools/cardctl.py artifacts/README.md
git diff --check
~~~

Expected: 文本文件显示 text: set 或由 text=auto 正确识别，二进制规则存在，命令无空白错误。

- [ ] **Step 4: Commit**

~~~bash
git add .editorconfig .gitattributes
git diff --cached --check
git commit -m "chore: standardize repository text attributes"
~~~

### Task 3: 添加 GitHub 社区协作模板

**Files:**
- Create: .github/CODEOWNERS
- Create: .github/PULL_REQUEST_TEMPLATE.md
- Create: .github/ISSUE_TEMPLATE/config.yml
- Create: .github/ISSUE_TEMPLATE/bug.yml
- Create: .github/ISSUE_TEMPLATE/content-evidence.yml

**Interfaces:**
- Consumes: CONTRIBUTING.md、SECURITY.md、SUPPORT.md、NOTICE.md。
- Produces: 新 Issue/PR 有足够上下文，安全事件有明确分流，默认审阅人是 @hrygo。

- [ ] **Step 1: 写入 CODEOWNERS 和 Issue 入口配置**

.github/CODEOWNERS 使用：

~~~text
# Default owner for repository changes
* @hrygo
~~~

.github/ISSUE_TEMPLATE/config.yml 使用：

~~~yaml
blank_issues_enabled: false
contact_links:
  - name: 安全漏洞报告
    url: https://github.com/hrygo/lotm-card-art/security/advisories/new
    about: 请使用私密渠道，不要在公开 Issue 中发布敏感细节。
  - name: 贡献指南
    url: https://github.com/hrygo/lotm-card-art/blob/main/CONTRIBUTING.md
    about: 提交 Issue 或 PR 前先阅读贡献流程。
  - name: 支持与问题分流
    url: https://github.com/hrygo/lotm-card-art/blob/main/SUPPORT.md
    about: 判断应该提交哪类公开问题。
~~~

- [ ] **Step 2: 写入 bug.yml**

表单必须包含 name、description、title、body，字段依次收集：问题摘要、复现步骤、预期行为、实际行为、运行命令与完整输出、Python 版本和系统、最小复现材料、隐私/凭据确认。将复现步骤、预期行为、实际行为和运行环境设置为必填；不设置 labels、assignees 或 projects。

- [ ] **Step 3: 写入 content-evidence.yml**

表单必须收集：问题类型（设定事实/来源范围/六维语义/视觉提案/其他）、涉及的 pathway/card ID、当前断言或字段、来源与可访问范围、建议修改、是否包含第三方或版权材料。要求提交者确认没有粘贴原著长摘录或私密信息；事实和解释字段设置为必填，来源缺口可以填写“未核验”而不是编造结论。

- [ ] **Step 4: 写入 PR 模板**

.github/PULL_REQUEST_TEMPLATE.md 使用复选清单覆盖：变更目的、影响路径、证据范围、是否改动六维语义、是否涉及第三方素材、是否引入新依赖、是否运行 scaffold check 和 unittest、是否包含生成物/运行缓存、是否已更新文档、是否包含未解决限制。模板提醒贡献者不要在公开 PR 中放置秘密或原著长摘录。

- [ ] **Step 5: 解析 YAML 并检查模板路径**

运行：

~~~bash
ruby -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path); puts path }' .github/ISSUE_TEMPLATE/config.yml .github/ISSUE_TEMPLATE/bug.yml .github/ISSUE_TEMPLATE/content-evidence.yml
test -f .github/CODEOWNERS
test -f .github/PULL_REQUEST_TEMPLATE.md
~~~

Expected: 每个 YAML 文件成功解析，模板路径均存在。GitHub 表单字段使用官方支持的 markdown、input、textarea、dropdown、checkboxes 类型。

- [ ] **Step 6: Commit**

~~~bash
git add .github/CODEOWNERS .github/PULL_REQUEST_TEMPLATE.md .github/ISSUE_TEMPLATE
git diff --cached --check
git commit -m "docs: add GitHub collaboration templates"
~~~

### Task 4: 添加 CI 与 Dependabot

**Files:**
- Create: .github/workflows/ci.yml
- Create: .github/dependabot.yml

**Interfaces:**
- Consumes: tools/cardctl.py、tests/、项目 Python 版本约束。
- Produces: main push、面向 main 的 PR 和手动触发都执行同一套矩阵检查；Actions 引用每周得到 Dependabot 更新。

- [ ] **Step 1: 写入 CI workflow**

.github/workflows/ci.yml 采用以下关键结构：

~~~yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    name: Python ${{ matrix.python-version }}
    runs-on: ubuntu-latest
    timeout-minutes: 10
    strategy:
      fail-fast: false
      matrix:
        python-version: ['3.10', '3.11', '3.12', '3.13', '3.14']
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - name: Check scaffold
        run: python tools/cardctl.py check --level scaffold
      - name: Run unit tests
        run: python -m unittest discover -s tests -v
~~~

不添加 pip 安装步骤；workflow 依赖的动作使用 major tag，由 Dependabot 跟踪。

- [ ] **Step 2: 写入 Dependabot 配置**

~~~yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    open-pull-requests-limit: 5
~~~

- [ ] **Step 3: 验证 YAML 结构和本地命令**

~~~bash
ruby -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path); puts path }' .github/workflows/ci.yml .github/dependabot.yml
python3 tools/cardctl.py check --level scaffold
python3 -m unittest discover -s tests -v
~~~

Expected: YAML 可解析；脚手架报告 220 个卡位且无错误；单元测试报告 48 项、0 个失败。

- [ ] **Step 4: Commit**

~~~bash
git add .github/workflows/ci.yml .github/dependabot.yml
git diff --cached --check
git commit -m "ci: add Python checks and action updates"
~~~

### Task 5: 应用 GitHub 仓库设置

**Files:**
- Modify: GitHub repository settings for hrygo/lotm-card-art。

**Interfaces:**
- Consumes: Tasks 1–4 的本地提交、已登录的 gh 管理权限。
- Produces: Issues 开启、Wiki 关闭、合并后删除分支开启、默认分支为 main，并尽可能开启安全提醒。

- [ ] **Step 1: 读取当前远端设置**

~~~bash
gh repo view hrygo/lotm-card-art --json nameWithOwner,isPrivate,defaultBranchRef,hasIssuesEnabled,hasWikiEnabled,hasProjectsEnabled,deleteBranchOnMerge
~~~

记录变更前值，不修改默认分支。

- [ ] **Step 2: 推送治理提交**

配置文件必须先进入远端默认分支，供 GitHub 识别社区文件和 Actions workflow：

~~~bash
git push origin main
~~~

- [ ] **Step 3: 应用基础仓库设置**

~~~bash
gh repo edit hrygo/lotm-card-art --enable-issues --enable-wiki=false --enable-projects=false --delete-branch-on-merge
~~~

- [ ] **Step 4: 开启安全提醒**

~~~bash
gh api --method PUT repos/hrygo/lotm-card-art/vulnerability-alerts
gh api --method PUT repos/hrygo/lotm-card-art/automated-security-fixes
~~~

如果 GitHub 返回明确的账户计划或能力限制，记录该限制并停止重试；不为了绕过限制修改仓库可见性、权限或 Actions token。

- [ ] **Step 5: 核对远端设置**

~~~bash
gh repo view hrygo/lotm-card-art --json nameWithOwner,isPrivate,defaultBranchRef,hasIssuesEnabled,hasWikiEnabled,hasProjectsEnabled,deleteBranchOnMerge
gh api repos/hrygo/lotm-card-art/vulnerability-alerts --include
~~~

Expected: isPrivate=false、默认分支 main、Issues 开启、Wiki 关闭、Projects 关闭、deleteBranchOnMerge=true；安全提醒返回成功或清晰的能力限制。

- [ ] **Step 6: 不设置分支保护**

确认没有创建 branch protection 或 ruleset，避免当前单人生产阶段无法直接维护 main。

### Task 6: 综合验收、提交与推送

**Files:**
- Modify: none beyond Tasks 1–4。
- Verify: all changed files and GitHub settings。

**Interfaces:**
- Consumes: Tasks 1–5 的文件、提交和远端设置。
- Produces: 本地 main 与 origin/main 指向同一提交，治理文件可被 GitHub 识别，项目原有检查保持通过。

- [ ] **Step 1: 检查工作树和 staged/unstaged 差异**

~~~bash
git status --short --branch
git diff --check
git diff HEAD~4..HEAD --stat
~~~

Expected: 非忽略工作树没有未提交改动；四个治理提交只包含计划文件和 Tasks 1–4 声明的文件。

- [ ] **Step 2: 运行最终本地检查**

~~~bash
python3 tools/cardctl.py check --level scaffold
python3 -m unittest discover -s tests -v
git diff HEAD~4..HEAD --name-only | rg '(^|/)(\.env|.*secret.*|.*credential.*|.*token.*|.*password.*|.*\.pem$)'
~~~

Expected: scaffold 通过并报告 220 个卡位；48 项测试全部通过；敏感文件名命令无匹配。对敏感内容再运行高信号正则扫描，确认没有 token、私钥或提交邮箱。

- [ ] **Step 3: 推送治理提交**

~~~bash
git push origin main
~~~

- [ ] **Step 4: 从远端核对提交和 Actions**

~~~bash
git rev-parse HEAD
git ls-remote origin refs/heads/main
gh run list --repo hrygo/lotm-card-art --limit 5
gh api repos/hrygo/lotm-card-art/community/profile --jq '{health_percentage,files}'
~~~

Expected: 本地 HEAD 和远端 refs/heads/main 哈希一致；最新 CI 至少已被 GitHub 接收；Community Profile 返回治理文件检查结果。

- [ ] **Step 5: 进行最终提交说明**

报告以下内容：文件变更摘要、未触碰的卡牌事实/资产、CI 与测试结果、远端设置、许可证范围、任何 GitHub 计划能力限制。明确说明仓库仍是脚手架，不等于 220 张完成卡面或官方授权内容。

## 回退方式

- 文件改动：按独立提交回退，不使用 git reset --hard，保留其他用户改动。
- GitHub 设置：使用 gh repo edit 将 Issues、Wiki、Projects 和合并后删除分支恢复为 Task 5 记录的变更前值；安全提醒按 GitHub 设置页面/API 的明确状态处理。
- 不回退或删除已有的卡牌数据、研究记录、生成目录或用户未提交内容。

## 完成定义

- Tasks 1–4 的文件全部存在、链接有效、YAML 可解析，并分别形成清晰提交。
- 本地 scaffold check 报告 220 个卡位；本地 unittest 报告 48 项、0 个失败。
- GitHub main 已接收治理提交，CI 被触发，Dependabot 配置位于默认分支。
- 仓库设置与设计稿一致；未启用会阻塞当前单人维护的分支保护。
- README、许可证和 NOTICE 没有把代码许可扩大到第三方主题内容，也没有公开秘密或私人联系信息。
