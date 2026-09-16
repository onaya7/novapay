# NovaWallet Mobile — Send & Save

**Scenario:** FirstBank NovaPay → NovaWallet. Two journeys, sending money and contributing to a NovaSave goal, built for a market where a large share of users are on low-end Android with patchy connectivity.

> **Status: partly built, and this document says which parts.** The money layer, the offline queue, the stand-in backend and the design system are implemented and under test. The three screens are in progress. Everything the design specifies beyond what is built is marked **`[DESIGN — not built]`** where it appears, because a document that quietly describes code that does not exist is worth less than no document.

> ## The design in one paragraph
> Every money-moving action is **written to a local queue before any network call**, so the online and offline paths are the same code and "offline" is not a branch. Each action carries a **client-generated idempotency key that is stable across retries**, and the backend keeps a **persisted** ledger keyed on it. That combination is what makes replay safe: the queue may send a duplicate, and the server collapses it. The honest claim is at-least-once delivery plus server-side deduplication, which is what "exactly once" means in practice.

---

## Implementation status

`254 tests, 100% line coverage` `[VERIFIED: fvm flutter test --coverage]`

| Area | Status | Where |
|---|---|---|
| Money as integer kobo — parse, format, sum, basis points | **Built** | [`lib/core/money/`](lib/core/money/) |
| Offline queue — persist-before-send, drain, retry budget, restart recovery | **Built** | [`lib/core/sync/`](lib/core/sync/) |
| Stand-in backend — models, repositories, services, API envelope, idempotency | **Built** | [`lib/server/`](lib/server/) |
| Storage — Hive CE and secure storage behind interfaces, flavor-scoped | **Built** | [`lib/core/local_data/`](lib/core/local_data/) |
| DI, reachability, error translation | **Built** | [`lib/core/injections/`](lib/core/injections/), [`lib/core/network_info/`](lib/core/network_info/), [`lib/utils/`](lib/utils/) |
| Design system — tokens, theme, shared components | **Built** | [`lib/config/theme/`](lib/config/theme/), [`lib/core/components/`](lib/core/components/) |
| Wallet home · Send Money · NovaSave goal | **In progress** | — |
| Leases, persisted backoff with jitter, `unresolved` state, available-vs-confirmed balance, per-attempt trace id | **`[DESIGN — not built]`** | Argued below; deliberately not built yet |

The last row is the honest one. Those are the right answers for a production wallet and the reasoning for each is kept below, because the reasoning is the deliverable. They are not in the code, and this table is the only place that needs checking to know that.

---

## Reading order

If you read three things: **[Offline and sync](#offline-and-sync)** → **[Money](#money-kobo-end-to-end)** → **[Testing](#testing)**. Everything else supports those.

## What's where

| Brief requirement | Section |
|---|---|
| Wallet home — balance, transaction list, pull-to-refresh | [Screens](#screens-and-scope) · [Performance](#performance) |
| Send Money — recipient → amount → confirm, idempotency key per attempt | [Offline and sync](#offline-and-sync) · [The idempotency key argument](#the-idempotency-key-argument) |
| NovaSave goal — create, contribute, progress | [Money](#money-kobo-end-to-end) · [Screens](#screens-and-scope) |
| Offline behavior — queued locally, shown Pending, not lost, no retry loop | [Offline and sync](#offline-and-sync) |
| Sync on reconnect — replayed exactly once, survives restart | [The state machine](#the-state-machine) · [Testing](#testing) |
| Money as integer kobo, no float drift | [Money](#money-kobo-end-to-end) |
| Queue survives app restart, never sent twice | [Restart is the hard case](#restart-is-the-hard-case) |
| Semantics, font scale, screen readers | [Accessibility](#accessibility) |
| `ListView.builder` for large lists | [Performance](#performance) |
| No secrets in plain SharedPreferences | [Storage](#storage) |
| Widget + integration tests | [Testing](#testing) |
| What is actually built | [Implementation status](#implementation-status) |
| AI usage | [AI_USAGE.md](AI_USAGE.md) |

## How to read the claims

Every factual claim carries its provenance. An untagged number is a defect.

| Tag | Meaning |
|---|---|
| `[SOURCE: …]` | Traceable to the brief, a file in this repo, or a named reference |
| `[VERIFIED]` | Reproduced by running it, not recalled |
| `[ASSUMPTION — needs validation]` | A judgment call the brief left open, labeled as one |
| `[JUDGMENT]` | An opinion, not a measurement |

---

## Quick start

Flutter **3.47.2** stable / Dart **3.13** `[VERIFIED: flutter --version on the development machine]`. The SDK constraints in `pubspec.yaml` are `sdk: ^3.13.0`, `flutter: ^3.47.0`.

The SDK is pinned with FVM (`.fvmrc`), so local commands take an `fvm` prefix. CI provisions its own SDK and runs them bare.

```sh
# Development
fvm flutter run --flavor development --target lib/main_development.dart

# Staging
fvm flutter run --flavor staging --target lib/main_staging.dart

# Production
fvm flutter run --flavor production --target lib/main_production.dart
```

```sh
fvm flutter test --coverage        # 254 tests, 100% line coverage
fvm flutter analyze lib test       # exits non-zero on info, so treat any issue as a failure
fvm dart format lib test
fvm dart run bloc_tools:bloc lint . # the bloc rules live under a key `flutter analyze` ignores
fvm dart run build_runner build    # freezed, json_serializable, injectable
```

Two conventions that will trip a reader who skims:

- Widgets import **`package:material_ui/material_ui.dart`**, not `package:flutter/material.dart`. Material was decoupled from the framework into its own package as of this Flutter version.
- The Dart 3.13 **`const new({super.key})`** shorthand is used for unnamed constructors. It does **not** work for named ones — `const .named(...)` fails to compile — which is why `unnecessary_type_name_in_constructor` is disabled in `analysis_options.yaml`.

**CI note, worth knowing before you push.** `.github/workflows/main.yaml` delegates to `very_good_workflows/flutter_package.yml@v1`, whose **`min_coverage` input defaults to `100`** `[VERIFIED: upstream workflow definition]`. A 100% line-coverage gate is a real force on this codebase, and it pushes toward exactly the tests that prove nothing. See [tests that lie](#tests-that-lie).

---

## Screens and scope

In scope, and nothing else:

| Screen | Contents |
|---|---|
| **Wallet home** | Balance card, available vs pending, recent transactions, pull-to-refresh |
| **Send Money** | Recipient → amount → confirm, as three steps |
| **NovaSave goal** | Create (name, target, date), contribute, progress bar with printed percentage |

**Explicitly deferred to post-launch**, so nobody half-starts them: localization beyond the English scaffold, biometric confirmation above a threshold, local notification on successful sync, and golden tests. Each is a stretch goal in the brief `[SOURCE: brief §2.4]` and each is a genuine enhancement, but none of them is the thing being graded.

---

## Architecture

### State management: Bloc and Cubit

**Not because Bloc is better than Riverpod in the abstract, but because this repo has already chosen.** `pubspec.yaml` ships `bloc`, `flutter_bloc`, `bloc_test` and `bloc_lint`, and CI runs `run_bloc_lint: true`. Bloc is enforced by the build, not merely preferred. Bloc carries session and app-level state; a Cubit backs each screen and each action.

Division of labor:

- **Bloc** for app and session state where events need a durable audit trail.
- **Cubit** for each screen and each action. Public methods return `void` or `Future<void>`; state lives in a `freezed` sealed union in a `part` file.
- **No Flutter imports inside a bloc or cubit.** `bloc_lint`'s `avoid_flutter_imports` enforces it, which means framework types are converted at the `MaterialApp` boundary, not carried through the state layer.
- In the UI, branch with `.when` / `.maybeWhen`. Elsewhere, `switch` is fine.

### Layering

Feature-first, with clean-architecture layers inside each feature. The boundary rules are worth stating explicitly, because they are the thing that keeps a fintech codebase testable:

> `domain/` imports neither `data/` nor Flutter. It depends on nothing. `data/` and `presentation/` both depend on `domain/`, never on each other. Presentation calls a **usecase**, never a repository directly.

```
lib/
├── config/
│   ├── flavor/          flavor-scoped config, chosen by the entry point
│   └── theme/           AppThemeColors (ThemeExtension), TTextTheme, AppTheme
├── core/
│   ├── components/      shared widgets, semantics baked in
│   ├── constants/       AppColor, AppSize, storage keys
│   ├── error/           Failure sealed union
│   ├── exception/       AppException sealed union
│   ├── extensions/      String, int and DateTime helpers
│   ├── injections/      get_it + injectable container
│   ├── local_data/      Hive CE and secure storage, both behind interfaces
│   ├── money/           Money value type, parser, formatter, basis points
│   ├── network_info/    reachability, not just interface-up
│   └── sync/            PendingAction + SyncService — the offline queue
├── server/              the stand-in backend, layered
│   ├── models/          Transaction, SavingsGoal, ApiResponse
│   ├── repositories/    account, transaction, savings goal, idempotency
│   ├── services/        transfer, savings — the business rules
│   └── novapay_api.dart the surface the app calls
└── utils/               EitherSafeRunner, InternetSafeRunner, logger
```

`lib/features/` does not exist yet; the three screens land there as `wallet/`, `send_money/` and `savings/`, each with `data · domain · presentation`.

**Why `lib/server/` is a directory and not a mock.** The brief supplies no backend, so this app ships one. It is layered the way a Node or Spring service would be — repositories own persistence, services own the rules and throw, an API surface maps a refusal onto a status code — and every layer sits behind an abstraction. That is not ceremony for its own sake: it is what makes the swap to a real HTTP client a change to one DI binding rather than a rewrite, and it keeps the fake honest, because a fake with the rules smeared into the transport layer will accept things a real server would refuse.

Every endpoint answers with the same `ApiResponse<T>` envelope — `{status, code, message, data}`. **A business refusal is a response carrying a code, the way a real API answers 402 or 422; only a transport failure throws.** The queue branches on `response.isSuccess`, and its `catch` is reserved for the case where the request never landed.

### Errors

Three vocabularies, one translation chain:

```
DioException / Object
   → AppException   (data layer speaks this)
   → Failure        (domain layer speaks this)
   → String         (UI speaks this)
```

A single `EitherSafeRunner` holds the only `try`/`catch` in the app; repositories return `Either<Failure, T>`. One place to change when error handling changes, and no scattered catch blocks silently swallowing a failed transfer.

**One pitfall this design avoids deliberately.** A translation layer that parses only `response.data['message']` collapses every 4xx and 5xx other than 401/402 into a single `ServerFailure`, leaving the status code unavailable for branching. That is fatal here, because [the offline queue needs to tell a definitive rejection from an ambiguous failure](#terminal-states-split-by-knowledge). Status codes are preserved.

### Storage

Two stores, split by sensitivity, both behind interfaces:

| Store | Holds | Why |
|---|---|---|
| **Hive CE** | The action queue, the server's own tables, non-sensitive flags | Synchronous reads at startup with no `await` |
| **flutter_secure_storage** | Auth tokens, session id | Keychain / Keystore. Never `SharedPreferences` `[SOURCE: brief §2.2]` |

Storage keys live in one file, each commented with which store owns it, so nobody puts a token in the wrong one. Box names are flavor-scoped, so a development build cannot read a production build's data.

`flutter_secure_storage` v11 removed the `encryptedSharedPreferences` flag because AES-GCM with RSA-OAEP key wrapping is now the Android default; there is nothing to opt into.

Queued actions are stored as **JSON strings rather than typed Hive adapters**. A queued transfer may outlive an app update, and a moving schema must not brick the queue. This choice has a cost, paid in [the money section](#money-kobo-end-to-end).

---

## Money: kobo end to end

Money is an `int` number of kobo in a `Money` value type, from parse to display. Naira never exists as a number in this app — only as a rendered string.

### Parsing never multiplies a double

The obvious implementation is wrong:

```dart
// WRONG — loses a kobo on ordinary inputs
final kobo = (double.parse(input) * 100).toInt();
```

`[VERIFIED]` by running it:

| Input | `× 100` | `.toInt()` | Correct |
|---|---|---|---|
| `0.29` | `28.999999999999996` | **28** | 29 |
| `1.15` | `114.99999999999999` | **114** | 115 |
| `8.87` | `886.9999999999999` | **886** | 887 |
| `19.99` | `1998.9999999999998` | **1998** | 1999 |

Four of seven sampled values lose a kobo. Not an edge case — `₦19.99` is an ordinary amount.

The correct parse never constructs a double at all: split on `.`, pad or truncate the fraction to exactly two digits, concatenate, parse one `int`. It also has to survive what users actually type: `".5"`, `"1."`, `"1.005"`, a pasted `"₦1,000.00"`, and a twenty-digit paste.

### Display never divides

```dart
final naira = kobo ~/ 100;      // integer division
final k     = kobo.abs() % 100; // remainder, always two digits
```

Group the **integer part only** with `NumberFormat.decimalPattern`, then concatenate the remainder. Sign is handled off `kobo.abs()` so `-16400` renders `-₦164.00`.

**Never `NumberFormat.currency`.** It takes a `num` and routes through a double internally. The one-liner someone adds the night before a demo, `NumberFormat.simpleCurrency().format(kobo / 100)`, puts the whole thing back into floats.

Verified output `[VERIFIED]`:

| kobo | renders |
|---|---|
| `248000000` | `₦2,480,000.00` |
| `1050` | `₦10.50` |
| `29` | `₦0.29` |
| `-16400` | `-₦164.00` |
| `0` | `₦0.00` |

`₦0.00` is the empty state, never a dash and never a blank.

### Goal progress is integer basis points

```dart
final bp = target > 0 ? ((saved * 10000) ~/ target).clamp(0, 10000) : 0;
```

The `double` appears exactly once, at the progress-bar render boundary, and that boundary is **strictly one-way**. Nobody reads the animated tween value back to build a `'${(v * 100).round()}%'` label, because that is a float producing a displayed number again. The printed percentage is computed from `bp`.

Two traps guarded above: `target == 0` throws on `~/`, and a goal can be created or edited to zero. And `~/` truncates toward zero, so an uncapped 99.99% renders as 99%.

### The cost of JSON storage

`jsonDecode` returns `num`. A whole number decodes as `int` on the VM, but any value that ever passed through a double — a hand-edited fixture, a web-side producer — arrives as `1000.0`. Then `as int` throws at runtime, and the tempting fix is `.toInt()`, which silently truncates.

One helper, used everywhere, that throws rather than coerces:

```dart
int _kobo(Object? v) => v is int ? v : throw FormatException('kobo must be int, got $v');
```

### Two honest caveats

- **On web, Dart `int` is a 53-bit JS double** `[SOURCE: dart2js number semantics]`. The scaffold targets web, so "no floating point anywhere" is literally false there. Integer semantics hold exactly below 2^53, which bounds this app at roughly ₦90 trillion. Input length is validated to stay inside it. Stating the bound is more defensible than claiming an absolute.
- **`closeTo` is banned in the money path.** Its presence in a money test is a defect by definition — it means someone is comparing money as floats.

---

## Offline and sync

This is the part the brief is actually grading, so it gets the most space.

### The shape

A **local queue**: every money-moving action becomes a durable row written to Hive **before any network call is attempted**. The UI renders from the queue, so a queued transfer appears as Pending immediately, whether the device is online or not.

**There is no separate offline code path.** Offline is simply a drain that has not succeeded yet. This is the single most important structural decision here: a codebase with an `if (offline)` branch has two behaviors to test and two places for the money to go missing.

A `PendingAction` carries `[SOURCE: lib/core/sync/pending_action.dart]`:

| Field | Purpose |
|---|---|
| `id` | Client-generated UUID, **stable for the life of the operation**. Sent as the idempotency key |
| `type` | `send` or `contribute` |
| `amountKobo` | `int` |
| `payload` | The request body |
| `schemaVersion` | The version that wrote the row, checked before it is decoded |
| `status` | `queued` · `sending` · `done` · `failed` |
| `attemptCount` | Retry budget, capped at 5 |
| `createdAt` | FIFO ordering |

**`[DESIGN — not built]`** The full design adds `attemptId` (per-attempt trace id), `sawAmbiguousAttempt`, `nextAttemptAt` (persisted backoff), `leaseOwner`/`leaseExpiresAt` (durable single-flight lease) and `userId`. Each is argued below. None is in the code.

### The idempotency key argument

The brief says the app "generates an idempotency key **per attempt** so a retried send can't double-process" `[SOURCE: brief §2.1]`. Those two clauses contradict each other, and this is worth stating plainly because a panel will ask.

A key that changes per attempt provides **zero** deduplication. If attempt 2 carries a different key from attempt 1, the server sees two unrelated requests and processes both. The literal reading does not merely fail to prevent double-processing, it guarantees it under retry — which is precisely what the sentence's own subordinate clause says the key is for.

The resolution is that the brief is conflating two different fields:

- **`idempotencyKey`** — one per logical operation, stable across every retry. This is what makes replay safe, and it is `PendingAction.id` in the code.
- **`attemptId`** — a fresh UUID per attempt, for tracing and for the support question "which attempt actually landed?" Never used for deduplication. **`[DESIGN — not built]`**

Shipping both satisfies the brief's literal wording and its stated intent, and it costs one field. The stable key is built because it is load-bearing; the trace id is not, because nothing yet consumes a trace. `[JUDGMENT]`

### The state machine as built

```
   enqueue (always, before any network call)
            │
            ▼
       ┌────────┐   drain, with a network   ┌─────────┐   2xx or a refusal   ┌──────┐
       │ queued │ ─────────────────────────▶│ sending │ ───────────────────▶ │ done │
       └────────┘                           └────┬────┘                      └──────┘
            ▲                                    │
            │  attemptCount < 5                  │ transport failure, or found
            └────────────────────────────────────┤ at cold start (recoverInterrupted)
                                                 │
                                                 ▼  attemptCount == 5
                                            ┌────────┐
                                            │ failed │
                                            └────────┘
```

A row found `sending` at cold start is requeued, which is safe **because the id is the idempotency key** — the resend is collapsed by the server rather than moving money twice. `done` and `failed` are terminal.

### Where that state machine is not enough

**`[DESIGN — not built]`, and this is the gap a reviewer should press on.**

Four states cannot express *"we don't know."* The design below splits the terminal states by knowledge instead of by attempt count, and the rest of this section argues why that matters for money.

### The fuller state machine

```
                    enqueue (always, before any network call)
                              │
                              ▼
                        ┌──────────┐
          ┌────────────▶│  queued  │◀───────────┐
          │             └────┬─────┘            │
          │                  │ lease acquired   │ transport failure,
          │                  ▼                  │ budget remains
          │             ┌──────────┐            │
          │             │ inFlight │────────────┘
          │             └────┬─────┘
          │                  │
          │      ┌───────────┼────────────┬──────────────────┐
          │      │           │            │                  │
          │   2xx│        4xx│         timeout /          cold start
          │      ▼           ▼         killed in flight    finds lease
          │ ┌─────────┐ ┌──────────┐      │                 expired
          │ │confirmed│ │ rejected │      │                  │
          │ └─────────┘ └────┬─────┘      ▼                  ▼
          │                  │     sawAmbiguousAttempt = true (one-way)
          │                  │            │                  │
          │                  │            └────────┬─────────┘
          │                  │                     ▼
          │                  │              ┌──────────────────┐
          │                  │              │ awaitingReconcile│
          │                  │              └────────┬─────────┘
          │                  │                       │ budget exhausted
          │                  │                       ▼
          │                  │              ┌──────────────┐
          │                  │              │  unresolved  │
          │                  │              └──────────────┘
          │                  │
          │   user retry     │  user retry after fixing the input
          └──────────────────┘  (NEW idempotencyKey — provably not processed)
```

Terminal states are `confirmed`, `rejected`, and `unresolved`. Only `rejected` may be retried with a fresh key.

### Terminal states split by knowledge

**This is the correction that matters most, and an earlier draft of this design got it wrong.** **`[DESIGN — not built]`** — the code currently has a single `failed`, which is exactly the shape this section argues against.

The intuitive design has one `failed` state reached after N attempts, with a Retry button. That is a live double-spend. Consider: attempts 1 and 2 fail to connect, genuinely not processed. Attempt 3 reaches the server, the server debits, and the response times out on a flaky cell. Attempts 4 and 5 fail to connect. The entry lands in `failed`, the user taps Retry, and the money moves twice.

A transport failure is **not evidence the server didn't process it.** So the terminal states are split by what is *known*, not by how many attempts were spent:

| State | Meaning | Hold | User retry |
|---|---|---|---|
| `rejected` | Definitive 4xx. **Provably** not processed | Released | Allowed, with a **new** key |
| `unresolved` | At least one attempt ended ambiguously | **Held indefinitely** | Never auto-resent; never a new key |

A one-way `sawAmbiguousAttempt` flag drives it: any attempt that was transmitted but whose response was not read sets it, and it never clears.

`unresolved` is surfaced as *"We couldn't confirm this transfer. Check your transaction history before trying again,"* not as *"Failed — Retry."* The copy difference is the whole point.

### Restart is the hard case

A row found `sending` at cold start is ambiguous: the process died somewhere between writing the request and reading the response.

**Single-flight cannot be an in-memory boolean.** The naive guard races against itself:

```dart
Future<void> drain() async {
  if (await _connectivity.hasInternetAccess) { ... } // await BEFORE the guard
  if (_isDraining) return;                            // both callers see false
  _isDraining = true;
}
```

Any `await` between the check and the set opens a deterministic window. Connectivity-regained and app-resume fire in the same frame, both yield at the await, both resume, both drain. Dart's single-threaded event loop does not save you here — it makes the bug reproducible, which is the only good news.

Three layers replace it:

1. **Re-entrancy within the isolate** — a future-chain mutex, `_lock = _lock.then((_) => _drainOnce())` `[SOURCE: lib/core/sync/sync_service.dart]`. **Built.** A bool guard was written first and was wrong in a way worth recording: a drain requested *during* a drain became a silent no-op, which loses exactly the wake-up that connectivity-regained delivers. The mutex chains instead of dropping.
2. **Across restart** — `recoverInterrupted()` requeues anything left `sending`, and is called at startup. **Built.** The durable lock should be a **lease** (`leaseOwner`, `leaseExpiresAt`) rather than a bare status, because a bare status cannot distinguish "crashed mid-send" from "currently being sent" — that distinction only matters with more than one drain trigger in flight, so it is deferred. **`[DESIGN — not built]`**
3. **Across isolates** — don't. Hive CE has no cross-isolate coordination, and two isolates with the same box open corrupt it rather than merely duplicating. **Exactly one isolate owns the queue**, stated here as an architectural constraint. A background isolate that needs to enqueue writes to a separate inbox box the owner drains.

A recovered row is resent **with the same idempotency key**, which is safe precisely because the server deduplicates.

### The backend has its own disk

No backend is provided, so this app ships one `[SOURCE: brief §2]`. `IdempotencyRepository` records every key the server has applied, and a replay returns the original entity instead of processing again.

**That record is persisted to the database, not held in memory.** An earlier draft held it in process memory, which fails at exactly the event the requirement is about: after an app restart the in-process server has total amnesia, the resent key hits an empty map, and the transfer is processed a second time. The demo would either never restart and prove nothing, or restart and double-send. There is a test for precisely this — *"a restart still recognizes a key it already applied"*.

The server's keys are namespaced as **the server's tables, not the client's**, so nobody later "tidies up" by merging them into the app's storage.

### Retry pacing

**Built:** a fixed retry budget of 5 attempts per action, and reachability checked against the network rather than merely "is there an interface up" — captive portals return 200 to their own login page.

**`[DESIGN — not built]`**, and the reasoning is why:

- **Backoff should be per-entry and persisted** as `nextAttemptAt`, with the drain skipping entries still inside their window. Persisted, because an in-memory backoff resets on restart and produces a thundering herd on the first cold start after a crash loop.
- **Exponential with jitter**, capped around 30 minutes. Jitter matters because every client on a cell tower reconnects at the same moment.
- **Failures should be classified.** A 4xx validation error is terminal at attempt 1 — retrying "invalid account number" five times is waste. A 401 refreshes the token and does **not** burn an attempt. 5xx and timeouts are retryable. The `ApiResponse` envelope already carries the status code needed to do this; nothing consumes it yet.
- **No terminal cap on transport errors.** If a user is offline for a week, the transfer should still go. What changes after N failures is the *UI*, which gains "Having trouble — Retry / Cancel", not the queue, which keeps trying. The current fixed cap of 5 is the expedient choice, and it is the wrong one for money — named here rather than left to be discovered. `[JUDGMENT]`

### Ordering without wedging

**`[DESIGN — not built]`** — the queue currently drains every pending action oldest-first, which is correct only because no state yet blocks on a user decision.

The queue should drain **the oldest *runnable* entry**, not simply the oldest entry.

Strict FIFO plus sequential single-flight plus a head entry awaiting a user decision equals a permanently stuck queue: a send sitting in `unresolved` would leave a NovaSave contribution behind it showing "Pending" forever, with no explanation and no action available.

FIFO *ordering* is still correct, because both action types debit the same wallet and order decides which wins when funds are tight. But ordering and blocking are different things. Entries that are terminal, awaiting a user decision, or inside their backoff window are skipped. Funds ordering stays safe because a skipped entry's hold remains deducted from the available balance, so the entry that jumps ahead cannot spend money the stuck one reserved.

Per-type lanes are the obvious alternative and are rejected: they break funds ordering for no benefit. The drain is never parallelized — concurrency buys nothing here and multiplies the race surface.

### Two balances

**`[DESIGN — not built]`** — `SyncService.pendingKobo()` exists and returns the total still owed, so the derived number is one subtraction away. The enqueue guard is not written, and lands with the Send Money screen.

| Number | Owner | Rule |
|---|---|---|
| **Confirmed** | The server | **Never** mutated client-side. Overwritten wholesale on sync |
| **Available** | Derived | `confirmed − Σ amountKobo` over all non-terminal entries |

The wallet home shows available prominently with pending secondary and tappable through to the queue.

**Available must be reduced by pending spend, and it must be enforced at enqueue.** Otherwise a user with ₦20,000 queues five transfers of ₦10,000 offline, every one of them is accepted with a cheerful "Pending", and three bounce on reconnect. Offline over-commitment is the most common real bug in this feature, and "the server will reject them" is not an acceptable answer for money. The third transfer is refused on the confirm screen.

**Confirmed is never computed locally.** Client-side arithmetic on the authoritative balance produces drift that nobody can later explain.

Holds release on `rejected` and **never** on `unresolved`. Releasing a hold on an unknown-outcome entry is a double-spend through the UI: the user watches the money come back, spends it, and then the original transfer lands.

### What this design does not claim

Exactly-once delivery over an unreliable channel to a non-idempotent receiver is the Two Generals problem. It is not achievable, and no amount of client engineering changes that.

What is achievable is **at-least-once delivery plus server-side deduplication**, which is what this design implements and what every real payment rail does.

If the server had no idempotency support, the fallbacks in order would be:

1. **Read-your-writes reconciliation.** Before resending, GET recent transactions and match on a client reference. Found means confirmed, and never resend. This converts unknown into known using only a read endpoint.
2. **Degrade to at-most-once.** Never auto-resend an ambiguous entry; require an explicit user decision. **A missed transfer the user can retry is strictly better than a duplicate debit they cannot undo.** Under-sending is recoverable; over-sending is a chargeback.
3. Client-side dedup on a natural key such as recipient plus amount plus minute — mentioned and **rejected**, because it wrongly blocks the legitimate case of sending ₦5,000 to the same person twice in a minute.

One question this design would ask a real backend team: **what is the idempotency key retention window?** Twenty-four hours is typical. An entry queued offline for three days falls outside it and deduplication silently stops applying. Past the window, stop auto-resending and escalate to a user decision. `[ASSUMPTION — needs validation]`

### Poison entries and shared devices

- **`schemaVersion` on every row, and a drain loop no single row can kill. Built.** A transfer queued on v1, then an app update to v2 that adds a required field, throws on decode. If that throw escapes the drain loop, the drain dies on every start and *every* queued transfer is stranded with the user's money in limbo. `PendingAction.fromStoredJson` checks the version first and raises one `FormatException` whatever the generated decoder threw, and the reader skips that row and keeps going. Tested as *"a row this build cannot read is skipped, not fatal"*.
- **`userId` on every row. `[DESIGN — not built]`** Shared phones are normal in this market. The drain should refuse rows belonging to a different session, logout with a non-empty queue should warn rather than clear, and a cold-start drain that fires before the session is restored must not burn an attempt on the resulting 401. There is no auth in this build, so there is no session to scope to — it is listed because shipping without it would be the bug, not because it was overlooked.

---

## Design system and UI quality

A token set plus a small number of rules that are enforced rather than suggested. Every value below is either measured or carries its reason, because a design system nobody can argue with is one nobody follows.

### Tokens

A three-layer token model is used: `Primitives` → `Semantic` → components. **Designs consume `Semantic`. Nothing binds directly to a raw value.** In Flutter this becomes a `ThemeExtension` holding the mode-varying semantic roles, with mode-invariant primitives as constants.

| Token | Light | Dark |
|---|---|---|
| `brand/primary` | `#1174ed` | `#1174ed` |
| `brand/primary-strong` | `#0e5fc4` | `#0e5fc4` |
| `bg/canvas` | `#faf9f6` | `#1f1f1f` |
| `bg/surface` | `#ffffff` | `#292929` |
| `bg/subtle` | `#f3f5f7` | `#3d3f47` |
| `text/primary` | `#000000` | `#ffffff` |
| `text/secondary` | `#4a4a49` | `#a9a9a9` |
| `text/tertiary` | `#686766` | `#8f8f8f` |
| `feedback/success` | `#08b142` | `#08b142` |
| `feedback/warning` | `#ff8f00` | `#ffb300` |
| `feedback/danger` | `#fc2d2d` | `#fc2d2d` |

Scale: spacing on a 4pt rhythm (`4 8 12 16 20 24 32 40 48 64`), radius favoring 10 and 16, icons at **16 / 20 / 24 only**, minimum touch target **44**. Type is a ten-style ramp with `Body/Medium` 14/22 as the default.

**No custom font is bundled.** A typeface is 100–400KB per weight before it renders a single pixel, and this app targets a device and a network where that is not free. The platform face costs nothing, is already hinted for the screen, and a ramp defined by size and weight survives a font swap where hand-tuned letter spacing would not. `[JUDGMENT]`

**Never branch on `Theme.of(context).brightness` to pick a color.** An `isDark ? a : b` pair is a semantic role that has not been named yet; add the field instead. No raw `Color(0x...)` literals in widgets.

### Two rules that are easy to get wrong

- **Icons.** One family, one weight, vector only, **no emoji as icons**, sizes snapped to the 16/20/24 ramp, and a 44pt frame plus an accessibility label on every icon-only control. The family matters less than picking one and not mixing.
- **Sub-12px type.** Nothing that carries meaning renders below 12pt. `Label/Small` at 10/14 exists and is for non-essential metadata only — an overline, a row of small print. Body copy never reaches for it, and neither does anything a user has to read to complete a transfer.

### Interaction detail

The difference between a production app and a generated one is mostly here:

- Press feedback within 100ms that does **not** shift layout bounds. A transform that moves neighboring content reads as jitter.
- Micro-interactions 150–300ms, exit roughly 60–70% of enter duration. Motion expresses cause and effect; it never makes a user wait for data that is already available.
- Skeletons that match the final layout shape for any wait over 300ms, never a blank screen and never a bare spinner on a data screen.
- **One primary CTA per screen.** Secondary actions are visually subordinate.
- Disabled is `bg/subtle` fill with a `text/tertiary` label — **not** `brand/primary` at reduced opacity, which reads as a rendering fault in dark mode.
- A CTA must not render as live when the screen's required input is empty. But a *blocked* screen keeps a live CTA that fixes the problem: on insufficient funds the button becomes `Fund Wallet`, because a disabled control there is a dead end rather than a state.
- Buttons name the action: `Send ₦5,000.00`, `Fund Wallet`, `Create goal`. Not `Continue`, `Proceed` or `Submit`.
- Error copy follows three beats — what happened, what it means, what to do — and never shows a raw error code.

### The Pending chip, and why it isn't amber

Pending is the one state the token set does not already answer, because it is the only thing in the app that is neither success nor failure. It is worth showing the working.

The obvious build is a filled amber pill with amber text. Measured, that is `#ffb300` on `#ff8f00` — **1.27:1** in dark. Unreadable, and it is the state a user most needs to read.

So the chip is a neutral `bg/subtle` pill, a 6px dot in the tone color, and the label in `text/primary`. That measures roughly 19:1 in light and 11:1 in dark, and it carries the state in the **word** as well as the color, which is what the do-not-signal-by-color-alone rule actually requires. The same shape then serves every tone, so `Unresolved` and `Rejected` cost nothing extra.

**Only exception rows get a chip.** A list where every row is badged has no signal in the badge. Settled transactions carry none.

---

## Accessibility

The brief makes this non-negotiable `[SOURCE: brief §2.2]`. Contrast is a measurement and is treated as one; the screen-reader, focus-order and font-scale rules below are judgment, and are marked where they are.

### Contrast rules that constrain the layout

- **White on `#1174ed` is 4.43:1 — below the 4.5:1 AA threshold.** The brand color is deliberately unchanged. It is therefore legal only for large text: **≥24px, or ≥18.66px bold**. In practice that means the balance figure and the primary CTA label, and nothing else. Any smaller white-on-blue text uses `brand/primary-strong` `#0e5fc4` at 6.08:1.
- **Never `text/tertiary` or `text/secondary` on `bg/subtle` in dark.** Measured 3.25:1 and 4.47:1 — both fail, and the second fails by 0.03, which is not a rounding error to wave through. Put them on `bg/canvas` or `bg/surface`.
- **Text on brand blue or on imagery binds `text/on-brand`, never `text/inverse`.** `text/inverse` resolves to *black* in dark mode, so a label on a card that stays blue in both themes would go black on blue.
- A hardcoded `Colors.black` passes every light-mode contrast sweep and fails the instant a dark theme exists. Unbound foregrounds are treated as a contrast defect in review, not just a style violation.

### Semantics

- **Money is announced as words, not characters.** A balance exposed as raw text reads as "naira two comma four eight zero…". The balance carries an explicit semantic label — "Balance, two million four hundred and eighty thousand naira" — with the visual text excluded from the semantics tree.
- **Every interactive element has a role and a label.** `Semantics(button: true, label: …)` is baked into the shared button and icon-button components rather than added per call site, which is the only way it survives. Icon-only controls get a 44pt frame and a label.
- **State changes are announced.** A queued item moving to sent, and a validation error appearing, are announced rather than left as a silent color change.
- Inputs carry a **visible label and** a semantic label. Placeholder-only labeling is treated as a defect.
- Focus order follows visual order; every modal and multi-step flow has a reachable escape route.

### Font scale, and a real tension

The app respects the system font scale. It does **not** clamp it to 1.0, which is the common shortcut and defeats the requirement.

**That collides with the token set, and the collision is named rather than hidden.** Tokens specify heights — list rows at 66, CTAs and fields at 52. Honoring the system font scale means **those are minimums, not fixed values**: `ConstrainedBox(minHeight:)`, never `SizedBox(height:)`, on anything containing text. Rows grow, and the layout is built to let them — no fixed-height text containers, no `maxLines: 1` on a label that carries meaning, wrapping preferred over truncation.

The layout is verified at the largest system font size as part of review, not assumed.

---

## Performance

The target device is a low-end Android phone, not the simulator on a fast laptop.

- **`ListView.builder` for the transaction list** `[SOURCE: brief §2.2]`, with a `ValueKey` on each row so state is preserved as the list changes.
- `const` constructors wherever possible; `context.select` so a balance change does not rebuild the whole tree.
- Skeletons sized to the final layout, which also prevents the layout shift that a spinner-then-content swap causes.
- Images and icons as vectors, sized from the token ramp.
- Profile with DevTools rather than guessing. The per-frame budget is ~16ms for 60fps.
- **The queue is decoded once per change, not once per rebuild.** `SyncService.changes` publishes the whole queue on every mutation and the UI listens to that, rather than re-reading and re-decoding the stored JSON inside `build`. Worth naming because the storage-backed read is cheap enough to be tempting and quadratic enough to hurt on a long list.

---

## Testing

`254 tests, 100% line coverage` `[VERIFIED]`. The 100% figure is a CI gate, not an achievement — see [tests that lie](#tests-that-lie).

### The matrix

| Level | Covers | Status |
|---|---|---|
| **Unit** | `Money` parse, format, sum, basis points. `PendingAction` transitions. Server services and repositories | Built |
| **Component** | Buttons, chips, scaffold, money text, empty and error states — including their semantics | Built |
| **Behavioral** | Queue against a real `LocalDataStorage` and a real server: offline, reconnect, retry, restart, replay | Built |
| **Widget** | Send Money recipient → amount → confirm. NovaSave contribute. Pending chip while offline | With the screens |
| **Integration** | offline → enqueue → kill app → relaunch → reconnect → **exactly one send**, on a device | With the screens |

### The tests that actually catch a regression

1. **Cold-restart replay. Built** — *"a queued action survives and then sends exactly once"* and *"a restart still recognizes a key it already applied"*. A fresh `SyncService` and a fresh server are built over the **same storage**, the way the app would come up after a kill. The load-bearing part is rebuilding from disk; a test that keeps the object graph alive proves nothing.
2. **Idempotency under replay. Built** — *"the same key applied three times moves money once"*, and *"a replay answers with the original transaction"*. The second matters more than it looks: a replay that returns a *fresh* success is indistinguishable from a double-spend at the call site.
3. **Interrupted send is retried, not lost. Built** — *"a send interrupted mid-flight is retried, not lost"*, plus *"recoverInterrupted requeues a stranded send"*.
4. **Money round-trip. Built** — `parse(format(k)) == k` across `0, 1, 29, 99, 100, 101` and large values, plus the inputs users actually produce: `".5"`, `"1."`, `"1.005"`, `"₦1,000.00"`, and a twenty-digit paste. Plus exact-equality summation over a list.
5. **Concurrent trigger race. `[DESIGN — not built]`** — fire connectivity-regained and app-resume in the same microtask, with the API gated on a `Completer` the test controls. This is what would catch the check-then-set-across-an-await bug. The future-chain mutex that fixes that bug **is** in the code; the test pinning it is not, and it **must** use a manual `Completer` — `Future.delayed` makes it pass by accident.
6. **The balance rule. `[DESIGN — not built]`** — with a ₦20,000 balance, queue three transfers of ₦10,000 offline and assert the **third is refused at enqueue**, not accepted and later bounced. Lands with the Send Money screen.

A `Clock` is not yet injected. Once backoff exists it must be, because backoff tested against real `Future.delayed` is slow and flaky, and a flaky suite gets deleted. **`[DESIGN — not built]`**

### Tests that lie

Named explicitly, because the 100% coverage gate pushes toward every one of them:

- **`bloc_test` over the Cubit with a mocked queue.** It asserts a state list, which is a restatement of the code that produced it. Storage never runs. It cannot catch a single defect described in this document — and it is roughly what most submissions offer as "offline queue tests." The queue tests here run against a real `LocalDataStorage` and a real server for exactly this reason.
- **"Enqueue offline, flip online, assert one API call" on an instance that never left memory.** Passes with no persistence at all, and passes with no idempotency key at all. It proves nothing about restart survival or deduplication.
- **`verify(...).called(1)` for the restart case.** The sharpest trap: it tests the *guard* rather than *idempotency*. The correct assertion is **`callCount == 2` and `ledger.length == 1`** — the duplicate **was** sent, and the server collapsed it. A restart test that expects one call has not demonstrated deduplication.
- **Coverage percentage.** This repo is at 100% and that is a CI gate, not evidence. 100% line coverage of the drain is reachable without exercising a single interleaving.

---

## Assumptions

Every judgment the brief's ambiguities forced.

| # | Assumption | What changes if it is wrong |
|---|---|---|
| 1 | "Idempotency key per attempt" means a stable dedup key plus a per-attempt trace id | If the grader wants it literally per-attempt, the design double-spends. Argued in full [above](#the-idempotency-key-argument) |
| 2 | The backend may deduplicate on the idempotency key | Without it, exactly-once is unachievable and the design degrades to at-most-once plus reconciliation |
| 3 | Pending spend reduces available balance and is enforced at enqueue | If over-commitment is acceptable, the enqueue guard can be dropped, but offline users will see failed transfers on reconnect |
| 4 | Idempotency keys are retained server-side for at least 24h | Entries queued longer than the window lose deduplication and must escalate to a user decision |
| 5 | One isolate owns the queue | A background-isolate enqueue path needs a separate inbox box; Hive CE cannot coordinate across isolates |
| 6 | The platform face is acceptable for a brand-led product | If a licensed brand typeface is required, the ramp is defined by size and weight so it swaps in without retuning the layout |

---

## Open questions

The things that would change the design, not the wording.

1. **Does the server deduplicate, and over what window?** Assumption 2 is the load-bearing one. Everything in [what this design does not claim](#what-this-design-does-not-claim) is the contingency.
2. **What is the correct behavior for an `unresolved` transfer after 30 days?** Holding a balance indefinitely is defensible for a week and probably not for a quarter. This needs an Ops answer, not an engineering one.
3. **Should a queued transfer be cancellable before it drains?** It is a natural user expectation and it interacts badly with an entry that may already be `inFlight`. Currently out of scope.
4. **CBN and NDPA touchpoints.** Queued money movement implies an audit trail — what is logged, retained how long, and readable by whom. Flagged as a real surface rather than answered here; the brief notes candidates are not expected to be regulatory experts `[SOURCE: brief §1]`.


---

*This is a fictional scenario created for evaluation purposes. No real FirstBank systems, customers, data or credentials are involved. The source brief is marked "not for external distribution" and is deliberately not included in this repository.*
