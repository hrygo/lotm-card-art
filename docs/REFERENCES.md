# 方法与来源入口｜访问日期 2026-09-13

这些链接提供方法或研究入口，不表示220张卡的内容已经核验。

- AGENTS.md开放格式：https://agents.md/ 。用于区分Agent工作说明与项目内容，不把它当作自动图像渲染器。
- Codex指令文档：https://developers.openai.com/codex/guides/agents-md/ （访问时跳转至 https://learn.chatgpt.com/docs/agent-configuration/agents-md ）。项目指令发现按根到当前目录组织，并有合并大小限制；本包显式编译当前任务依赖，不假定任意链接都已自动加载。
- 第一部中文作品入口：https://www.qidian.com/book/1010868264/ 。本次未成功取得正文，仅登记研究入口。
- WebNovel第31章Potion：https://www.webnovel.com/book/lord-of-mysteries_11022733006234505/potion_31326301566593179 。实际可见正文中区分辅助材料和关键材料；本包不复刻完整配方或将英文材料名冒作已核准中文名。
- WebNovel第57章Organization and Summary：https://www.webnovel.com/book/lord-of-mysteries_11022733006234505/organization-and-summary_31623483792353138 。本次只见开头关于魔药消化与扮演关系的预览，不能声称核验整章或某序列的全部扮演原则。

## 序列层级研究

- 官方《诡秘世界研究手册》Paths of the Divine：https://www.lomworld.com/handbook/en?categoryId=3 。用于交叉核对9–0层级、半神/圣者/天使、天使之王与真神的范围；当前页面主体依赖脚本，项目仍保留partial证据状态。
- 起点中文官方第一百零一章“可能”：https://www.qidian.com/chapter/1010868264/424607198/ 。页面可见片段直接支持“序列0等于真神，每个序列只有一个序列0”；正文为VIP且未完整取得，只用于位阶关系，不外推到愚者名称或其他六维。
- 起点中文官方《诡秘之主》设定集：https://h5.if.qidian.com/h5/workSet/main?albumId=131&bookId=1010868264 。通过“力量体系/神之途径”页面视觉读取到22条途径、序列9至0，以及半神、天使、序列0真神的层级概述；不用于补造愚者专属事实。
- WebNovel官方英文译本目录：https://www.webnovel.com/book/11022733006234505/catalog 。用于定位Sequence 2、Attendant of Mysteries等章节标题；英文译本不自动替代第一部中文底本。
- WebNovel第237章Sequence 2：https://www.webnovel.com/book/11022733006234505/35957781160850515 。可见段落将Sequence 2定位为接近神灵的angel层级。
- WebNovel第1289章Fooling：https://www.webnovel.com/book/11022733006234505/fooling_45129713886230191 、第1352章Attendant of Mysteries：https://www.webnovel.com/book/11022733006234505/attendant-of-mysteries_46571607958807867 、第1380章A Miracle：https://www.webnovel.com/book/11022733006234505/a-miracle_47290665209484716 。作为愚者途径高序列研究定位，页面正文均未完整返回，不能据此补造配方或仪式。
- WebNovel第1289–1291章研究定位：第1289章Fooling：https://www.webnovel.com/book/11022733006234505/fooling_45129713886230191 、第1290章Fulfilling Wishes：https://www.webnovel.com/book/11022733006234505/fulfilling-wishes_45148052876477804 、第1291章Two Rituals：https://www.webnovel.com/book/11022733006234505/two-rituals_45148053144913263 。官方英文页面可定位愚者卡、历史投影与仪式叙事，但当前访问均未提供足以核验中文配方/仪式的完整正文。
- WebNovel第1383、1385、1389章研究定位：Stipulated Rules：https://www.webnovel.com/book/11022733006234505/stipulated-rules_47290690459196478 、“Madness”：https://www.webnovel.com/book/11022733006234505/%22madness%22_47290706565332404 、The Fool's Commission：https://www.webnovel.com/book/11022733006234505/the_fool%27s_commission_47290739851329152 。可见片段分别提供愚者卡状态变化、Fooling命名权柄与沉睡叙事的定位；不是完整能力/限制清单。
- 第二十五章“两个仪式”的非官方中文镜像索引：https://www.piaotia.com/html/9/9459/7830015.html 。其中的序列0配方与仪式仅作为二手lead；不复制正文、不替代授权中文底本，也不使项目断言进入`verified`。

本次单卡研究记录见 `docs/research/2026-09-13-fool-s00-research.md`。研究稿将来源分为官方英文译本、官方世界手册与二手线索，并明确哪些内容仍需第一部中文底本核验。
- 当前采用的层级单一事实源：`config/sequence-hierarchy.json`；结构约束见 `schemas/sequence-hierarchy.schema.json`。其中序列0卡是正式序列卡，不是特殊事件。

中文名称仍须以第一部中文底本逐项核验；当前`pathways/fool/canon.json`中的愚者途径名称记录明确为`lead`，不是`verified`。

设计规则与路径美术语言是本项目原创方案，不是引用上述文档作为审美权威。
