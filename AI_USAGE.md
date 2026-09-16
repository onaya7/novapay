# AI Usage

Everything below happened while designing this app. The failure cases in §3 are real errors that reached a draft and were corrected, not illustrations written afterwards to fill the section.

## 1. Tools, and what each was used for

| Tool | Used for |
|---|---|
| **Claude Code (Opus 5)** | Primary working environment. Reading the brief, exploring the repo, designing the architecture, drafting both documents |
| **Separate review agents**, run in their own contexts | Adversarial review of the offline-queue design, and structured exploration of the existing scaffold. The separate context is the point: an agent that did not write the design attacks it instead of defending it |
| **Python scratch scripts** | Reproducing every numeric claim. No figure in the README was produced by a language model doing arithmetic from memory |
| **A UI/UX rule-set tool** | Accessibility, touch-target and interaction checklists, used as a review pass rather than as a source of visual design |
| **`cspell`, and the repo's own CI config** | Checking that the documents actually pass the build before they are pushed |

**Division of labor.** AI did the drafting, the exploration and the arithmetic checking. The judgment calls were mine: which reading of an ambiguous requirement to follow, whether pending spend should reduce the displayed balance, what to leave out of scope. Several were made *against* the first answer I got. §3 is the evidence.

## 2. Three prompts, and what came back

### Prompt 1 — attack my own offline-queue design

> "You are adversarially reviewing a Flutter offline-queue design for a fintech take-home. Be concise and hostile to the design. Do NOT be agreeable. Your job is to find where it breaks, not to praise it. […] **1.** The brief says 'idempotency key per attempt.' My design generates it per ENTRY and deliberately reuses it across retries. Is my reading defensible, or does it violate the brief? Argue both sides and give a verdict. **2.** Where can this design still double-send? Enumerate concrete interleavings […] **5.** […] **This is a trap — think hard about whether an optimistic balance is right for a fintech app.** […] **8.** Name the 3-4 tests that would actually catch a regression here, and any test I would likely write that gives false confidence."

**What came back:** twelve prioritized defects, three of which changed the design materially and are documented in §3. On the idempotency question it agreed per-entry is mechanically correct, then pointed out I had framed it as a binary when the brief is conflating two different fields — the strong answer ships a stable dedup key *and* a per-attempt trace id, which satisfies the literal wording and the intent at a cost of one field. That is now in the README and in the code design.

It also answered the balance question in a way I had not anticipated: the interesting part is not whether the deduction is optimistic but **when the hold is released**, which turns out to be the difference between correct and a double-spend through the UI.

### Prompt 2 — generate a design system for this product type

> `"fintech mobile wallet payments savings trust" --design-system`

**What came back:** a dark-only theme, gold `#F59E0B` with purple `#8B5CF6`, IBM Plex Sans, and a pre-delivery checklist containing `cursor-pointer`, hover states and 1440px breakpoints.

**Rejected**, for three independent reasons, any one of which is sufficient: the brand palette was already decided, so a recommendation contradicting it is noise; it proposed dark-only for a system that is light-first with a dark twin; and the checklist is web guidance for what is a Flutter mobile app, where `cursor-pointer` and hover do not exist. Its **rule layers** — touch targets, contrast, motion timing, semantics — were kept, because those are sound and platform-independent. Its palette and typography were discarded. Detail in §3, case 4.

### Prompt 3 — compute it, don't recall it

> "Show IEEE-754 double behavior for these money inputs (identical in Dart): for each, print `float(s) * 100`, `int(...)` and the correct value. Then show kobo → Naira split formatting with no float anywhere."

**What came back:** the table now in the README, and one result I did not expect, which is covered in §3, case 5. This prompt exists because the brief names "naive kobo→Naira math" as a known AI failure, and the honest way to avoid it is to run the arithmetic rather than assert it.

## 3. Where AI output was wrong or risky

### Case 1 — an offline queue that replays twice

This is the brief's own example of a dangerous AI answer, and it is exactly what I produced.

**What the AI produced (me, first pass):** the fake backend keeps a `Map<idempotencyKey, Response>` and returns the stored response on replay. I wrote that this "is what makes exactly-once demonstrable."

**Why it is wrong:** the map is in process memory, and the requirement's headline scenario is a queue replayed after an **app restart**. After a restart the in-process server has total amnesia. The resent key hits an empty map and the transfer is processed a second time. The entire reconcile-after-restart story rested on a deduplication table that does not survive the one event it exists to handle. The demo would either never restart, and prove nothing, or restart and double-send.

**How it was caught:** the adversarial review in Prompt 1, run in a context that had not written the design. Not by re-reading my own draft, which is the whole reason for running the critique somewhere else.

**Fix:** the fake backend gets its own persisted storage, documented as the server's disk rather than the client's, so client outbox and server ledger both survive a restart. The test changed too, and this is the part worth arguing in an interview: the restart test asserts **`callCount == 2` and `ledger.length == 1`**. The duplicate *was* sent and the server collapsed it. A restart test asserting a single call is testing the in-memory guard, not deduplication, and would pass on a build with no idempotency at all.

### Case 2 — one terminal `failed` state, with a Retry button

**What the AI produced:** five attempts, then `failed`, surfaced in the UI with a manual Retry. It reads like every retry queue anyone has written.

**Why it is wrong:** a transport failure is not evidence the server did not process the request. Attempts 1 and 2 fail to connect, genuinely not processed. Attempt 3 reaches the server, the server debits, and the response times out on a flaky cell. Attempts 4 and 5 fail to connect. The entry lands in `failed`, the user taps Retry, and **the money moves twice**. The design had correctly routed a process killed mid-flight to reconciliation, then routed a timeout — which has identical epistemic status — back to the retry pool.

**How it was caught:** Prompt 1, which asked the question I had not: *is a user-initiated retry from `failed` a new logical operation, or the same one?* Both answers are wrong in the other's case.

**Fix:** terminal states are split by **what is known**, not by how many attempts were spent. `rejected` means a definitive 4xx, so the transfer provably did not happen, the hold releases, and a user retry mints a new key. `unresolved` means at least one attempt ended ambiguously, so the hold stays indefinitely, the entry is never auto-resent, and a retry never mints a new key. A one-way `sawAmbiguousAttempt` flag drives it. The copy follows the distinction: "We couldn't confirm this transfer. Check your history before trying again," not "Failed — Retry."

### Case 3 — white text on the brand blue

**What the AI produced:** me, about to specify white balance text and white secondary labels on the brand blue `#1174ed`, because that is what the palette obviously suggests.

**Why it is risky:** measured, white on `#1174ed` is **4.43:1**, just below the 4.5:1 AA threshold. It is not a rounding error to wave through on a screen whose entire job is showing someone their money.

**How it was caught:** reading the measured contrast values before writing the theme, rather than trusting that a brand color is safe for text.

**Fix:** white on brand is legal only for large text — 24px, or 18.66px bold — which in practice means the balance figure and the primary CTA label and nothing else. Every smaller white-on-blue label uses `#0e5fc4` at 6.08:1. The same pass caught two more: secondary and tertiary text on the subtle surface in dark mode measure 4.47:1 and 3.25:1, so neither may sit there.

### Case 4 — a generated palette that contradicted the brand

**What the AI produced:** see Prompt 2 — a dark-only gold-and-purple theme with a web checklist.

**Why it is risky:** not because the palette is ugly, but because it is confidently specific. It arrives formatted as a finished design system, with hex values and a font pairing and a checklist, and the format invites adoption. Applied without challenge it would have produced an app that looks nothing like the product it belongs to, and a checklist item telling a Flutter engineer to verify `cursor-pointer` states.

**Fix:** kept the rule layers, discarded the visual recommendation. Recorded in the README as a decision rather than silently dropped, because "we ran the generator and rejected its output" is a more useful thing for a reviewer to know than the absence of any mention.

### Case 5 — the example that did not reproduce

Smaller, and the one I am most inclined to keep.

**What the AI produced:** me, about to write that `0.1 + 0.2 + 0.3` demonstrates floating-point drift in a running total. It is the canonical example, it is in every blog post about float math, and I was going to assert it.

**Why it is wrong:** run it, and it returns exactly `0.6`. The claim would have been false in a document whose entire argument is that money must not be computed in floats. Being wrong *there* would have been worse than not making the point at all.

**How it was caught:** Prompt 3 — computing it rather than recalling it.

**Fix:** cut. The README uses the cases that do reproduce: `(double.parse('0.29') * 100).toInt()` is `28`, not `29`, and `1.15`, `8.87` and `19.99` fail the same way. Four of seven sampled values lose a kobo, which is a stronger argument anyway because those are ordinary amounts rather than a textbook example.

### A sixth, smaller one: assuming the stack

Before reading the repo I had started reasoning about which state-management library to recommend, and was weighing a Riverpod argument. The repo had already decided: `bloc`, `flutter_bloc`, `bloc_test` and `bloc_lint` are in `pubspec.yaml`, and CI runs `run_bloc_lint: true`, so the choice is enforced by the build. The same pass found that the coverage gate defaults to 100%.

Caught by reading `pubspec.yaml` and the workflow file instead of proposing from habit. It is a small thing, but "recommend a state-management library" and "notice the project already enforces one" are different jobs, and only one of them is useful here.

## 4. What AI was not used for

The decisions. Every review agent in this project was pointed at attacking a position I had already taken; none was asked "what should I build?" Where the agents disagreed with me, I changed the design rather than the goal, because the corrections were about **how the guarantee is achieved**, not about what the guarantee should be.

Two places where I went against the first answer I received: the review suggested dropping the terminal retry cap entirely, and I kept a cap on the *UI* affordance while removing it from the queue, because a user needs a way to act on a stuck transfer even when the queue should keep trying. And it proposed per-type queues to avoid head-of-line blocking, which I rejected — that breaks funds ordering between a transfer and a contribution drawing on the same balance. Draining the oldest *runnable* entry solves the blocking without giving up the ordering.
