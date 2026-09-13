# Fool Five-Tier Materials Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the active Fool pathway four-tier material study with a verified five-tier material kit and ten sequence-specific transparent frame outputs for sequences 9–0.

**Architecture:** Keep the approved 0–9 Fool fusion emblems as immutable visual inputs. Generate five Agentic material studies for the shared Fool frame language, then use a new versioned native renderer to apply fixed-coordinate texture and gemstone grading to one frozen geometry master; the renderer derives ten sequence outputs from the five-tier mapping and performs zero-drift checks.

**Tech Stack:** Swift/AppKit native raster renderer, Python `unittest`, JSON task/manifest contracts, built-in `image_gen`, PNG/sRGB/RGBA assets, `shasum`, `file`, and repository `cardctl`/production checks.

**Spec:** `docs/superpowers/specs/2026-09-13-fool-five-tier-materials-design.md`

## Global Constraints

- The active scope is the Fool pathway only, sequences 9–0; other pathways and character cards are out of scope.
- All ten approved Fool fusion emblems are accepted visual baselines; no new emblem-shape redesign is required.
- The old four-tier kit is not an active asset, delivery baseline, or fallback; it must not be renamed into the new kit.
- The five tiers are low 9/8, mid 7/6/5, saint 4/3, angel 2/1, and true-god 0.
- Primary colors are read from `config/quality-color-tokens.json`; no second hand-maintained color table is authoritative.
- Quality changes may affect frame texture, enamel, and gemstone material only; frame geometry, emblem digit skeleton, anchors, name area, and illustration window remain fixed.
- `max_anchor_drift_px=0` and `max_geometry_drift_px=0`; registration, warp, per-tier offsets, and cropping cannot hide drift.
- Outputs remain `pending` until visual review and user approval; no App integration, audio generation, or 220-card release is included.
- Existing user changes and historical receipts outside this plan must be preserved; any old-kit cleanup uses exact targets and a recoverable move.

---

### Task 1: Version the five-tier contract and active Fool asset catalog

**Files:**
- Create: `production/symbols/quality-frame-five-tier-direction.json`
- Create: `production/symbols/fool-five-tier-kit.json`
- Create: `production/symbols/tasks/fool-quality-frame-low-v2.json`
- Create: `production/symbols/tasks/fool-quality-frame-mid-v2.json`
- Create: `production/symbols/tasks/fool-quality-frame-saint-v2.json`
- Create: `production/symbols/tasks/fool-quality-frame-angel-v2.json`
- Create: `production/symbols/tasks/fool-quality-frame-true-god-v2.json`
- Modify: `production/symbols/fool-fusion-family.json`
- Modify: `production/symbols/fool-fusion-preservation.json`
- Modify: `.agents/skills/lotm-hierarchy/SKILL.md`
- Modify: `.agents/skills/lotm-quality-frames/SKILL.md`
- Modify: `.agents/skills/lotm-symbols/SKILL.md`
- Test: `tests/test_fool_five_tier.py`

**Interfaces:**
- Consumes: `config/quality-color-tokens.json`, `config/sequence-hierarchy.json`, `production/symbols/quality-geometry-lock.json`, `production/symbols/fool-frame-kit.json`, and the ten existing `production/symbols` fusion records.
- Produces: a five-tier catalog with exact `tier_id`, sequence mapping, master geometry, five task paths, ten emblem input bindings, active output path, and an explicit `legacy_four_tier_status` that excludes the old kit from active assets; the existing Fool fusion family records a top-level current approval for all ten 0–9 emblems as `user-approved-visual-baseline` while keeping historical per-entry observations, engineering transparency and formal release separate.

- [ ] **Step 1: Write the failing contract tests.**

  Add tests that load the catalog and assert:

  ```python
  self.assertEqual(catalog["sequence_mapping"], {
      "low": [9, 8],
      "mid": [7, 6, 5],
      "saint": [4, 3],
      "angel": [2, 1],
      "true-god": [0],
  })
  self.assertEqual(set(catalog["approved_emblems"]), set(range(10)))
  self.assertFalse(catalog["legacy_four_tier_status"]["active"])
  for tier in ["low", "mid", "saint", "angel", "true-god"]:
      self.assertEqual(tasks[tier]["quality"]["visual_tier"], tier)
  ```

- [ ] **Step 2: Run the focused tests and confirm RED.**

  Run:

  ```bash
  python3 -m unittest discover -s tests -p 'test_fool_five_tier.py' -v
  ```

  Expected result: failure because the versioned catalog, five tasks, and test module do not yet exist.

- [ ] **Step 3: Add the catalog and task contracts.**

  Each task must use the existing schema shape, use one representative `quality.sequence` accepted by the current compiler (9 for low, 7 for mid, 4 for saint, 2 for angel, and 0 for true-god), set the matching `hierarchy.spec.tier`, bind `production-preflight.md`, the quality direction, geometry lock, color config, and the appropriate material/geometry references, and use `saint`/`angel` explicitly rather than `high`. The catalog carries the complete sequence lists and must identify the approved emblem records for digits 0 through 9 and set the new output root to `artifacts/production/fool-five-tier-kit-v1`.

  Update the three skills and both existing Fool fusion records so their active Fool rule declares all 0–9 emblems in a top-level current approval as user-approved visual baselines, while historical observations, engineering transparency and placement remain separate gates; the old four-tier kit is historical and inactive, not a fallback.

- [ ] **Step 4: Run the focused tests and structural checks.**

  Run:

  ```bash
  python3 -m unittest discover -s tests -p 'test_fool_five_tier.py' -v
  python3 tools/cardctl.py check --level scaffold
  ```

  Expected result: focused contract tests pass; scaffold check reports 22 pathways and 220 card slots with no new errors.

- [ ] **Step 5: Review and commit the contract slice.**

  Run `git diff --check`, inspect only the staged contract/skill files, then commit:

  ```bash
  git add production/symbols/quality-frame-five-tier-direction.json production/symbols/fool-five-tier-kit.json production/symbols/tasks/fool-quality-frame-*-v2.json .agents/skills/lotm-hierarchy/SKILL.md .agents/skills/lotm-quality-frames/SKILL.md .agents/skills/lotm-symbols/SKILL.md tests/test_fool_five_tier.py
  git commit -m "feat: define Fool five-tier material contract"
  ```

### Task 2: Add the zero-drift five-tier native renderer

**Files:**
- Create: `tools/render/foolkit5.swift`
- Modify: `tests/test_fool_five_tier.py`
- Create: `production/symbols/recipes/fool-five-tier-materials.json`

**Interfaces:**
- Consumes: the Task 1 catalog, geometry lock, color config, frozen mother frame, and ten approved fusion PNGs.
- Produces: `foolkit5 selftest`, `foolkit5 prepare ROOT OUT`, and `foolkit5 gate ROOT OUT`; a manifest with input/output hashes, tier mapping, geometry comparison counts, alpha diagnostics, and renderer digest.

- [ ] **Step 1: Add failing native-renderer tests.**

  Extend `tests/test_fool_five_tier.py` with tests that compile `tools/render/foolkit5.swift`, run `selftest`, and assert the native report includes `five-tier-mapping`, `geometry-zero`, `alpha-real`, `gem-highlight-preserved`, and `legacy-four-tier-rejected`. Add an integration test that runs `prepare` into a fresh temporary output and asserts five tier frames, ten sequence frames, ten emblem layers, deep/white diagnostics, a contact sheet, and `manifest.json` exist.

- [ ] **Step 2: Run the native tests and confirm RED.**

  Run:

  ```bash
  python3 -m unittest discover -s tests -p 'test_fool_five_tier.py' -v
  ```

  Expected result: failure because `tools/render/foolkit5.swift` and the recipe are absent.

- [ ] **Step 3: Implement the minimal versioned renderer.**

  Implement straight-RGBA `Raster`, SHA-256 input/output binding, safe repository-relative path resolution, non-overwriting output, actual PNG decoding, and these functions:

  ```swift
  func qualityTier(for sequence: Int, mapping: [String: [Int]]) throws -> String
  func fixedMaterial(_ source: Raster, tier: TierSpec, masks: MaterialMasks) -> Raster
  func geometryDifference(_ lhs: Raster, _ rhs: Raster) throws -> Int
  func renderSequenceFrame(frame: Raster, emblem: Raster, sequence: Int, geometry: GeometryLock) throws -> Raster
  func prepare(root: URL, output: URL) throws
  func gate(root: URL, output: URL) throws
  ```

  The renderer must read primary colors, hue drift drivers, and gemstone luminance rules from the color config. It must preserve alpha and source coordinates, apply material differences only inside fixed regions, keep dark slots and bright facets together, and reject a missing saint/angel split, changed master hash, changed mask hash, output overwrite, alpha-less emblem, geometry difference, or recomputed placement mismatch. It must not use the old four-tier mapping or accept `high` as a new saint/angel substitute.

  Use one frozen geometry master and one set of masks. Use the approved 0–9 fusion PNGs as separate input files; clean background/holes only through the recorded per-emblem matte settings without changing the approved digit skeleton. Derive each sequence frame from the tier frame and its own digit; do not copy sequence 9 placement measurements.

- [ ] **Step 4: Run the native tests and recipe checks.**

  Run:

  ```bash
  python3 -m unittest discover -s tests -p 'test_fool_five_tier.py' -v
  python3 -m json.tool production/symbols/fool-five-tier-kit.json
  ```

  Expected result: native selftest and temporary prepare/gate pass; the catalog/recipe is structurally accepted, while visual status remains `pending`.

- [ ] **Step 5: Review and commit the renderer slice.**

  Run `git diff --check`, inspect the renderer and focused tests, then commit:

  ```bash
  git add tools/render/foolkit5.swift production/symbols/recipes/fool-five-tier-materials.json tests/test_fool_five_tier.py
  git commit -m "feat: add deterministic Fool five-tier renderer"
  ```

### Task 3: Generate the five Agentic material studies

**Files:**
- Create: `production/calls/fool-five-tier-material-{low,mid,saint,angel,true-god}-v1.json`
- Create: `artifacts/production/fool-five-tier-material-{low,mid,saint,angel,true-god}-v1/`
- Modify: `production/symbols/fool-five-tier-kit.json`

**Interfaces:**
- Consumes: frozen Fool geometry, double-sided curtain junction, quality direction, color config, and actual approved Fool emblem/frame references.
- Produces: five independently generated material-study PNGs with real call records, prompt text, attachment list, input hashes, visual observations, and `pending` status. These studies inform the deterministic material recipe; they do not authorize geometry changes.

- [ ] **Step 1: Inspect actual reference images before generation.**

  Use `view_image` for the frozen master frame and a representative approved fusion emblem. Confirm the references are available as local files, record their paths and SHA-256 values, and do not use a contact sheet as the only image input.

- [ ] **Step 2: Generate one independent study per tier with built-in `image_gen`.**

  Use the shared prompt structure:

  ```text
  Use case: stylized-concept
  Asset type: Fool pathway five-tier frame material study
  Input images: frozen frame geometry as reference; approved Fool fusion emblem as style/connection reference
  Primary request: create only the material, enamel, relief, reflection, and gemstone treatment for the named quality tier
  Composition/framing: full upright 2:3 frame study, same silhouette and same internal coordinates
  Constraints: preserve outer contour, inner window, curtain junctions, emblem safe region, nameplate, quality marker, and all anchors exactly; no text; no new emblem; no extra ornament count; no subject or scene
  Avoid: position drift, warped geometry, moved windows, moved nameplate, altered digit skeleton, oversized emblem, global card tint, random rainbow noise, clipped-white gem, large bloom
  ```

  Replace only the tier-specific material intent and palette from `config/quality-color-tokens.json`. Make five separate built-in calls; do not use `n` or a five-panel prompt as a substitute. Save each returned image into its versioned workspace directory, record the actual prompt and attachments, inspect the output with `view_image`, and retain it as a material study even if the deterministic renderer later rejects it as a geometry source.

- [ ] **Step 3: Register observations and bind studies to the recipe.**

  For each study record: visible material hierarchy, hue drift, gemstone body/dark facet/highlight/refraction behavior, geometry drift observation, text/extra-object observation, and whether it is usable as a material reference. Set `art_review` and `engineering` to `pending` until the actual five-tier kit is inspected.

- [ ] **Step 4: Review and commit only the study records and prompts.**

  Do not stage generated build output or unrelated user files. Stage the five call records, prompt/observation files, and catalog binding, run `git diff --check`, then commit:

  ```bash
  git add production/calls/fool-five-tier-material-*.json production/symbols/fool-five-tier-kit.json
  git commit -m "feat: add Fool five-tier material studies"
  ```

### Task 4: Render and gate the ten sequence material outputs

**Files:**
- Create: `artifacts/production/fool-five-tier-kit-v1/`
- Modify: `production/symbols/fool-five-tier-kit.json`
- Create: `reports/fool-five-tier-materials-v1.md`
- Test: `tests/test_fool_five_tier.py`

**Interfaces:**
- Consumes: the Task 1 catalog, Task 2 renderer, frozen geometry, Task 3 material studies, and all ten approved fusion inputs.
- Produces: five tier frames, ten `fool-<sequence>-frame.png` files, ten clean emblem layers, deep/white diagnostics, contact sheets, manifest, and a report separating machine gates from visual/user approval.

- [ ] **Step 1: Add output inventory assertions before running production.**

  Add tests asserting the exact inventory:

  ```python
  self.assertEqual(set(report["tier_frames"]), {"low", "mid", "saint", "angel", "true-god"})
  self.assertEqual(report["sequence_frames"], [9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
  self.assertTrue(all(item["geometry_difference_pixels"] == 0 for item in report["sequence_entries"]))
  self.assertFalse(report["release_approved"])
  ```

- [ ] **Step 2: Run the output-inventory test and confirm RED.**

  Run `python3 -m unittest discover -s tests -p 'test_fool_five_tier.py' -v`; it must fail because the new kit has not been generated.

- [ ] **Step 3: Run `foolkit5 prepare` into the new output directory.**

  Compile and run the versioned renderer from the repository root:

  ```bash
  mkdir -p generated/production/bin
  swiftc -O tools/render/foolkit5.swift -o generated/production/bin/foolkit5
  generated/production/bin/foolkit5 prepare . artifacts/production/fool-five-tier-kit-v1
  ```

  The command must fail rather than overwrite if the directory already exists. The output must contain exactly five shared tier frames and ten sequence frames; the ten sequence-to-tier bindings must be low 9/8, mid 7/6/5, saint 4/3, angel 2/1, true-god 0.

- [ ] **Step 4: Run the complete machine gate and inspect actual pixels.**

  Run:

  ```bash
  generated/production/bin/foolkit5 gate . artifacts/production/fool-five-tier-kit-v1
  python3 -m unittest discover -s tests -p 'test_fool_five_tier.py' -v
  ```

  Check actual decoded PNGs for 2048×3072, RGBA, sRGB, real transparent pixels, unchanged geometry alpha, independently recomputed emblem placement, and source-over edge behavior. Inspect five-tier contact sheet, ten-sequence contact sheet, dark/white diagnostics, and enlarged seam/gem crops with `view_image`.

- [ ] **Step 5: Write the production report.**

  Record the exact output hashes, renderer/config/geometry hashes, five Agentic study references, mapping table, gate results, visual observations, known issues, and statuses. State explicitly that user approval of 0–9 emblem shapes does not itself approve the new color/material outputs or formal release.

- [ ] **Step 6: Review and commit the generated kit metadata.**

  Stage only the intended new kit, report, catalog, and focused test changes. Do not stage `.build`, `generated/production/bin`, or unrelated artifacts. Commit:

  ```bash
  git add artifacts/production/fool-five-tier-kit-v1 production/symbols/fool-five-tier-kit.json reports/fool-five-tier-materials-v1.md tests/test_fool_five_tier.py
  git commit -m "feat: render Fool five-tier sequence materials"
  ```

### Task 5: Remove the old four-tier kit from the active workspace

**Files:**
- Modify: `production/symbols/fool-frame-kit.json`
- Modify: `production/symbols/quality-frame-family.json`
- Modify: `production/symbols/quality-geometry-lock.json`
- Modify: `reports/fool-frame-kit.md`
- Modify: `reports/fool-five-tier-materials-v1.md`
- Test: `tests/test_fool_five_tier.py`

**Interfaces:**
- Consumes: exact references found by repository search, the completed five-tier catalog, and the new gate report.
- Produces: an active asset index that excludes the old four-tier output and a recoverable cleanup record; historical evidence is not rewritten as a new five-tier result.

- [ ] **Step 1: Inventory old four-tier references.**

  Search exact names and paths before moving anything:

  ```bash
  rg -n 'fool-frame-kit-v3|fool-quality-frame-(low|mid|high|true-god)|fool-frame-kit.json|foolkit.swift' production reports tests docs .agents
  ```

  Classify each reference as active input, historical audit record, test fixture, or obsolete pointer. Do not remove a file that the new kit still consumes.

- [ ] **Step 2: Add a failing active-set test.**

  Assert that `production/symbols/fool-five-tier-kit.json` is the only active Fool frame kit and that the old four-tier catalog has `active: false` and does not appear in new output dependencies.

- [ ] **Step 3: Update active pointers and perform exact recoverable cleanup.**

  Change active catalog references to the five-tier kit. For obsolete old four-tier output directories identified in Step 1, move only those exact paths to the macOS user Trash with a bounded command, preserving a cleanup receipt listing original path, destination, timestamp, and recovery action. Leave audit-only records readable unless they are proven to be obsolete and unreferenced.

- [ ] **Step 4: Run active-set and production gates.**

  Run:

  ```bash
  python3 -m unittest discover -s tests -p 'test_fool_five_tier.py' -v
  generated/production/bin/foolkit5 gate . artifacts/production/fool-five-tier-kit-v1
  python3 tools/cardctl.py check --level scaffold
  ```

- [ ] **Step 5: Commit the active-set cleanup.**

  Run `git diff --check`, inspect exact moved/modified paths, and commit:

  ```bash
  git add production/symbols/fool-frame-kit.json production/symbols/quality-frame-family.json production/symbols/quality-geometry-lock.json reports/fool-frame-kit.md reports/fool-five-tier-materials-v1.md tests/test_fool_five_tier.py
  git commit -m "chore: retire Fool four-tier material baseline"
  ```

### Task 6: Final verification and handoff

**Files:**
- Modify: `apps/LotmCardStudio/docs/qa/m1-local-run.md` only if the new material kit is intentionally documented for the app; do not integrate it into the app in this task.

**Interfaces:**
- Consumes: all five task commits, new material studies, five-tier output, cleanup record, and current repository verification commands.
- Produces: a final verification record with explicit pass/fail/unknown statuses and a user-facing list of paths.

- [ ] **Step 1: Run fresh focused and project checks.**

  Run each command after the last code or data change:

  ```bash
  python3 -m unittest discover -s tests -p 'test_fool_five_tier.py' -v
  python3 tools/cardctl.py check --level scaffold
  python3 -m json.tool production/symbols/fool-five-tier-kit.json
  generated/production/bin/foolkit5 gate . artifacts/production/fool-five-tier-kit-v1
  git diff --check
  ```

- [ ] **Step 2: Run the repository suite and record unrelated failures honestly.**

  Run `python3 -m unittest discover -s tests -v`. If historical receipt mismatches remain, report the exact count and first cause separately from the Fool five-tier focused gate; do not regenerate unrelated assets merely to make the suite green.

- [ ] **Step 3: Perform final five-axis review.**

  Review correctness of mapping and zero-drift enforcement, readability of task/manifest/report names, architecture boundary between Agentic studies and deterministic renderer, absence of secrets or external dependencies, and bounded output generation. Confirm no old four-tier output is active and no new output is labeled approved/release.

- [ ] **Step 4: Give the final handoff.**

  Report the five tier paths, ten sequence frame paths, study/report paths, tests and gates with actual counts, cleanup scope and recoverability, visual items still awaiting user review, and explicit exclusions: other pathways, character cards, App integration, audio, and formal release.
