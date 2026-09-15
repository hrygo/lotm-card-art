// Builds the Figma development plugin for the global design tokens:
//   tokens.js + main.js  ->  code.js
// and stages code.js + manifest.json into the user's Downloads folder so the
// Figma desktop file picker can reach them.
//
// Nothing generated is written back into this folder: code.js only ever lands in
// the staging directory, so the repository holds sources and nothing else.
//
// 用法：node build.js   （构建 + 冒烟测试）

const fs = require("fs");
const os = require("os");
const path = require("path");
const vm = require("vm");

const SRC_DIR = __dirname;
// ASCII 目录名：Figma 的清单选择器在中文路径上会卡住剪贴板/输入，实测踩过。
const STAGE_DIR = path.join(os.homedir(), "Downloads", "mysteries-figma-kit");

// Figma 插件在严格模式下执行。显式写上这句声明，让 Node 冒烟测试与 Figma 里跑的
// 是同一种语义——未声明的标识符在这里就会当场失败。
const USE_STRICT = '"use strict";\n';

function readSource(file) {
  return fs.readFileSync(path.join(SRC_DIR, file), "utf8");
}

function build() {
  const code = USE_STRICT + ["tokens.js", "main.js"].map(readSource).join("\n");
  fs.mkdirSync(STAGE_DIR, { recursive: true });
  fs.writeFileSync(path.join(STAGE_DIR, "code.js"), code);
  fs.copyFileSync(path.join(SRC_DIR, "manifest.json"), path.join(STAGE_DIR, "manifest.json"));
  return code;
}

// --- 冒烟测试 ----------------------------------------------------------------
// 给未声明标识符赋值在 Figma 里只表现为插件面板上的一行 ReferenceError，编辑器的
// 语法检查看不出来。下面这个 figma stub 让 code.js 在 Node 里跑完整个流程，把这类
// 错误挡在人工操作之前。

function makeFigmaStub() {
  let seq = 0;
  const captured = {
    colors: [],
    numbers: [],
    textStyles: [],
    boundPaints: 0,
    ui: null,
    notify: null,
  };

  function node(kind) {
    const created = {
      kind: kind,
      id: kind + "-" + (++seq),
      name: "",
      x: 0,
      y: 0,
      width: 0,
      height: 0,
      fills: [],
      clipsContent: true,
      cornerRadius: 0,
      fontSize: 0,
      characters: "",
      textStyleId: null,
      children: [],
      resize: function (w, h) { this.width = w; this.height = h; },
      appendChild: function (child) { this.children.push(child); return child; },
      remove: function () {},
    };
    let font = null;
    Object.defineProperty(created, "fontName", {
      get: function () { return font; },
      set: function (value) { assertFontLoaded(value); font = value; },
    });
    return created;
  }

  const loadedFonts = {};

  function fontKey(font) {
    return font.family + " " + font.style;
  }

  // Figma 的硬性契约：给 fontName 赋值之前必须先 loadFontAsync，否则抛
  // Cannot use unloaded font。stub 复刻这条规则，好让冒烟测试抓到同类问题。
  function assertFontLoaded(font) {
    if (!font) return;
    if (!loadedFonts[fontKey(font)]) {
      throw new Error('Cannot use unloaded font "' + fontKey(font) + '"');
    }
  }

  const root = node("document");
  const collections = [];
  const byType = {};

  const figma = {
    root: root,
    currentPage: null,
    ui: { onmessage: null },
    viewport: { scrollAndZoomIntoView: function () {} },
    createFrame: function () { return node("frame"); },
    createText: function () { return node("text"); },
    createRectangle: function () { return node("rect"); },
    createPage: function () {
      const page = node("page");
      root.children.push(page);
      return page;
    },
    loadFontAsync: function (font) {
      loadedFonts[fontKey(font)] = true;
      captured.fonts = loadedFonts;
      return Promise.resolve();
    },
    getLocalTextStyles: function () { return captured.textStyles.slice(); },
    createTextStyle: function () {
      const style = { id: "style-" + (++seq) };
      let font = null;
      Object.defineProperty(style, "fontName", {
        get: function () { return font; },
        set: function (value) { assertFontLoaded(value); font = value; },
      });
      captured.textStyles.push(style);
      return style;
    },
    showUI: function (html) { captured.ui = html; },
    closePlugin: function () {},
    notify: function (message) { captured.notify = message; },
    variables: {
      getLocalVariableCollections: function () { return collections.slice(); },
      getLocalVariables: function (type) { return (byType[type] || []).slice(); },
      createVariableCollection: function (name) {
        const collection = {
          id: "collection-" + (++seq),
          name: name,
          modes: [{ modeId: "mode-" + seq, name: "Mode 1" }],
          renameMode: function (modeId, next) {
            this.modes.forEach(function (mode) {
              if (mode.modeId === modeId) mode.name = next;
            });
          },
        };
        collections.push(collection);
        return collection;
      },
      createVariable: function (name, collection, type) {
        const variable = {
          id: "variable-" + (++seq),
          name: name,
          variableCollectionId: collection.id,
          resolvedType: type,
          description: "",
          values: {},
          setValueForMode: function (modeId, value) { this.values[modeId] = value; },
        };
        byType[type] = byType[type] || [];
        byType[type].push(variable);
        (type === "COLOR" ? captured.colors : captured.numbers).push(variable);
        return variable;
      },
      setBoundVariableForPaint: function (paint, field, variable) {
        captured.boundPaints += 1;
        const boundVariables = {};
        boundVariables[field] = { type: "VARIABLE_ALIAS", id: variable.id };
        return Object.assign({}, paint, { boundVariables: boundVariables });
      },
    },
  };

  return { figma: figma, captured: captured };
}

async function selftest(code) {
  // main() 是异步的：注入两行，把自检报告和 main() 的 promise 都留出来，这样
  // 字体未载入一类的异步失败会在这里当场炸出来，而不是等人工在 Figma 里发现。
  const probe = code.replace(
    /\nmain\(\);\s*$/,
    "\nglobalThis.__report = report;\nglobalThis.__done = main();\n"
  );
  if (probe === code) {
    throw new Error("冒烟测试注入失败：main.js 结尾的 main() 调用没找到");
  }
  const stub = makeFigmaStub();
  const sandbox = { figma: stub.figma, console: console };
  vm.createContext(sandbox);
  vm.runInContext(probe, sandbox, { filename: "code.js" });
  await sandbox.__done;

  const captured = stub.captured;
  const problems = (sandbox.__report && sandbox.__report.problems) || [];
  const fonts = Object.keys(captured.fonts || {});
  const checks = [
    ["无问题项", problems.length === 0, problems.slice(0, 3).join("；")],
    ["每张色板都绑定变量", captured.boundPaints === captured.colors.length,
      captured.boundPaints + "/" + captured.colors.length],
    ["文字样式 10 个", captured.textStyles.length === 10, String(captured.textStyles.length)],
    ["字体先载入后使用", fonts.length >= 4, fonts.join(" / ")],
    ["自检面板已生成", typeof captured.ui === "string" && captured.ui.indexOf("自检") >= 0, ""],
  ];

  let failed = 0;
  checks.forEach(function (check) {
    if (!check[1]) failed += 1;
    console.log((check[1] ? "  ok   " : "  FAIL ") + check[0] + (check[2] ? "  (" + check[2] + ")" : ""));
  });
  console.log("  变量 COLOR " + captured.colors.length + " · FLOAT " + captured.numbers.length);
  console.log("  通知：" + (captured.notify || ""));
  return failed;
}

(async function () {
  const code = build();
  console.log("code.js " + code.length + " bytes");
  console.log("staged  " + STAGE_DIR);
  const failed = await selftest(code);
  if (failed) {
    console.error("冒烟测试失败：" + failed + " 项");
    process.exit(1);
  }
  console.log("冒烟测试通过");
})();
