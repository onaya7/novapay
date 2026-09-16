---
paths:
  - "lib/features/**"
---

# Keep the feature doc current

Every feature has a doc: `docs/features/<feature>.md`, or `docs/features/<feature>/*.md` when the
feature splits into sub-areas. Update it **in the same change** as the code. Claude Code's hook warns
when feature code changed and its doc did not.

`lib/core/services/*` has no doc of its own. Record load-bearing facts about those modules in the
doc of the feature that consumes them, or in `docs/ARCHITECTURE.md`.

## Six headings, in this order
1. **Purpose:** what the feature is for.
2. **Entry screens:** its views and routes.
3. **Endpoints:** the `AppUrl` getters it calls.
4. **State:** its cubits and blocs, and which are paginated.
5. **Key files:** the 3–5 files a newcomer should read first.
6. **Gotchas:** non-obvious behavior.

## Update only when a section became wrong
Update for:
- a view or route added, removed or renamed
- an endpoint added, removed or repointed
- a cubit added or removed, or one that became paginated
- key files that changed
- a gotcha discovered, or a gotcha fixed

**Don't** update the doc for a widget tweak, a copy change, a refactor that moves code without
changing behavior, or a bug fix that doesn't affect any section. Churn is what makes docs stop being
trusted.

## Writing rules
- State only what you have verified. Grep every endpoint against `app_url.dart` and every cubit
  against the real `presentation/cubit/` listing.
- Keep the six headings, in order. A uniform shape makes drift visible.
- Prefer a fact that stays true ("`OrdersCubit` is paginated") over one that won't (a step-by-step
  flow description).
- If a gotcha stops being true, **delete it**. A wrong gotcha is worse than none.
