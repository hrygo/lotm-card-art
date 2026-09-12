## 变更目的

<!-- 说明为什么需要这次变更，以及它解决的具体问题。 -->

## 影响范围

- [ ] 仅文档或仓库配置
- [ ] tools/ 检查器或任务编译器
- [ ] tests/ 测试
- [ ] card.json、canon.json 或其他卡牌事实源
- [ ] sources/registry.json 或 references/ 素材登记
- [ ] 六维语义、视觉提案或审核流程

涉及的 pathway、sequence 或文件：

## 事实、证据与权利

- [ ] 我区分了 canon、interpretation 和 knowledge_gap。
- [ ] 精确名称、配方、晋升条件和限制有匹配作品范围的证据，或明确保留为未核验。
- [ ] 我说明了来源语言、版本、访问范围和可复核位置。
- [ ] 我没有把原创视觉提案、角色推测或英文译文写成正典事实。
- [ ] 我没有提交原著长摘录、未授权图片、字体、模型输出或其他第三方素材。
- [ ] 我没有在 PR、提交、截图或测试夹具中放置 token、密码、私钥或个人敏感信息。

## 验证

- [ ] 已运行 python3 tools/cardctl.py check --level scaffold
- [ ] 已运行 python3 -m unittest discover -s tests -v
- [ ] 已检查 git diff --cached 或等价的最终 diff。
- [ ] 若检查未通过，我在下方说明失败原因和剩余风险。

验证结果：

## 文档与后续工作

- [ ] 已更新受影响的 README、贡献指南或设计说明。
- [ ] 我说明了生成物、运行缓存、兼容性或其他限制。
- [ ] 这次 PR 只处理一个清晰的逻辑范围。

补充说明：
