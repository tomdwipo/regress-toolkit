# do implementation Command

read all lines from .docs/year(YYYY)/month(MM)/day(DD)/{number-in-DD-folder(01)}-$ARGUMENTS/$ARGUMENTS-spec.md 
and
.docs/year(YYYY)/month(MM)/day(DD)/{number-in-DD-folder(01)}-$ARGUMENTS/$ARGUMENTS-implementation-plan.md first for context.
do a detailed step-by-step implementation new feature from document .docs/year(YYYY)/month(MM)/day(DD)/{number-in-DD-folder(01)}-$ARGUMENTS/$ARGUMENTS-spec.md
and must follow the implementation plan at .docs/year(YYYY)/month(MM)/day(DD)/{number-in-DD-folder(01)}-$ARGUMENTS/$ARGUMENTS-implementation-plan.md. 
you have to be on that track in the implementation phase. 
Ensure all steps are completed before proceeding to the next feature.
add the necessary unit tests for each step or follow the testing considerations in the implementation plan.
don't add any comments in real code except TODO comments.
update or create the Acceptance Criteria (AC) if it doesn't exist at .docs/year(YYYY)/month(MM)/day(DD)/{number-in-DD-folder(01)}-$ARGUMENTS/ to reflect the new feature's success metrics.
run ./gradlew build for specific feature related the code changes after all done implementation the code before update Acceptance Criteria (AC).
think hard and provide a comprehensive implementation plan with before/after code examples for each step.
dont create other file except update or create Acceptance Criteria (AC) file AND the Roborazzi baselines + `.figma.png` reference siblings under `.docs/screen/{module}/` (see §Roborazzi Verification).
max 5000 characters for Acceptance Criteria (AC) file if the result exceeds 5000 characters, just it is.

## Roborazzi Verification (mandatory when plan has a Visual Intent Map)

If the implementation-plan.md contains a `Visual Intent Map`, you MUST run this verification BEFORE marking the AC complete. The plan is the intent ledger — judge pixel diffs against it yourself, do NOT ask the user mid-run.

### Per-row execution

For each row in the Visual Intent Map:

```
action == VERIFY-ONLY:
    ./gradlew :{module}:verifyRoborazziDebug --tests "*{Screen}ScreenshotTest.{state}"
    diff ≤ 0.1% px  → PASS, continue
    diff > 0.1% px  → REGRESSION
                      → fix the offending code (revert the unintended change)
                      → re-run verify
                      → max 3 fix attempts; if still failing, STOP and write
                        "❌ {Screen}/{state}: regression — {observed delta},
                         3 fix attempts exhausted" into the AC and halt.
                      NEVER re-record a VERIFY-ONLY row.

action == RE-RECORD:
    # --- Asset auto-import + bounded retry loop (MAX 3 PASSES) ---
    # Imports happen INSIDE `/do-implementation` per RE-RECORD row.
    # Each pass: (a) stage declared/auto-detected assets, (b) record
    # Roborazzi, (c) fetch Figma sibling, (d) heuristic diff check,
    # (e) decide whether to retry. Hard cap at 3 passes.
    for pass in 1..3:
        # (a) Stage assets
        if pass == 1:
            import every entry in the row's "Asset Manifest"
            (format=svg → {module}/figma-svg/{name}.svg,
             format=png → {module}/src/main/res/drawable-{density}/{name}.png).
            Skip any entry where the target file already exists and is
            non-empty (idempotency — supports re-runs after plan edits).
        else:
            # Auto-detect candidates from the Figma subtree.
            call `mcp__figma__get_file_nodes(
                key="{fileKey}", ids=["{nodeId}"], depth=10
            )` to walk the parent node's children.
            Filter for child nodes of type VECTOR / RECTANGLE-with-image-fill /
            INSTANCE-with-icon-component whose snake_case name does NOT
            match any existing drawable in `{module}/src/main/res/drawable*/`
            (or any other module's drawables).
            Rank candidates by rendered area (largest first); pick top 5.
            Import each via `mcp__figma__get_image_render(
                key="{fileKey}", ids=["{candidateId}"],
                format="png", scale=4
            )` to `{module}/src/main/res/drawable-xxxhdpi/{name}.png`.
            Record each auto-detected import in the AC.

        # (b) Record Roborazzi
        ./gradlew :{module}:recordRoborazziDebug --tests "*{Screen}ScreenshotTest.{state}"
        copy produced PNG → .docs/screen/{module}/{ScreenName}_{state}.png

        # (c) Fetch Figma sibling
        attempt `.docs/screen/{module}/{ScreenName}_{state}.figma.png` via
        `mcp__figma__get_image_render(key, ids=[nodeId], format="png", scale=1)`
        — same non-blocking semantics as before (record `⚠️` on failure).
        Note: the URL is short-lived (Figma signs it for ~30 minutes) —
        download AND commit the PNG; do NOT just store the URL.

        # (d) Heuristic diff (retry SIGNAL only, NOT the verdict)
        if `.figma.png` is staged:
            compute a normalised mean-absolute-pixel-difference between
            the Roborazzi PNG and the Figma PNG (resize both to the smaller
            of the two dimensions first; treat as grayscale; divide by 255).
            Call this `diff_pct`. THIS IS NOT THE VERDICT — Figma vs
            Roborazzi is reviewer-eyeballed (font hinting / sub-pixel AA /
            density rounding always produce some diff). `diff_pct` only
            decides whether the retry loop continues.
        else:
            skip the diff step; cannot retry without a reference image →
            break the loop after this pass.

        # (e) Decide
        if diff_pct ≤ 0.25 (25%) OR pass == 3:
            break
        # else: there is significant divergence AND we have retries left
        # → loop to next pass for auto-detect import.

    # --- After loop: record outcome ---
    Compare against the row's "Intended delta" text:
        - delta visible AND matches description → PASS the row.
        - delta visible BUT differs from description → REGRESSION
            → fix code OR (if description is wrong) STOP and flag in AC.
        - no visible delta vs prior baseline → SUSPECT
            → either the code change didn't land, or the test setup
              isn't exercising the changed path. Fix and re-record.

    # --- AC bookkeeping (every RE-RECORD row) ---
    Append to `### Asset Imports` in AC, one entry per asset processed:
        "✅ {drawable} → {target path} (pass {N}, {declared|auto-detected})"
        "↪️ convert {drawable}.svg → VectorDrawable via AS Vector Asset Studio"
          (only for `format=svg` entries; tells the dev to finish the asset)
        "(skipped — already staged)" for idempotent re-runs

    If the final `diff_pct` > 0.25 after pass 3, OR `.figma.png` could not
    be staged at all, append to `### Figma Reference Notes`:
        "⚠️ {Screen}/{state}: post-import gap remains (final diff_pct = X%,
         3 passes exhausted). Likely cause: {compose-side wiring not
         updated to reference imported drawable | Figma node has elements
         not yet expressible in Compose | reviewer eyeball needed}.
         Reviewer eyeballs Roborazzi PNG against design in Figma
         (link: https://www.figma.com/design/{fileKey}/...?node-id={nodeId})."

    Failure reasons for `.figma.png` not staged (same as before):
        - "MCP fetch failed: 401/403 auth — token missing or expired"
        - "MCP fetch failed: 404 — node id `{nodeId}` not in file `{fileKey}`"
        - "MCP fetch failed: network/server offline"
        - "MANUAL flagged in plan but `.figma.png` not staged"
        - "no Figma node in plan and no `.figma.png` staged"

    The row's PASS does NOT depend on Figma fidelity or final `diff_pct` —
    those are reviewer concerns recorded in AC + PR for visibility.
    Re-running `/do-implementation` after editing the plan (e.g. adding
    missing Asset Manifest entries or fixing Compose references) is
    idempotent and acts as re-verification — the bot will skip already-
    staged assets and re-record / re-diff the affected rows.
```

Threshold = `changeThreshold = 0.001f` (0.1%) on `RoborazziOptions.CompareOptions`. This absorbs anti-aliasing noise without hiding real layout changes.

### Self-verdict, no asking

You decide PASS / REGRESSION / SUSPECT yourself per row. The user is not the verifier mid-run — they are the reviewer of the PR. Confidence comes from:

1. The **Visual Intent Map** declares scope. A screen not listed = regression on first non-zero diff.
2. The **changeThreshold** is deterministic.
3. RE-RECORD descriptions are specific enough that you can read the diff image and confirm match.

If you cannot confidently decide, default to REGRESSION and fix code. Do NOT escalate ambiguous diffs to the user.

### Baseline placement & commit

```
src/test/snapshots/.../{ScreenName}_{state}.png        (Roborazzi default output)
                              │ copy curated set
                              ▼
.docs/screen/{module}/{ScreenName}_{state}.png         (Roborazzi baseline)
.docs/screen/{module}/{ScreenName}_{state}.figma.png   (Figma export — RE-RECORD only, manual)
                                                       │ both committed; reviewer eyeballs side-by-side
                                                       │ (Figma export ≠ Roborazzi pixel-for-pixel — that is OK)
```

Stage the `.docs/screen/{module}/` PNGs in the same commit as the code. They ship in the same PR — the reviewer sees them in the diff. Do NOT commit the raw `src/test/snapshots/` output.

### AC visual-parity block (append to existing AC)

After all rows are PASS, append this block to the AC file (counts toward the 5000-char cap; trim other AC text if needed):

```
### Visual Parity (Roborazzi)
Plugin/deps verified in {module}/build.gradle.kts: yes
Threshold: 0.1% px diff

| Screen / state                        | Action      | Verdict | Note                                    |
|---------------------------------------|-------------|---------|-----------------------------------------|
| InfoConnectedDeviceScreen / default   | RE-RECORD   | PASS    | browser icon swap matches plan          |
| InfoConnectedDeviceScreen / loading   | VERIFY-ONLY | PASS    | 0% diff                                 |
| LoginScreen / default                 | VERIFY-ONLY | PASS    | 0% diff (regression guard)              |

Baselines + `.figma.png` reference siblings (RE-RECORD rows) staged at .docs/screen/{module}/ — included in this commit.
```

### Build gate

The AC is NOT complete until BOTH are true:

- `./gradlew :{module}:build` is green
- Every Visual Intent Map row resolves to PASS and the corresponding `.docs/screen/{module}/{ScreenName}_{state}.png` is staged for commit. Missing `.figma.png` siblings do NOT block the gate — instead they appear as `⚠️` lines in §"Figma Reference Notes" of the AC and must be surfaced in the PR description (see §"PR description hook").

### PR description hook

If §"Figma Reference Notes" of the AC contains any `⚠️` lines after the build gate passes, `/push-pr` MUST surface them in the PR description under a `## Missing Figma References` heading. Reviewers should see the warnings at PR open time, not only after diff-diving the AC file. Each line carries the screen, state, reason, and Figma URL (if known) so the reviewer can open Figma directly and judge design fidelity by eye.

If a row halts at REGRESSION after 3 fix attempts, the AC records the failure and you stop — do not paper over it.

### Learning loop (post-PR)

If the PR reviewer overrides one of your verdicts (e.g. "that opacity drift you flagged as regression was intended"), capture the rule once and never re-litigate:

1. Save a `feedback_*.md` memory entry: the rule, **Why:** (reviewer's reasoning), **How to apply:** (when this kicks in at verify time).
2. If the rule generalises across screens/modules, add a chapter under `.docs/common-issues/` per the Unified Save Protocol.

Do not save a learning when you were simply wrong on this one screen — that's a one-off, not a rule.

## Avoid Repeating Mistakes

Before starting implementation, read the **Common Issues** section in CLAUDE.md for known gotchas.

If you encounter a new mistake during implementation, add it to CLAUDE.md Common Issues section with:
- What went wrong
- How it was fixed

Keep it short. This helps future sessions not repeat the same mistake.
