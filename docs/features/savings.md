# NovaSave

## Purpose
Money set aside for something specific. A goal has a name, a target and a date; contributions move
money out of the wallet and into it, and the bar shows how far along it is.

## Entry screens
- `SavingsPage` (`presentation/view/savings_page.dart`) — the list, one of the four tabs behind
  `AppShell`'s bottom nav. The wallet's `Save` quick action switches to this tab
  (`context.goNamed(RoutesName.savings)`) rather than pushing a second copy. Each `GoalCard` carries
  an overflow button that opens `GoalActionsSheet` (edit, delete), shown as `showModalBottomSheet`
  from this view.
- `CreateGoalPage` — name, target, date. Reached via `context.pushNamed(RoutesName.createGoal)`.
- `EditGoalPage` — the same three fields, pre-filled. Reached via
  `context.pushNamed(RoutesName.editGoal, extra: goal)` from a card's overflow menu.
- `ContributePage` — the amount, pushed from a goal card via
  `context.pushNamed(RoutesName.contribute, extra: goal)` — the goal travels as router `extra`,
  since it isn't part of the path.

Every sub-screen is pushed from `SavingsPage`, which `await`s the push and refreshes once it pops.

## Endpoints
Through `NovaPayApi`:

| Call | Used for |
|---|---|
| `goals()` | the list |
| `createGoal(...)` | a new goal, **sent directly** |
| `updateGoal(...)` | editing name/target/date, **sent directly** |
| `deleteGoal(...)` | removing a goal, **sent directly** |
| `balance()` | what may be spent |

Contributions do **not** call the API. They go through `SyncService.enqueue` as
`PendingActionType.contribute`, and the queue owns the call.

## State
Four cubits, each `@injectable` so a screen gets a fresh one:

- `SavingsCubit` — `loading` · `ready(goals)` · `failure(message)`. Loads once, then follows the
  queue so a contribution shows without a reload. Also owns `delete(goalId)`, which refreshes the
  list on success and folds a refusal into `failure(message)`.
- `CreateGoalCubit` — `editing(draft, {error})` · `submitting` · `done`.
- `EditGoalCubit` — `initial` · `editing(draft, {error})` · `submitting` · `done`, seeded from the
  goal via `start(goal)`, the same shape as `ContributeCubit`.
- `ContributeCubit` — `initial` · `editing(draft, {error})` · `submitting` · `done`.

None is paginated.

## Key files
1. `domain/entities/savings_goal_item.dart` — the merge of settled and queued, and the progress maths.
2. `data/repositories/savings_repository_impl.dart` — the merge, the funds guard, the enqueue.
3. `presentation/cubit/contribute_cubit.dart` — the amount flow.
4. `presentation/widgets/savings_widgets.dart` — the card, the bar, the date field.

## Gotchas
- **A goal's status is computed, never stored.** `GoalCard` shows "Reached" once
  `SavingsGoalItem.isComplete`, "Pending" while `hasPending`, or no badge otherwise — there is no
  status field to set by hand.
- **Deleting a goal refunds what was saved, and refuses while a contribution is pending.**
  `SavingsService.deleteGoal` credits `savedKobo` back to the wallet before removing the goal.
  `SavingsRepositoryImpl.deleteGoal` refuses first, before calling the API, if this goal still has a
  queued contribution — otherwise the queue would later replay a contribution against a goal that no
  longer exists.
- **Creating, editing and deleting are not queued; contributing is.** None of the first three moves
  money (a delete's refund happens synchronously in the same call), so each is safe to require a
  connection and simply ask again. A contribution moves money, so it must survive being offline and
  must carry an idempotency key.
- **Progress counts queued money.** `projected = saved + pending`, and the bar reads from that, so
  tapping *Add* moves the bar immediately. `saved` remains the server's number and is never computed
  on the client.
- **Progress is integer basis points.** `progressFraction` is the only double, it is one-way into
  the bar, and the printed percentage is computed separately from integers — never read back off
  the fraction.
- **`ContributeState.draft` returns null on the base and is overridden by each variant's field.**
  A `switch` there is dead code: freezed declares `draft` as a field on every variant except
  `initial`, and a field overrides an inherited getter.
- **`ContributeState.initial` renders a spinner.** A widget test that pumps it and then calls
  `pumpAndSettle` will time out, because the spinner never stops animating.
- **The funds guard exists twice**, as in Send Money: the screen blocks it, and the repository
  blocks it again in case the balance moved.
- `GoalDateField` passes an explicit `lastDate`. The picker's default is today, which would block
  every valid choice for a goal that is by definition in the future.
- **The pinned `Create goal` button uses `CustomScaffold`'s default padding.** The shell's bottom
  nav is opaque, so nothing here needs lifting above it — see `.claude/rules/ui-conventions.md`.
