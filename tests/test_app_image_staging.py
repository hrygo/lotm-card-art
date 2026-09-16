"""客户端卡图衍生档的打包契约（决策见 docs/DECISIONS.md D23）。

App 内不放母版，只放「按显示尺寸已经做好的成片」。这一组测试守四件事：

1. 每张已登记卡图都落齐每一档，且母版 PNG 不进 App 包；
2. 每一档都不低于客户端显示需求（低于就意味着打开单卡或看网格会糊）；
3. 只缩不放：档位长边取 `min(档位, 母版)`，母版够小时详情档与母版同像素；
4. 换成成片之后包体真的比母版小（这是本决策的目的，不是副产品）；
5. 网格列宽上限落在瓦片档的显示覆盖内（「先给瓦片设上限，再定档」）。
"""

from pathlib import Path
import re
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import cardctl
import production


@unittest.skipUnless(sys.platform == "darwin" and shutil.which("sips"),
                     "app image staging requires macOS sips (see docs/DECISIONS.md D23)")
class AppImageStagingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls._tmp = tempfile.TemporaryDirectory()
        cls.staged = production.validate_fool_audio_package(ROOT, stage_root=cls._tmp.name)
        cls.records = cls.staged["staged_card_art"]
        cls.art_dir = Path(cls._tmp.name) / "CardArt"
        cls.names = cls.staged["app"]["card_art_names"]
        cls.tiers = [tier["tier"] for tier in production.APP_IMAGE_TIERS]

    @classmethod
    def tearDownClass(cls):
        cls._tmp.cleanup()

    def test_every_registered_card_gets_every_tier(self):
        self.assertEqual(len(self.records), len(self.names) * len(self.tiers))
        for name in self.names:
            for tier in self.tiers:
                self.assertTrue((self.art_dir / f"{name}-{tier}.jpg").is_file(), f"{name}-{tier}")

    def test_no_master_png_is_staged_into_the_app(self):
        suffixes = sorted({path.suffix for path in self.art_dir.iterdir()})
        self.assertEqual(suffixes, [".jpg"], "母版 PNG 不得进入 App 包，否则包体回到决策前的量级")

    def test_tiers_meet_the_client_display_requirement(self):
        for record in self.records:
            self.assertGreaterEqual(
                max(record["width"], record["height"]),
                production.APP_IMAGE_DISPLAY_MINIMUM_LONG_EDGE,
                f"{record['file']} 低于客户端显示需求",
            )

    def test_tiers_never_upscale_beyond_the_master(self):
        for record in self.records:
            info = cardctl.image_info(ROOT / record["source"])
            self.assertEqual(info["format"], "PNG")
            source_long_edge = max(info["width"], info["height"])
            declared = next(
                tier["long_edge"] for tier in production.APP_IMAGE_TIERS
                if tier["tier"] == record["tier"]
            )
            self.assertEqual(max(record["width"], record["height"]), min(declared, source_long_edge))
            self.assertLessEqual(record["width"] * record["height"], info["width"] * info["height"])

    def test_hero_tier_keeps_the_master_pixel_size_when_the_master_already_fits(self):
        """用户硬约束「打开单卡不降品质」：母版长边不超过详情档时，详情档与母版同像素。"""
        hero_long_edge = next(
            tier["long_edge"] for tier in production.APP_IMAGE_TIERS if tier["tier"] == "hero"
        )
        checked = 0
        for record in self.records:
            if record["tier"] != "hero":
                continue
            info = cardctl.image_info(ROOT / record["source"])
            if max(info["width"], info["height"]) <= hero_long_edge:
                self.assertEqual([record["width"], record["height"]], [info["width"], info["height"]])
                checked += 1
        self.assertGreater(checked, 0, "没有可核对的详情档，测试形同空跑")

    def test_staged_art_is_smaller_than_the_masters_it_replaces(self):
        staged_bytes = sum(record["bytes"] for record in self.records)
        master_bytes = sum(
            (ROOT / record["source"]).stat().st_size
            for record in self.records
            if record["tier"] == self.tiers[0]
        )
        self.assertLess(
            staged_bytes * 2, master_bytes,
            f"成片 {staged_bytes} 字节，母版 {master_bytes} 字节：换成成片的收益不足 2 倍",
        )

    def test_records_bind_each_tier_to_its_source_digest(self):
        for record in self.records:
            self.assertEqual(record["source_sha256"], cardctl.digest_file(ROOT / record["source"]))
            self.assertEqual(
                record["sha256"], cardctl.digest_file(self.art_dir / Path(record["file"]).name)
            )
            self.assertTrue(1 <= record["jpeg_quality"] <= 100)
            self.assertEqual(record["file"], f"CardArt/{Path(record['file']).name}")

    def test_grid_column_cap_stays_within_the_tile_tier(self):
        """列宽上限与瓦片档必须自洽：上限写宽了，超宽窗口下卡面会被放大到糊。

        上限写在客户端（`albumTileMaxDisplayWidth`，单位 pt），成片尺寸写在打包侧；
        两处是同一个「先给瓦片设上限、再定档」的关系，任何一边单独改动都会在这里失败。
        """
        source = (
            ROOT
            / "apps/WorldOfMysteries/Sources/WorldOfMysteriesFeatures/ArtworkStore.swift"
        ).read_text(encoding="utf-8")
        match = re.search(r"albumTileMaxDisplayWidth:\s*CGFloat\s*=\s*([0-9.]+)", source)
        self.assertIsNotNone(match, "客户端未声明 albumTileMaxDisplayWidth")
        cap_points = float(match.group(1))
        staged_widths = {record["width"] for record in self.records if record["tier"] == "tile"}
        self.assertTrue(staged_widths, "没有瓦片档可核对，测试形同空跑")
        self.assertLessEqual(
            cap_points * 2,
            min(staged_widths),
            f"列宽上限 {cap_points}pt 在 2x 下需要 {cap_points * 2}px，"
            f"瓦片档只有 {min(staged_widths)}px 宽",
        )
