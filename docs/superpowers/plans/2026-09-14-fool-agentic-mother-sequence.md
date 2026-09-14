# Fool Agentic Mother-to-Sequence Production Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current mixed Fool frame workflow with an Agentic mother-frame → five-tier material → ten-sequence inscription pipeline, then use the resulting assets to render and integrate the Fool sequence 9 Klein and sequence 0 Mr. Fool cards.

**Architecture:** Agentic generation owns the Fool-specific visual language, material studies, gemstone behavior, and local inscription treatment. A frozen `FrameCore + EmblemDock + NameSurface + GemSlot` owns geometry, alpha, exact glyph masks, protected regions, and final compositing. Five tier frames are shared by the ten sequence outputs; the sequence outputs select one tier, one approved fused emblem, and one right-side sequence inscription, never a 5×10 cross-product.

**Tech Stack:** Built-in `image_gen`, local PNG inspection, Swift/AppKit native raster renderers, Python JSON/schema orchestration, `jsonschema`, `unittest`, `cardctl`, and the existing macOS card compositor.

**Spec:** `docs/superpowers/specs/2026-09-14-fool-agentic-mother-to-sequence-design.md`

## Global Constraints

- The active visual scope is the Fool pathway and its ten sequence slots; other pathways remain out of scope.
- The five tier mapping is low 09/08, mid 07/06/05, saint 04/03, angel 02/01, true-god 00.
- The approved 0–9 fused Fool emblems remain immutable visual baselines; engineering cleanup cannot redesign their digit skeleton.
- One mother geometry is the only source of production coordinates; no scale, rotation, perspective, registration, or per-tier translation may hide drift.
- `max_anchor_drift_px=0`, `max_geometry_drift_px=0`, and sequence text center error is at most 1 final pixel.
- The right sequence zone is empty in the mother and tier frames; only the corresponding sequence inscription may change it.
- The name zone has no renderer-added background; later character names are exact relief masks on the existing surface.
- Agentic full-frame outputs are candidate references unless they pass native size, real alpha, protected-region, and zero-drift gates.
- All generated assets remain `pending-user-visual-approval` until the user visually approves them; machine gates never create approval evidence.
- Existing dirty worktree files and historical receipts remain intact; each new output uses a new versioned path and refuses overwrite.

---

### Task 1: Activate the v3 production contract and register the new asset graph

**Files:**
- Create: `docs/production-sop-v3.md`
- Modify: `AGENTS.md`
- Modify: `docs/card-production-index.md`
- Modify: `docs/pathway-carrier-sop.md`
- Modify: `.agents/skills/lotm-foundation/SKILL.md`
- Modify: `.agents/skills/lotm-hierarchy/SKILL.md`
- Modify: `.agents/skills/lotm-quality-frames/SKILL.md`
- Modify: `.agents/skills/lotm-symbols/SKILL.md`
- Modify: `.agents/skills/lotm-subject/SKILL.md`
- Create: `production/schemas/fool-mother-frame.schema.json`
- Create: `production/templates/fool-mother-frame-interface-v1.json`
- Create: `production/templates/fool-sequence-inscription-interface-v1.json`
- Create: `production/symbols/fool-mother-frame-v1.json`
- Create: `production/tasks/fool-mother-frame-v1.json`
- Create: `production/tasks/fool-five-tier-frame-batch-v1.json`
- Create: `production/tasks/fool-ten-sequence-frame-batch-v1.json`
- Modify: `tools/production.py`
- Test: `tests/test_fool_agentic_pipeline.py`

**Interfaces:**
- `fool-mother-frame.schema.json` validates `geometry_id`, `canvas`, `pathway_mark`, `emblem_dock`, `right_sequence_zone`, `name_surface`, `gem_slot`, `protected_regions`, ownership, and zero-drift thresholds.
- The mother task is a `hierarchy` concept task with a fixed 2:3 output contract and actual Fool frame references.
- The tier and sequence batch tasks are structured task manifests, not image attachments; their actual Agentic calls are recorded under `production/calls/` after generation.
- `tools/production.py task_dependencies()` records `docs/production-sop-v3.md` as the active SOP while retaining v2 for historical snapshot compatibility; new tasks bind the v3 hash explicitly.

- [ ] **Step 1: Write failing contract tests.**

  Add tests that load the new template/catalog/tasks and assert:

  ```python
  self.assertEqual(template["geometry_id"], "fool-agentic-mother-v1")
  self.assertEqual(template["right_sequence_zone"]["status"], "reserved-empty")
  self.assertEqual(template["name_surface"]["background_pixels"], 0)
  self.assertEqual(template["thresholds"]["geometry_displacement_max_px"], 0)
  self.assertEqual(catalog["sequence_mapping"], {
      "low": [9, 8], "mid": [7, 6, 5], "saint": [4, 3],
      "angel": [2, 1], "true-god": [0]
  })
  self.assertEqual(len(catalog["sequence_outputs"]), 10)
  self.assertEqual(len({row["tier"] for row in catalog["sequence_outputs"]}), 5)
  self.assertEqual(set(catalog["sequence_outputs"][0]["digits"]), {9})
  ```

- [ ] **Step 2: Run the focused contract test and confirm RED.**

  Run `python3 -m unittest tests.test_fool_agentic_pipeline.MotherContractTests -v`.
  It must fail because the v3 runtime contract and asset catalog do not exist.

- [ ] **Step 3: Add the v3 SOP and machine contracts.**

  Copy the approved design decisions into `docs/production-sop-v3.md`; make it the active entry in `AGENTS.md`, the production index, and the five relevant skills. Keep v2 as a historical document. The template must declare the top-left coordinate system, standard and collector canvas sizes, a single `GemSlot` with five tier materials, an empty right sequence zone, and a background-free name surface. The catalog must bind the existing ten approved emblem records, current five-tier color config, hierarchy config, emblem dock contract, and the new task paths.

- [ ] **Step 4: Extend dependency tracking without breaking historical tasks.**

  Update `task_dependencies()` so every new task records the v3 SOP, while existing v2 snapshots remain valid when they explicitly bind v2. Add a targeted test that compiles a new task and checks the v3 receipt hash is present.

- [ ] **Step 5: Run schema, contract, and scaffold checks.**

  Run:

  ```bash
  python3 -m unittest tests.test_fool_agentic_pipeline.MotherContractTests -v
  python3 -m json.tool production/schemas/fool-mother-frame.schema.json
  python3 -m json.tool production/templates/fool-mother-frame-interface-v1.json
  python3 tools/cardctl.py check --level scaffold
  ```

- [ ] **Step 6: Commit only this contract slice.**

  Run `git diff --check`, inspect the staged paths, and commit:

  ```bash
  git add AGENTS.md docs/production-sop-v3.md docs/card-production-index.md docs/pathway-carrier-sop.md .agents/skills/lotm-foundation/SKILL.md .agents/skills/lotm-hierarchy/SKILL.md .agents/skills/lotm-quality-frames/SKILL.md .agents/skills/lotm-symbols/SKILL.md .agents/skills/lotm-subject/SKILL.md production/schemas/fool-mother-frame.schema.json production/templates/fool-mother-frame-interface-v1.json production/templates/fool-sequence-inscription-interface-v1.json production/symbols/fool-mother-frame-v1.json production/tasks/fool-mother-frame-v1.json production/tasks/fool-five-tier-frame-batch-v1.json production/tasks/fool-ten-sequence-frame-batch-v1.json tools/production.py tests/test_fool_agentic_pipeline.py
  git commit -m "feat: define Fool mother-to-sequence production contract"
  ```

### Task 2: Implement deterministic mother cleanup, five-tier derivation, and sequence assembly

**Files:**
- Create: `tools/render/foolpipeline5.swift`
- Create: `production/symbols/recipes/fool-agentic-mother-to-sequence-v1.json`
- Modify: `tests/test_fool_agentic_pipeline.py`

**Interfaces:**
- `foolpipeline5 selftest`
- `foolpipeline5 mother ROOT INPUT NEW_OUTPUT`
- `foolpipeline5 tiers ROOT MOTHER_OUTPUT NEW_OUTPUT`
- `foolpipeline5 sequences ROOT TIER_OUTPUT NEW_OUTPUT`
- `foolpipeline5 gate ROOT OUTPUT`

- [ ] **Step 1: Add failing renderer tests.**

  Assert that selftest prints `mother-contract`, `single-gem-slot`, `right-zone-empty`, `name-surface-background-free`, `five-tier-mapping`, `geometry-zero`, `sequence-local-diff`, and `real-alpha`. Add a temporary-output integration test that requires one cleaned mother, five tier frames, five gem layers, ten emblem layers, ten sequence frames, per-sequence inscription layers, contact sheets, and a manifest.

- [ ] **Step 2: Run the renderer tests and confirm RED.**

  Run `python3 -m unittest tests.test_fool_agentic_pipeline.RendererTests -v` and confirm the missing binary/commands are the only failures.

- [ ] **Step 3: Implement the renderer from fixed contracts.**

  Use straight RGBA `Raster`, actual PNG decode, safe repository-relative paths, no overwrite, SHA-256 dependency binding, and local top-left coordinates. `mother` isolates only the approved mother silhouette and writes masks; it rejects baked checkerboard pixels entering the alpha layer. `tiers` applies Agentic-selected material parameters only inside frozen material/gem masks and compares alpha to the mother. `sequences` selects the tier from `config/sequence-hierarchy.json`, adds the matching approved emblem and exact right-side inscription layer, and compares all pixels outside the declared local diff domain. The renderer must reject missing/ambiguous mapping, `high` in place of saint/angel, changed master hashes, duplicate ownership, text outside the right zone, or nonzero geometry difference.

- [ ] **Step 4: Run selftest and structural renderer checks.**

  Compile with `swiftc -O tools/render/foolpipeline5.swift -o /tmp/foolpipeline5` and run `/tmp/foolpipeline5 selftest`. Then run the focused Python renderer tests and `git diff --check`.

- [ ] **Step 5: Commit the deterministic renderer slice.**

  ```bash
  git add tools/render/foolpipeline5.swift production/symbols/recipes/fool-agentic-mother-to-sequence-v1.json tests/test_fool_agentic_pipeline.py
  git commit -m "feat: add deterministic Fool frame pipeline"
  ```

### Task 3: Generate and freeze the Agentic Fool mother frame

**Files:**
- Create: `production/calls/fool-mother-frame-v1.json`
- Create: `artifacts/production/fool-mother-frame-v1/`
- Modify: `production/symbols/fool-mother-frame-v1.json`

**Interfaces:**
- Consumes the mother task, Fool direction, approved side-column style study, EmblemDock contract, and current quality geometry rules.
- Produces an Agentic mother study, a cleaned transparent `FrameCore` candidate, masks for the right sequence zone/name surface/gem slot, a contact preview, and a receipt that separates the Agentic source from the production-cleaned layer.

- [ ] **Step 1: Inspect all references before calling image generation.**

  Use `view_image` on the approved Fool side-column study, current low and true-god frames, the approved 0–9 emblem representative, and the diamond study. Record actual dimensions/channels and hashes. Do not send a contact sheet as the sole reference.

- [ ] **Step 2: Generate the mother candidate with the exact structured prompt.**

  The prompt must require a portrait 2:3 Fool pathway frame, left integrated artistic pathway identity, fixed top emblem recess, right empty sequence zone, bottom background-free name surface, one medium high-clarity gemstone slot above the bottom center, generous clean illustration window, and no sequence number, character name, subject, scene, pseudo-text, or watermark. It must explicitly preserve the initial Fool curled curtain columns and their material continuity without turning the right zone or name zone into closed pills.

- [ ] **Step 3: Inspect the returned image and classify it.**

  Record whether the output is RGBA or RGB, whether checkerboard pixels are baked, whether the left pathway mark is legible, whether the right zone/name zone/gem slot are correct, and whether extra text or objects exist. Keep the source as `agentic-mother-study` even when it fails production gates.

- [ ] **Step 4: Run `foolpipeline5 mother` into a new output directory.**

  The command must refuse an existing output directory, preserve the mother source hash, produce actual alpha and masks, and set status to `pending-engineering-review`. Run the mother gate and inspect the transparent frame on both dark and white backgrounds.

- [ ] **Step 5: Update the catalog and commit the mother receipt only.**

  Bind the real image/call/receipt hashes. Do not mark the mother approved until the user visually accepts the frame.

### Task 4: Generate five Agentic tier studies and materialize five frozen tier frames

**Files:**
- Create: `production/calls/fool-tier-frame-{low,mid,saint,angel,true-god}-v1.json`
- Create: `artifacts/production/fool-five-tier-frame-v1/`
- Modify: `production/symbols/fool-mother-frame-v1.json`
- Modify: `production/symbols/recipes/fool-agentic-mother-to-sequence-v1.json`
- Modify: `tests/test_fool_agentic_pipeline.py`

**Interfaces:**
- Each Agentic call receives the frozen mother as reference and produces a material/gem study; no study owns coordinates.
- `foolpipeline5 tiers` emits exactly five shared frames and five tier gemstones with identical alpha/geometry masks.

- [ ] **Step 1: Add the five-tier inventory test before generation.**

  Assert exact tier order `low, mid, saint, angel, true-god`, five gem layers, no tier-suffixed emblem assets, identical geometry hashes, and the configured palette IDs.

- [ ] **Step 2: Generate one independent Agentic study per tier.**

  Use the mother as the geometry reference and ask only for material, reflection, enamel, relief and gemstone behavior. Read the primary colors and hue-drift/gem-luminance policy from the config; do not maintain a second authoritative color table in the prompt record. Inspect each study with `view_image` and record material observations.

- [ ] **Step 3: Select material behavior and update the recipe.**

  Record which study features are adopted: controlled hue drift in frame texture, dark body plus facets plus highlights in the gem, pathway identity preserved in smoky-violet recesses, and no complexity escalation as a proxy for quality.

- [ ] **Step 4: Run the deterministic tier derivation and gate.**

  Run `foolpipeline5 tiers ROOT MOTHER_OUTPUT NEW_OUTPUT`, inspect the five-tier comparison, and verify alpha/geometry equality and gem protection around the name surface. Any Agentic geometry drift remains candidate-only.

- [ ] **Step 5: Commit the five-tier study records and deterministic kit metadata.**

  Keep all five calls and the recipe in the same versioned asset graph; status remains `pending-user-visual-approval`.

### Task 5: Generate ten local sequence inscriptions and assemble ten sequence frames

**Files:**
- Create: `production/calls/fool-sequence-inscription-{09,08,07,06,05,04,03,02,01,00}-v1.json`
- Create: `artifacts/production/fool-ten-sequence-frame-v1/`
- Modify: `production/symbols/fool-mother-frame-v1.json`
- Modify: `tests/test_fool_agentic_pipeline.py`

**Interfaces:**
- Each inscription call receives only the fixed right-zone crop and Fool inscription style references.
- The output is a local candidate layer; the renderer keeps only exact characters, relief, alpha, and pixels inside the right-zone mask.

- [ ] **Step 1: Generate the ten local engraving studies.**

  Use the compiled Fool sequence names from the pathway/card source. Prompt for upright vertical inscription, a continuous recessed rail integrated into the right pillar, no capsule panel, no new background, no mirror text, and no changes outside the crop. Store each real prompt and input hash.

- [ ] **Step 2: Run exact glyph and local-diff gates.**

  Reject any candidate with pseudo-text, wrong characters, mirror orientation, overlap, crop drift, or pixels outside the right safe rectangle. For accepted style behavior, derive the exact character face/bevel/glint from the program-controlled glyph mask.

- [ ] **Step 3: Assemble the ten sequence frames.**

  Run `foolpipeline5 sequences ROOT TIER_OUTPUT NEW_OUTPUT`; verify mapping 09/08→low, 07/06/05→mid, 04/03→saint, 02/01→angel, 00→true-god; bind one emblem per sequence; output exactly ten frames and no 50-way variants.

- [ ] **Step 4: Inspect representative and full inventories.**

  Inspect 09, 07, 04, 02, 00 at 100% and thumbnail scale, then the full ten-frame contact sheet, dark/white previews, right-zone difference maps, and gem/name crops. Record machine results separately from visual judgment.

- [ ] **Step 5: Commit the sequence asset graph.**

  Commit only the new calls, receipts, manifests, diagnostics, and focused tests; leave formal approval false.

### Task 6: Rebuild the Klein sequence 9 and Mr. Fool sequence 0 cards on the new carrier

**Files:**
- Modify or create the current `production/tasks/fool-s09-subject-v*.json` and its call/receipt using a new versioned revision
- Modify or create the current `production/tasks/fool-s00-subject-v*.json` and its call/receipt using a new versioned revision
- Create: `production/tasks/fool-s09-card-v1.json`
- Create: `production/tasks/fool-s00-card-v1.json`
- Create: `production/calls/fool-s09-card-v1.json`
- Create: `production/calls/fool-s00-card-v1.json`
- Create: `artifacts/production/fool-s09-card-v1/`
- Create: `artifacts/production/fool-s00-card-v1/`
- Modify: `tests/test_fool_agentic_pipeline.py`

**Interfaces:**
- Each card consumes one final sequence frame, one integrated subject/background scene, the exact character-name contract, the six-dimensional semantic source, and the independent narrative package.
- The subject scene contains no card text; the final carrier supplies the side pathway/sequence names, approved emblem, gem, and background-free character-name engraving.

- [ ] **Step 1: Reconcile current character identity and evidence.**

  Read the current Fool 09 and Fool 00 `card.json`, canon, direction, narrative contracts, and evidence. Preserve the existing verified Klein Chinese name `克莱恩·莫雷蒂` and the approved Mr. Fool identity boundary; do not invent new canon facts.

- [ ] **Step 2: Produce or reuse approved subject scenes with the new frame as the only carrier reference.**

  Generate the sequence 9 Klein scene and sequence 0 Mr. Fool scene separately. Require one main event, no explanatory text, no borders, no pseudo-glyphs, and a background that can coexist with the fixed carrier window. Record actual calls and inspect both scenes.

- [ ] **Step 3: Render the names onto the existing name surface.**

  Use the current exact glyph renderer with `克莱恩·莫雷蒂` for sequence 9 and the verified Mr. Fool display name for sequence 0. Enforce actual ink-box centering, no background pixels, no duplicate face layers, and full gemstone protection.

- [ ] **Step 4: Compose and gate both cards.**

  Produce standard and collector outputs only when the chosen profile is explicitly requested by the task. Run subject/design/composition/release checks as far as the approval state allows; keep visual approval and formal release separate.

- [ ] **Step 5: Perform a side-by-side visual review.**

  Inspect the two full cards at 100%, thumbnail size, dark/light backgrounds, and enlarged crops for the top emblem, right inscription, name, gem, and scene junction. Record defects as a new revision rather than painting over the artifact.

### Task 7: Integrate the two verified card candidates into the app without promoting unapproved art

**Files:**
- Read/modify only the existing Fool card fixture/catalog files under `apps/LotmCardStudio/` that currently point at old candidate resources
- Create: `apps/LotmCardStudio/docs/qa/fool-carrier-v3.md`
- Test: existing Swift tests under `apps/LotmCardStudio/`

**Interfaces:**
- The app receives isolated candidate card resources and their status/receipt metadata; it must not treat a machine-gated or user-unapproved artifact as formal canon.

- [ ] **Step 1: Write the failing fixture/catalog test.**

  Assert that the two displayed cards use the new versioned candidate paths, stable `card_id`s remain distinct, names are not mirrored, and approval status is represented separately from render success.

- [ ] **Step 2: Update the fixture and run Swift tests.**

  Keep the app changes limited to the two requested candidate resources and their metadata. Run the relevant `swift test` target and debug/release app builds if the fixture is bundled into the app.

- [ ] **Step 3: Record QA and visual limitations.**

  Document the new carrier, exact frame hashes, card hashes, status, and any remaining visual approval. Do not claim formal release merely because the app displays the files.

---

## Final verification checklist

- [ ] `python3 -m unittest discover -s tests -v`
- [ ] `python3 tools/cardctl.py check --level scaffold`
- [ ] `python3 tools/cardctl.py check --level design --card fool:09`
- [ ] `python3 tools/cardctl.py check --level design --card fool:00`
- [ ] `foolpipeline5 selftest`
- [ ] `foolpipeline5 gate` for mother, five tiers, and ten sequences
- [ ] `fooltext3 selftest` and `fooltext3 gate` for exact names/inscriptions
- [ ] PNG dimension, RGBA, alpha, sRGB, SHA-256, protected-region, and zero-drift checks
- [ ] `swift test` and applicable debug/release app builds
- [ ] `git diff --check`
- [ ] User visual approval recorded separately for mother, five tiers, ten sequence frames, and the two cards

The final report must list completed, pending, rejected, and unverified items independently. It must not convert a green structural gate into artistic approval, canonical approval, or formal release.
