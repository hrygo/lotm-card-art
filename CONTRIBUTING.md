# 贡献指南

感谢你帮助改进这个卡牌制作工具。这里的首要目标是保持事实诚实、证据可追溯、卡面语义可回读，以及让后续贡献者能复现检查结果。

## 开始前

请先阅读：

1. 根目录 AGENTS.md。
2. pathways/AGENTS.md 和目标途径目录下的 AGENTS.md。
3. design/semantic-contract.md、design/qa-rubric.md、docs/source-policy.md。
4. NOTICE.md 和 SECURITY.md。

仓库的内容生产工具链目前是 Python 3.10+、标准库、无第三方依赖。不要为了方便引入需要联网、密钥或付费服务才能运行的步骤。

## 适合贡献的内容

- 改进 tools/cardctl.py 的结构检查、任务编译或错误信息。
- 为现有检查器补充回归测试。
- 改进设计规则、工作流说明和贡献体验。
- 在证据充分时补充单卡研究和六维转译。
- 提交经过授权、来源和用途明确的参考素材登记。

## 单卡与设定贡献规则

修改卡牌资料时，请保持以下区分：

- canon：有可复核来源支持的作品断言。
- interpretation：基于证据的解释，不承担精确事实。
- knowledge_gap：明确记录的资料缺口，不等于“不存在”。

精确中文名称、配方、晋升条件和限制必须有与作品范围匹配的证据。未核验时保留 research 或明确缺口，不用模型记忆、英文译文或二手页面填空。不要提前表现下一序列能力，也不要将原创视觉提案写成官方徽记或正典设定。

## 本地检查

在提交 Pull Request 前运行：

~~~bash
python3 tools/cardctl.py check --level scaffold
python3 -m unittest discover -s tests -v
~~~

`check --level scaffold` 应报告 220 个卡位且没有结构错误；当前测试套件（2026-09-15 实测）为 **184 项、0 个失败**（含 6 项跳过）。design 和 release 在没有完成研究、实际图像和真实审核时失败是预期行为。

不要提交 .env、token、私钥、运行缓存、.omo/、生成任务快照、未授权图片、原著长摘录或伪造审核/批准记录。提交前检查 git diff --cached。

## Pull Request

一个 PR 尽量只解决一个可描述的问题，并说明：

- 变更动机与影响范围。
- 涉及的 pathway、sequence 或文件。
- 事实证据、来源访问范围和事实/解释/缺口状态。
- 是否影响六维语义、图像素材、版权边界或第三方依赖。
- 实际运行的检查命令和结果。
- 尚未解决的限制或需要维护者决定的事项。

PR 不应包含凭据、个人敏感信息、原著长摘录或无授权素材。维护者可以要求拆分混合了事实修订、格式化和无关重构的变更。

## 提交信息

使用简洁、可检索的 Conventional Commit 风格，例如：

~~~text
docs: clarify source verification scope
fix: reject generated path traversal
test: cover duplicate claim identifiers
~~~

提交信息描述变更目的，不使用 update、misc 等无法检索的标题。

## 问题与安全

可复现的工具问题请使用 Issue；设定、来源和语义问题请使用对应表单。安全漏洞、凭据泄露和其他敏感问题请按 SECURITY.md 私下报告，不要公开讨论细节。
