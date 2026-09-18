// =============================================================================
// 卡牌演示 · 全局设计 token — Figma 生成器
//
// 输入：tokens.js（由 tools/design_tokens.py 从 config/design-tokens.json 生成）
// 输出：变量集合「卡牌演示」（COLOR + FLOAT）、type/* 文字样式、00 Foundations 页面、
//       以及一份自检报告。
//
// 幂等：重跑时复用同名变量与文字样式，清空并重建自己拥有的页面。
// 它只写 Figma 文档，不碰仓库代码、不联外网。
//
// 两个 Figma 特有的硬性约束（都实测踩过）：
//   1. 插件沙箱是严格模式，所有标识符必须先声明；
//   2. 任何 fontName 赋值之前，必须先 await figma.loadFontAsync(...)，
//      否则插件直接以 "Cannot use unloaded font" 失败。
// =============================================================================

const PAGE_NAME = "00 Foundations";
const COLLECTION_NAME = "卡牌演示";
const MODE_NAME = "Dark";
const FONT_FAMILY = "Inter";
const STYLE_FONT_STYLE = {
  regular: "Regular",
  medium: "Medium",
  semibold: "Semi Bold",
  bold: "Bold",
  black: "Black",
};

// 语义文字样式：名字、字号、字重、行高百分比、生产实现说明。
const TEXT_STYLES = [
  ["type/display", 32, "bold", 120, "SF Serif（design: .serif）"],
  ["type/hero", 24, "bold", 120, "SF Serif"],
  ["type/title", 20, "bold", 120, "SF Serif"],
  ["type/titleSmall", 17, "medium", 138, "SF Serif"],
  ["type/body", 13, "regular", 138, "SF Serif"],
  ["type/bodyStrong", 13, "semibold", 138, "SF Serif"],
  ["type/caption", 12, "medium", 138, "SF Rounded（design: .rounded）"],
  ["type/captionStrong", 11, "semibold", 138, "SF Rounded"],
  ["type/eyebrow", 10, "semibold", 138, "SF Rounded"],
  ["type/micro", 9, "medium", 138, "SF Rounded"],
];

// 只载入真正用到的字重：Figma 对未载入的字体赋值一律抛错。
function fontStylesInUse() {
  const used = [];
  TEXT_STYLES.forEach(function (def) {
    const style = STYLE_FONT_STYLE[def[2]];
    if (used.indexOf(style) < 0) used.push(style);
  });
  return used;
}

async function loadFonts() {
  await Promise.all(fontStylesInUse().map(function (style) {
    return figma.loadFontAsync({ family: FONT_FAMILY, style: style });
  }));
}

// 色板分组顺序：决定页面上色板的排列，不参与数值。
const COLOR_GROUPS = [
  "leather", "brass", "aether", "parchment", "mystic", "artwork",
  "story", "semantic", "status", "playback", "tier", "border", "shadow",
];

const GROUP_TITLES = {
  leather: "Leather · 复古牛皮底色",
  brass: "Brass · 黄铜",
  aether: "Aether · 灵界青碧",
  parchment: "Parchment · 羊皮纸文字",
  mystic: "Mystic · 神秘色",
  artwork: "Artwork · 程序化卡面底色",
  story: "Story · 故事书材质",
  semantic: "Semantic · 六维信息色",
  status: "Status · 内容状态色",
  playback: "Playback · 播放状态色",
  tier: "Tier · 序列档位色（客户端图鉴）",
  border: "Border · 描边",
  shadow: "Shadow · 阴影与发光",
};

const report = { steps: [], problems: [] };
// 插件沙箱是严格模式：这些必须先声明，直接赋值给未声明标识符会 ReferenceError。
const V = {};
const TS = {};
const P = {};

// --- 小工具 -----------------------------------------------------------------

function hex(rgba) {
  function part(v) {
    const n = Math.round(Math.max(0, Math.min(1, v)) * 255);
    return n.toString(16).padStart(2, "0");
  }
  const base = "#" + part(rgba[0]) + part(rgba[1]) + part(rgba[2]);
  return rgba[3] < 1 ? base + " · " + Math.round(rgba[3] * 100) + "%" : base;
}

function paint(rgba) {
  return { type: "SOLID", color: { r: rgba[0], g: rgba[1], b: rgba[2] }, opacity: rgba[3] };
}

function solid(rgba) {
  return { type: "SOLID", color: { r: rgba[0], g: rgba[1], b: rgba[2] }, opacity: rgba[3] };
}

function frame(name, x, y, w, h, fill) {
  const node = figma.createFrame();
  node.name = name;
  node.x = x;
  node.y = y;
  node.resize(w, h);
  node.fills = fill ? [fill] : [];
  node.clipsContent = false;
  return node;
}

function text(parent, x, y, chars, size, style, color) {
  const node = figma.createText();
  node.fontName = { family: FONT_FAMILY, style: style };
  node.fontSize = size;
  node.characters = chars;
  node.fills = [solid(color)];
  node.x = x;
  node.y = y;
  parent.appendChild(node);
  return node;
}

function rect(parent, x, y, w, h, rgba, radius) {
  const node = figma.createRectangle();
  node.x = x;
  node.y = y;
  node.resize(w, h);
  node.fills = [paint(rgba)];
  node.cornerRadius = radius || 0;
  parent.appendChild(node);
  return node;
}

function bindPaint(node, rgba, variable) {
  const bound = figma.variables.setBoundVariableForPaint(solid(rgba), "color", variable);
  node.fills = [bound];
}

// --- 变量 -------------------------------------------------------------------

function ensureCollection(name) {
  const found = figma.variables.getLocalVariableCollections().find(function (c) {
    return c.name === name;
  });
  return found || figma.variables.createVariableCollection(name);
}

function ensureVariable(collection, name, type) {
  const found = figma.variables.getLocalVariables(type).find(function (v) {
    return v.name === name && v.variableCollectionId === collection.id;
  });
  return found || figma.variables.createVariable(name, collection, type);
}

function buildVariables() {
  const collection = ensureCollection(COLLECTION_NAME);
  const modeId = collection.modes[0].modeId;
  if (collection.modes[0].name !== MODE_NAME) {
    try { collection.renameMode(modeId, MODE_NAME); } catch (e) {}
  }
  if (collection.modes.length > 1) {
    report.problems.push("变量集合有多个 mode；本设计只有单一深色档，多余 mode 需要手工确认");
  }

  TOKEN_DATA.colors.forEach(function (entry) {
    const variable = ensureVariable(collection, entry[0], "COLOR");
    const rgba = entry[1];
    variable.setValueForMode(modeId, { r: rgba[0], g: rgba[1], b: rgba[2], a: rgba[3] });
    variable.description = hex(rgba);
    V[entry[0]] = variable;
  });
  TOKEN_DATA.numbers.forEach(function (entry) {
    const variable = ensureVariable(collection, entry[0], "FLOAT");
    variable.setValueForMode(modeId, entry[1]);
    V[entry[0]] = variable;
  });
  return {
    collection: collection,
    modeId: modeId,
    colors: TOKEN_DATA.colors.length,
    numbers: TOKEN_DATA.numbers.length,
  };
}

// --- 文字样式 ---------------------------------------------------------------

function buildTextStyles() {
  let created = 0;
  TEXT_STYLES.forEach(function (def) {
    const style = figma.getLocalTextStyles().find(function (s) { return s.name === def[0]; }) ||
      figma.createTextStyle();
    style.name = def[0];
    style.fontName = { family: FONT_FAMILY, style: STYLE_FONT_STYLE[def[2]] };
    style.fontSize = def[1];
    style.lineHeight = { unit: "PERCENT", value: def[3] };
    try { style.description = "生产实现：" + def[4]; } catch (e) {}
    TS[def[0]] = style;
    created += 1;
  });
  return created;
}

// --- 页面 -------------------------------------------------------------------

function buildPage() {
  let page = figma.root.children.find(function (p) { return p.name === PAGE_NAME; });
  if (!page) {
    const spare = figma.root.children.find(function (p) {
      return p.children.length === 0 && p.name !== PAGE_NAME;
    });
    page = spare || figma.createPage();
  }
  page.name = PAGE_NAME;
  page.children.slice().forEach(function (child) { child.remove(); });
  P.page = page;
  return page;
}

function colorRows() {
  const byGroup = {};
  TOKEN_DATA.colors.forEach(function (entry) {
    const group = entry[0].split("/")[1];
    byGroup[group] = byGroup[group] || [];
    byGroup[group].push(entry);
  });
  return byGroup;
}

function buildColorBoards(root, byGroup) {
  const COLUMNS = 8;
  const CELL_W = 168;
  const CELL_H = 108;
  let y = 0;
  let drawn = 0;
  const ink = [0.949, 0.937, 0.914, 1];
  const dim = [0.639, 0.62, 0.576, 1];

  COLOR_GROUPS.forEach(function (group) {
    const entries = byGroup[group];
    if (!entries) return;
    text(root, 0, y, GROUP_TITLES[group] || group, 14, "Semi Bold", ink);
    y += 26;
    entries.forEach(function (entry, index) {
      const col = index % COLUMNS;
      const row = Math.floor(index / COLUMNS);
      const x = col * CELL_W;
      const cellY = y + row * CELL_H;
      const swatch = rect(root, x, cellY, 148, 62, entry[1], 8);
      const variable = V[entry[0]];
      if (variable) {
        bindPaint(swatch, entry[1], variable);
      } else {
        report.problems.push("色板未绑定变量：" + entry[0]);
      }
      text(root, x, cellY + 70, entry[0].split("/").slice(1).join("/"), 10, "Medium", ink);
      text(root, x, cellY + 86, hex(entry[1]), 9, "Regular", dim);
      drawn += 1;
    });
    y += Math.ceil(entries.length / COLUMNS) * CELL_H + 28;
  });
  return { drawn: drawn, height: y };
}

function buildNumberScales(root, y) {
  const ink = [0.949, 0.937, 0.914, 1];
  const dim = [0.639, 0.62, 0.576, 1];
  let cursor = y;

  const groups = [
    ["space/", "Space · 间距刻度（数值即取值）"],
    ["radius/", "Radius · 圆角"],
    ["stroke/", "Stroke · 描边宽度"],
    ["font/size/", "Font size · 字号刻度"],
    ["font/lineHeight/", "Line height · 行高百分比"],
    ["size/", "Size · 结构性尺寸"],
  ];
  groups.forEach(function (pair) {
    const prefix = pair[0];
    const entries = TOKEN_DATA.numbers.filter(function (entry) {
      return entry[0].indexOf(prefix) === 0;
    });
    if (!entries.length) return;
    text(root, 0, cursor, pair[1], 14, "Semi Bold", ink);
    cursor += 26;
    entries.forEach(function (entry, index) {
      const x = index * 176;
      const variable = V[entry[0]];
      const bar = rect(
        root,
        x,
        cursor,
        Math.max(4, Math.min(160, entry[1] * (prefix === "font/lineHeight/" ? 0.5 : 1))),
        prefix === "radius/" ? 28 : 10,
        [0.82, 0.749, 0.6, 1],
        prefix === "radius/" ? Math.min(14, entry[1]) : 4
      );
      if (variable && prefix !== "font/lineHeight/") {
        // 尺寸条本身不是变量绑定的对象，这里只把数值写进说明，避免误导。
      }
      text(root, x, cursor + 40, entry[0].split("/").pop(), 10, "Medium", ink);
      text(root, x, cursor + 56, String(entry[1]), 9, "Regular", dim);
    });
    cursor += 96;
  });
  return cursor;
}

function buildTypeScale(root, y) {
  const ink = [0.949, 0.937, 0.914, 1];
  const dim = [0.639, 0.62, 0.576, 1];
  text(root, 0, y, "Type · 语义文字样式", 14, "Semi Bold", ink);
  let cursor = y + 30;
  TEXT_STYLES.forEach(function (def) {
    const sample = text(root, 0, cursor, def[0] + "　卡牌演示 · 秘史档案馆　Aa 0123", 14, "Regular", ink);
    const style = TS[def[0]];
    if (style) {
      sample.textStyleId = style.id;
    } else {
      report.problems.push("文字样式缺失：" + def[0]);
    }
    text(root, 640, cursor + 2, def[1] + "pt · " + def[2] + " · " + def[3] + "%", 9, "Regular", dim);
    cursor += 26;
  });
  return cursor;
}

function buildNotes(root, y) {
  const ink = [0.949, 0.937, 0.914, 1];
  const dim = [0.639, 0.62, 0.576, 1];
  const lines = [
    "本页由 design/figma-kit 生成；数值的事实源是仓库里的 config/design-tokens.json。",
    "变量集合「卡牌演示」只有一个 mode（Dark）：这个产品只有深色一档，不做浅色克隆。",
    "文字样式用 Inter 呈现；生产实现按说明里的设计字体（SF Serif / SF Rounded）落地。",
    "不是变量的部分：渐变材质、阴影扩散、动效时长与弹簧参数——它们在 config/design-tokens.json 的 material / motion 里，",
    "Figma 变量不能表达它们，所以这里只出示意色板与说明，真实观感以 macOS 客户端为准。",
  ];
  text(root, 0, y + 10, lines[0], 11, "Medium", ink);
  lines.slice(1).forEach(function (line, index) {
    text(root, 0, y + 34 + index * 18, line, 10, "Regular", dim);
  });
  return y + 34 + (lines.length - 1) * 18 + 20;
}

function buildFoundations(page, info) {
  const byGroup = colorRows();
  const root = frame("卡牌演示 · Design Tokens", 0, 0, 1440, 1200, solid([0.122, 0.114, 0.118, 1]));
  const ink = [0.949, 0.937, 0.914, 1];
  const dim = [0.639, 0.62, 0.576, 1];
  page.appendChild(root);

  text(root, 0, 0, "卡牌演示 · 全局设计 token", 26, "Bold", ink);
  text(root, 0, 40, "颜色 / 间距 / 圆角 / 描边 / 字号 / 行高 / 结构尺寸 → 变量；语义文字 → 文字样式。", 12, "Regular", dim);
  text(root, 0, 62, "变量 " + (info.colors + info.numbers) + " 个（COLOR " + info.colors + " · FLOAT " + info.numbers + "）· 文字样式 " + TEXT_STYLES.length + " 个", 11, "Medium", dim);

  const holder = frame("boards", 0, 100, 1440, 100, null);
  root.appendChild(holder);

  const colors = buildColorBoards(holder, byGroup);
  const afterNumbers = buildNumberScales(holder, colors.height + 24);
  const afterType = buildTypeScale(holder, afterNumbers + 24);
  const total = buildNotes(holder, afterType + 24);

  holder.resize(1440, total);
  root.resize(1440, 100 + total + 40);
  return { root: root, swatches: colors.drawn };
}

// 报告走插件面板（HTML），而不是画布：面板文本可被读屏与可访问性树读到，
// 画布上的文字只能靠截图。参考项目同样把 audit 放在面板里。
function reportHTML(info, drawn) {
  const modes = info.collection.modes.map(function (m) { return m.name; }).join(" / ");
  const lines = [
    "变量集合：" + info.collection.name + "（mode：" + modes + "）",
    "变量：COLOR " + info.colors + " · FLOAT " + info.numbers + "（合计 " + (info.colors + info.numbers) + "）",
    "文字样式：" + TEXT_STYLES.length + " 个（type/*）",
    "本页色板：" + drawn + " 张（应等于 COLOR 变量数）",
    "问题：" + report.problems.length,
  ].concat(report.problems.slice(0, 8).map(function (item) { return "· " + item; }));
  const rows = lines.map(function (line, index) {
    const cls = index < 5 ? "row" : "row dim";
    return '<div class="' + cls + '">' + line.replace(/[<>&]/g, "") + "</div>";
  }).join("");
  return [
    "<style>",
    "body{margin:0;font:12px -apple-system,sans-serif;background:#1a181c;color:#f2efe9}",
    "header{padding:14px 16px 6px;font-weight:600;font-size:13px}",
    ".row{padding:3px 16px;line-height:1.5}",
    ".dim{color:#a39e94}",
    "footer{padding:12px 16px 16px}",
    "button{font:600 12px -apple-system,sans-serif;padding:7px 16px;border-radius:8px;",
    "border:0;background:#a4937a;color:#04080d;cursor:pointer}",
    "</style>",
    "<header>卡牌演示 Design Tokens · 自检</header>",
    rows,
    '<footer><button id="close">关闭</button></footer>',
    "<script>document.getElementById('close').onclick=function(){parent.postMessage({pluginMessage:{type:'close'}},'*')}</script>",
  ].join("");
}

// --- 入口 -------------------------------------------------------------------

async function main() {
  await loadFonts();
  const info = buildVariables();
  report.steps.push("variables");
  const styles = buildTextStyles();
  report.steps.push("text styles");
  const page = buildPage();
  report.steps.push("page");
  const built = buildFoundations(page, info);
  report.steps.push("foundations");
  if (built.swatches !== info.colors) {
    report.problems.push("色板数 " + built.swatches + " 与 COLOR 变量数 " + info.colors + " 不一致");
  }
  figma.currentPage = page;
  figma.viewport.scrollAndZoomIntoView([built.root]);
  figma.showUI(reportHTML(info, built.swatches), { width: 460, height: 300, title: "卡牌演示 Design Tokens" });
  figma.ui.onmessage = function (message) {
    if (message && message.type === "close") figma.closePlugin();
  };
  figma.notify(
    "卡牌演示 token：变量 " + (info.colors + info.numbers) +
    " · 文字样式 " + styles + " · 问题 " + report.problems.length
  );
}

main();
