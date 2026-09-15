# 设计 token 投影与字面量门禁的反例测试。
#
# 注入临时文件而不是依赖仓库里现有 Swift 源码的具体写法：门禁本身必须能被证伪，
# 否则「检查通过」可能只说明扫描器什么都没扫到。

import sys
import tempfile
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import design_tokens


def scan_swift(source: str):
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "Fixture.swift"
        path.write_text(source, encoding="utf-8")
        return design_tokens.scan_literals(design_tokens.load_tokens(), [path], baseline={})


def scan_swift_with_baseline(source: str, baseline: dict):
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "Fixture.swift"
        path.write_text(source, encoding="utf-8")
        return design_tokens.scan_literals(design_tokens.load_tokens(), [path], baseline=baseline)


def scan_styles(source: str):
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "main.js"
        path.write_text(source, encoding="utf-8")
        return design_tokens.scan_text_styles(design_tokens.load_tokens(), path)


class LiteralScanTests(unittest.TestCase):
    def test_clean_source_passes(self):
        problems, notes = scan_swift(
            "Text(a)\n"
            "  .font(.system(size: DesignTokens.FontSize.s13))\n"
            "  .padding(DesignTokens.Space.s16)\n"
            "  .frame(width: DesignTokens.Size.hitTarget, height: DesignTokens.Size.hitTarget)\n"
        )
        self.assertEqual(problems, [])
        self.assertEqual(notes, [])

    def test_spacing_and_typography_literals_are_rejected(self):
        problems, _ = scan_swift(
            "Text(a)\n"
            "  .font(.system(size: 13))\n"
            "  .padding(16)\n"
            "  .padding(.horizontal, 12)\n"
            "  .cornerRadius(8)\n"
            "  .stroke(DesignTokens.Palette.brassCore, lineWidth: 1.5)\n"
        )
        joined = "\n".join(problems)
        for needle in (
            "字号字面量 13",
            "内边距字面量 16",
            "轴内边距字面量 12",
            "圆角字面量 8",
            "描边字面量 1.5",
        ):
            self.assertIn(needle, joined)

    def test_corner_radius_modifier_and_argument_are_both_rejected(self):
        problems, _ = scan_swift(
            "Rectangle().cornerRadius(1.5)\n"
            "RoundedRectangle(cornerRadius: 6)\n"
        )
        joined = "\n".join(problems)
        self.assertIn("圆角字面量 1.5", joined)
        self.assertIn("圆角字面量 6", joined)

    def test_zero_and_infinity_are_allowed(self):
        problems, _ = scan_swift(
            "VStack(spacing: 0) {\n"
            "  Spacer(minLength: 0)\n"
            "  Color.clear.frame(maxWidth: .infinity)\n"
            "}\n"
        )
        self.assertEqual(problems, [])

    def test_spacer_minimum_length_is_rejected(self):
        problems, _ = scan_swift("HStack { Spacer(minLength: 24) }\n")
        self.assertIn("弹性间距字面量 24", "\n".join(problems))

    def test_structural_literal_matching_a_token_is_rejected(self):
        problems, _ = scan_swift(".frame(minWidth: 1180, minHeight: 760)\n")
        joined = "\n".join(problems)
        self.assertIn("size.windowMinWidth", joined)
        self.assertIn("size.windowMinHeight", joined)

    def test_structural_literal_without_a_token_needs_baseline_registration(self):
        problems, _ = scan_swift(".frame(width: 137, height: 89)\n")
        joined = "\n".join(problems)
        self.assertIn("结构性尺寸字面量 137 未登记", joined)
        self.assertIn("结构性尺寸字面量 89 未登记", joined)

    def test_registered_structural_literals_pass_and_removals_are_allowed(self):
        problems, notes = scan_swift_with_baseline(
            ".frame(width: 137)\n",
            {"结构性尺寸": {"137": 1, "89": 1}},
        )
        self.assertEqual(problems, [])
        self.assertIn("结构性尺寸 1 处", "\n".join(notes))

    def test_baseline_still_rejects_a_new_use_of_a_registered_value(self):
        problems, _ = scan_swift_with_baseline(
            ".frame(width: 137)\n.frame(width: 137)\n",
            {"结构性尺寸": {"137": 1}},
        )
        self.assertIn("结构性尺寸字面量 137 未登记（2 处，基线 1 处）", "\n".join(problems))

    def test_color_literal_is_rejected(self):
        problems, _ = scan_swift("let c = Color(red: 0.1, green: 0.2, blue: 0.3)\n")
        self.assertIn("请用 DesignTokens.Palette", "\n".join(problems))

    def test_untokenized_classes_are_frozen_not_gated(self):
        problems, notes = scan_swift(".opacity(0.42)\n.shadow(color: .black, radius: 12)\n")
        joined = "\n".join(problems)
        self.assertIn("不透明度字面量 0.42 未登记", joined)
        self.assertIn("阴影半径字面量 12 未登记", joined)
        joined = "\n".join(notes)
        self.assertIn("不透明度 1 处", joined)
        self.assertIn("阴影半径 1 处", joined)

    def test_frozen_classes_pass_once_registered(self):
        problems, notes = scan_swift_with_baseline(
            ".opacity(0.42)\n.shadow(color: .black, radius: 12)\n",
            {"不透明度": {"0.42": 1}, "阴影半径": {"12": 1}},
        )
        self.assertEqual(problems, [])
        self.assertIn("不透明度 1 处", "\n".join(notes))


class TextStyleScanTests(unittest.TestCase):
    def test_text_style_drawn_from_tokens_passes(self):
        problems, count = scan_styles('["type/body", 13, "regular", 138, "SF Serif"],\n')
        self.assertEqual(problems, [])
        self.assertEqual(count, 1)

    def test_text_style_inventing_a_size_is_rejected(self):
        problems, _ = scan_styles('["type/body", 33, "regular", 138, "SF Serif"],\n')
        self.assertIn("字号 33 不在 config 的 type.size 里", "\n".join(problems))

    def test_text_style_inventing_a_line_height_is_rejected(self):
        problems, _ = scan_styles('["type/body", 13, "regular", 200, "SF Serif"],\n')
        self.assertIn("行高 200 不在 config 的 type.lineHeight 里", "\n".join(problems))

    def test_text_style_inventing_a_weight_is_rejected(self):
        problems, _ = scan_styles('["type/body", 13, "heavier", 138, "SF Serif"],\n')
        self.assertIn("字重 heavier 不在 config 的 type.weight 里", "\n".join(problems))

    def test_missing_text_style_table_is_rejected(self):
        problems, count = scan_styles("const NOTHING = 1;\n")
        self.assertEqual(count, 0)
        self.assertIn("找不到 type/* 文字样式定义", "\n".join(problems))


if __name__ == "__main__":
    unittest.main()
