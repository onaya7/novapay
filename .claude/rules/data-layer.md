---
paths:
  - "lib/features/*/data/**"
  - "lib/features/*/domain/**"
  - "lib/core/services/*/**"
  - "lib/core/network_info/**"
  - "lib/core/injections/**"
---

# Data and domain layers

## Layer boundaries: the ones that get violated plausibly
- `domain/` imports **neither** `data/` nor Flutter. It depends on nothing.
- `data/` and `presentation/` both depend on `domain/`, never on each other.
- Wire-format models live in `data/models/`; entities live in `domain/entities/`. A model must not
  leak into `domain/` or `presentation/`.
- Presentation calls a **usecase**, never a repository directly.
- `lib/core/services/*` are full clean-architecture sub-features and follow these same boundaries,
  even though they live under `core/`.

## The pipeline: datasource → repository → usecase → cubit

**Endpoints** are constants in `AppUrl` (`lib/core/constants/app_url.dart`); the base URL comes
from `Env.apiBaseUrl`. **`ApiClient`** (Retrofit, `lib/core/network_info/api_client.dart`) exposes
generic HTTP verbs only. Never add a per-endpoint method to it.

1. **Datasource:** wrap the call in `InternetSafeRunner`, unwrap the response envelope
   (`(response.data as Map)['data']`), and return `Model.fromJson(...)`. If the backend's envelope
   differs, change it here and in `app_exceptions.dart`, then record the real shape in this rule.
2. **Repository:** wrap the datasource in `EitherSafeRunner` and return `Either<Failure, T>`
   (dartz), mapping `AppException`/`DioException` to a `Failure`.
3. **Usecase:** `@injectable`, extends `UseCase<T, Params>` (`lib/core/usecase/usecase.dart`; use
   `NoParams` when there are none). It only delegates to the repository.
4. **Cubit:** see `.claude/rules/state-management.md`.

Read environment values only through `Env` (`lib/core/constants/env.dart`), never with
`dotenv.env[...]` elsewhere.

## DI annotations
| Kind | Annotation |
|---|---|
| Datasource, repository | `@LazySingleton(as: <AbstractType>)` |
| Usecase | `@injectable` |
| Cubit, bloc | `@lazySingleton` |

- The container is `lib/core/injections/injection.dart` (`sl`, `configureDependencies()`).
- Third-party singletons (Dio, `ApiClient`, the Hive box, secure storage, connectivity) are
  registered by hand in `register_module.dart`.
- **Never hand-edit `injection.config.dart`**; rerun codegen.
- New Hive adapters go in `registerHiveAdapters()`
  (`lib/app/presentation/view/app_hive_adapters.dart`), kept in alphabetical order.

## Storage
- Tokens, credentials and personal data go in `SecureLocalDataStorage`, **never** in Hive.
- Preferences and caches go in `LocalDataStorage` (Hive CE).

## JSON models: silent traps
- json_serializable silently drops keys the model doesn't declare, and an unknown enum value throws
  unless the field has `@JsonKey(unknownEnumValue: ...)`. Map wire names with `@JsonValue`.
- A null `int?` printed with `toString()` becomes the string `"null"`, so format nullable values
  explicitly.
- When you add or widen a model, add a contract test that decodes captured server JSON from
  `test/fixtures/<feature>/`.

## Known limitation
`AppException` parses only `response.data['message']`. Every other 4xx/5xx detail collapses into
`ServerFailure`, so the UI cannot branch on status codes or read validation payloads. Extend
`app_exceptions.dart` when a feature needs that detail.
