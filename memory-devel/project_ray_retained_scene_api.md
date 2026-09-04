---
name: ray-retained-scene-api
description: "Retained-scene Janet API — R1-R7 ALL DONE + merged to main 2026-08-16 (@b2388db); doc docs/retained-scene-api-plan.md; snapshot/2-way translation shipped"
metadata: 
  node_type: memory
  type: project
  originSessionId: d45ea68f-c449-495d-90b5-87301ee6df3f
---

**ALL STAGES R1–R7 DONE + MERGED TO MAIN 2026-08-16 (ff, origin/main
@b2388db)**. Final stages beyond what's below:
- **R7 @0a97146**: (snapshot &opt path &named expand) — origin recording in
  every wrapper (templates w/ %MAT% re-read from store → set-albedo tweaks
  captured; the user's 2-way requirement TESTED end-to-end); generators got
  **:seed** (private RNG via (dyn :ray-rng); unseeded path bit-identical);
  unseeded random groups AUTO-EXPAND to add-mesh buffers
  (TriangleMesh::vertex_normals reconstructs smooth normals); gltf always
  compact; with-group/defgroup capture body source (code-lit honors parser
  bracket flags; data `lit` ALWAYS brackets — %j prints paren tuples that
  EVALUATE on reload!); seed rule in doc REVISED (derivation = parity break).
  14 read-only %-callbacks (+janet_array bindings). Limitations documented:
  group-member setter tweaks exact only via expansion; closures in with-group
  source; snapshot = state fidelity not source fidelity.
- **&opt/&named FOOTGUN @b2388db**: Janet fills &opt before &named → :name
  after unfilled optional was SILENTLY swallowed (scene.janet :box was keyed
  :shape-0 through R5/R6!). Fix: material is now the LAST positional —
  add-cuboid **:bevel**, add-sphere-mesh/add-cuboid-mesh/add-cone **:smooth**
  named; add-mesh keeps positional normals/translation/rotation + loud
  keyword-in-optional-slot guard. pastel-blocks' multi-line positional bevels
  caught ONLY by the byte-identical matrix (silently dropped → unbeveled).
- **R6 @950d7e0**: provenance mark-and-sweep (file_born set + sync window per
  scene); C-c C-b send-buffer = converging sync; eval-error counter aborts
  sweep on broken buffer (%sync-abort); load-scene/--scene loads are
  file-born; empty-buffer-sync-after-load empties scene (pinned).
Final: 376 Rust tests + 21 elisp, 31/31 byte-identical at EVERY stage.
Branch r1-material-values can be deleted (fully merged).
Remaining future work (doc Future section): BVH refit + material-only-upsert
skip, per-member group addressing, scene diffing, *render* params table,
scene.janet defshape-style rewrite (optional showcase).

**defshape/defgroup DONE 2026-08-16 @fc9424c** (user-requested "R5.5"; born
from the "would the design be the same in CL?" discussion — defining forms
upsert, like defun): name in defining position + bound as a SYMBOL →
compile-checked references (typoed keyword silently upserts a new shape;
typoed symbol errors). :name stays for computed names. 367 tests; spot
parity 3/3. scene.janet NOT yet rewritten in defshape style (optional).

**USER DRAG-TESTED 2026-08-16: live drag + resend WORK on the branch** (also
validates E2 mouse plumbing signs/feel — no complaints raised). Found the R6
delete-gap immediately: sending a different file's buffer = mixed scenes →
**shipped @db79091: janet-clear-and-send-buffer (C-c C-l)** = (clear-scene) +
buffer + *scene-file*; C-c C-b stays upsert. Doc R6 section notes the interim;
mark-and-sweep still planned for same-file deletions. 20 elisp tests.
Also @129750b prelude naming-convention note (make-/add-/def*/set-/!).

**R5 DONE (FLAG DAY) 2026-08-16 @780a6c8**: (render) = trace the store
everywhere; build_scene/run_scene/SCENE_FN/%register-scene DELETED;
register-scene = prelude shim (warn+clear+run-once; no hot-swap — re-call the
fn). All 30 examples ported via minimal `(register-scene scene)`→`(scene)`
(structured-into-functions stays idiomatic); scene.janet rewritten FLAT with
:names matching old ordinal aliases; bounce/dof render.sh re-call (scene) per
sweep step (sweep vars no longer rebuild via (render)!). live.janet setters
name-keyed via %update-material (+set-emissive; geometry setters RETIRED —
re-send the named add form); load-scene clears first; prelude mirror vars
deleted; WIRE_STYLE reseeds at clear-scene/make-scene. Matrix now 31 scenes
(added bokeh/bounce/dof subdir examples, baselines from R4 binary). 365
tests, **31/31 byte-identical**. Remaining: R6 (sync/mark-and-sweep + studio
markers), R7 (snapshot + seed capture).

**R4 DONE 2026-08-15 @6a21612**: SceneRegistry (current + name-keyed builders)
behind with_builder; %make-scene/%use-scene/%current-scene/%get-camera
(12-tuple, f32 → tests use 1e-4 tolerances); bare-REPL renders w/o
register-scene (can_render/full_build; binary gates updated); **with-scene
macro DECIDED instead of per-command :scene** (user's Lisp with-resource
idiom; doc amended @5120f69) + with-group over in-group; set-camera *camera*
sync REMOVED, orbit!/pan!/dolly! read %get-camera via camera-pose/move-camera!
in live.janet (per-scene cameras; DOF now preserved during moves); *camera*
var only remains as scene.janet authored data until R5. Scene switch clears
RETAINED+pending. 362 tests, 28/28 byte-identical.

**R3 DONE 2026-08-15 @5318e91**: ShapeEntry::One|Group; load-gltf + grow-branches*
= one atomic group entry (auto :group-N), %group-begin/%group-end + public
in-group (defer commits partial group on error); failed gltf re-load EMPTIES
the group (visible, not silently stale); **seed capture DEFERRED to R7**
(mid-stream derivation would break parity gate; seed field + arg plumbed,
passes nil); 357 tests, 28/28 byte-identical.

**R2 DONE 2026-08-15 on branch @9fbb41d**: IndexMap name-keyed stores in
SceneBuilder; add-* takes :name + returns keyword key (auto :shape-N/:light-N);
upsert replaces in place; flat namespace (light :sun evicts shape :sun);
remove-shape/remove-light/clear-* ; finish() clones (Shape now Clone via
Arc<dyn Geometry>; textures cloned too); geometry_dirty pinned by tests but
unconsumed until R5; bindgen allowlist += janet_string/janet_wrap_string;
352 tests green (9 new), 28/28 byte-identical. R2 caveat documented: (render)
still re-runs scene fn → REPL removes undone until R5. Next: R3 groups.

**R1 DONE 2026-08-15 on branch `r1-material-values` @c16eb7f (NOT merged to
main; user wanted a separate branch)**: materials are values; one
%set-material (30 flat args w/ has-* flags) replaced the 8 %mat-* cfunctions;
load-gltf :material value option (+:material-fn compat); grow-branches accepts
value-or-fn; 343 tests green (5 new); **28/28 renders byte-identical**
(release binary, clean (save-image) saves — NOTE the startup --out auto-save
is STAMPED with Mpix/s → nondeterministic bytes; always compare via clean
saves. Binary loads scripts/prelude.janet from the repo path baked at compile
time, so baseline renders need the pristine prelude checked out — stash first).
Also on branch @c2668b3: doc §"Live mode" requirement. Next: R2.

DESIGN 2026-08-15 (user's proposal, doc written, R1 built, R2+ not yet):
`docs/retained-scene-api-plan.md` — invert the scene model: ray retains the
scene in memory as truth; the file becomes a convergent script. Supersedes
the `register-scene` re-run model.

Key decisions pinned in the doc:
- **Upsert by name**: every `add-*` takes `&named name scene`; same name →
  replace in place (this is what makes editor re-sends idempotent — the user's
  key insight that answered my earlier objection to retained handles).
  Unnamed adds are append-only, return an auto-id handle.
- **Materials become values** (R1, land first/alone): `(material ...)` returns
  a struct; kills the side-effect protocol, `%mat-*` staging, material-fn
  thunks, and the cond trap ([[janet-cond-material]]). Call sites read
  identically — style preservation was an explicit user requirement ("keep
  the style of the existing functions").
- **Groups**: load-gltf/grow-branches `:name` scopes all produced shapes;
  atomic group replace; resend re-rolls randomness (use math/seedrandom to
  pin; no :seed arg).
- **Scenes as values** + current-scene default; settings (camera/film/sky/…)
  live on the scene value; prelude `*camera*`/`*shapes*` parallel state
  retires (orbit! reads via %get-camera).
- **Buffer sync delete gap**: provenance mark-and-sweep — ray-studio wraps
  send-buffer in `(%sync-begin)`/`(%sync-end)`; file-born names not
  re-asserted get swept, repl-born survive; expression sends never sweep;
  load-scene = clear+sync.
- **`(snapshot &opt path)`** serializes retained scene back to loadable Janet
  source (round-trip byte-identical render = the test); this is also the
  editor's codegen capability ([[ray-interactive-editor]] "addressing"
  prerequisite — this API IS the addressing substrate). USER REQUIREMENT
  2026-08-15: translation must be 2-way (REPL edits → script). Pinned @1eed264:
  state fidelity guaranteed / source fidelity not (canonical flattened calls);
  seed rule — group calls record RNG seed (derived if unseeded, stored in R3),
  snapshot emits (math/seedrandom ...) preamble; `:expand` = explicit bulky
  fallback, never default.
- Stages R1–R7, each ending with all examples byte-identical; R5 is the
  flag-day port of all examples + live.janet ordinal setters → name-keyed.
- USER REQUIREMENT 2026-08-15: R1–R7 must work with the live interactive
  machinery (C1 ArcSwap render thread, D1/D2 progressive + wireframe proxy).
  Pinned in doc §"Live mode": mutations produce one snapshot swap + generation
  bump (ladder unchanged); camera moves keep no-rebuild path; R2+ gate = 1
  rebuild/swap per upsert, 0 per camera move (rebuild-counter idiom).
- Open questions at doc end: flat vs per-kind name namespace, keep
  set-camera!/toggle-wireframe! as aliases, sweep scope for settings, group
  member addressing (deferred).
