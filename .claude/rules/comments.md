---
paths:
  - "lib/**"
  - "test/**"
---

# Comments: one line, default to none

The bar is **zero comments**. A comment earns its place only when a reader who understands Dart
and this codebase would still get the line wrong. Then it is **one line**, wrapped at 80 columns
including the indent.

## Hard rules
- **One line.** Not two. If it doesn't fit on one, the second line is detail that belongs in the
  commit message, `docs/features/<feature>.md` or a `.claude/rules/` file.
- **Never restate the code.** `// Persists the token` above `saveToken()` is noise.
- **No `///` essays.** A doc comment on a public member follows the same one-line limit. Don't
  write a `///` paragraph explaining a whole mechanism; that's what `docs/` is for.
- **Don't narrate the change.** No "fixed a bug where…" and no "previously this…". The diff and the
  commit message carry that.
- **Don't cross-reference another symbol's rationale** ("same reasoning as [_endSession]"). State
  this line's reason, or say nothing.
- **Never reference a design-tool node or frame.** Describe the widget by its purpose.

## Where a comment is allowed at all

**Reusable widgets may carry one doc line.** A shared widget in `lib/core/components/**` or a
feature's `presentation/widgets/**` may open with a single `///` saying what it is for and how it is
meant to be used. That line is the closest thing the widget has to an API; callers read it instead
of the build method. Its constructor params get a `///` only when the name genuinely can't carry the
meaning (an encoded backend enum, a unit).

**Views carry no comments at all.** Anything under `presentation/view/**` gets zero `//` and zero
`///`, with no exceptions. If something in a view needs explaining, one of these is true, and each
has a fix:

- It's a fact about the feature: put it in `docs/features/<feature>.md`.
- It's logic that needs a name: lift it into a cubit, a helper, or a named private method.
- It's a widget that needs explaining: it belongs in `widgets/` with its one doc line.

Extracting a `_canSubmit` getter or a well-named local beats any comment describing the same
condition inline.

## Keep the reason, drop the retelling
State the *why* in its shortest true form. Most long comments are one sentence of reason plus
several of justification. Keep the first; delete the rest.

```dart
// BAD — four lines to say one thing
/// Apple sends the user's name on the first authorization for a bundle id and
/// never again — not on reinstall, not after the account is deleted. A
/// sign-up can still fail after that one chance, so the name is parked in the
/// keychain the moment it arrives and read back later.

// GOOD
/// Apple sends the name once ever, so it is parked until sign-up accepts it.
```

```dart
// BAD — a paragraph of consequence
/// The cubits behind these buttons are app-wide singletons, so every mounted
/// copy sees the same state change. Only the visible screen may act on it —
/// otherwise a flow that routes back to its starting screen pushes a second
/// copy, which then reacts too.

// GOOD
/// The cubits are app-wide singletons — only the visible screen may react.
```

## Where the deleted detail goes
| Detail | Home |
|---|---|
| Why this change was made | commit message |
| How a feature's flow hangs together | `docs/features/<feature>.md` |
| A convention future changes must follow | a `.claude/rules/` file |
| System-wide mechanics | `docs/ARCHITECTURE.md` |

## Lint directives are not prose
`// ignore:` and `// ignore_for_file:` are code, not comments; never delete them.
`very_good_analysis` enables `document_ignores`, which **requires** one explanatory line directly
above the directive. That pair is the one sanctioned two-line block; keep the justification to a
single line.

## Section markers are fine
Single-word groupers in a long constants file, like `// Auth` or `// Settings` in `app_url.dart`,
are not prose comments and stay.
