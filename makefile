# Flavor run and build commands, plus the CI gates. `make help` lists every target.

.DEFAULT_GOAL := help

.PHONY: run-dev run-staging run-prod \
	build-dev-apk build-staging-apk build-prod-apk \
	build-dev-aab build-staging-aab build-prod-aab \
	build-dev-ipa build-staging-ipa build-prod-ipa \
	get codegen gen-l10n \
	analyze bloc-lint lint format format-check \
	test coverage golden golden-update ci \
	clean help

run-dev: ## Run the development flavor
	fvm flutter run -t lib/main_development.dart --flavor development

run-staging: ## Run the staging flavor
	fvm flutter run -t lib/main_staging.dart --flavor staging

run-prod: ## Run the production flavor
	fvm flutter run -t lib/main_production.dart --flavor production

build-dev-apk: ## Build a debug development APK
	fvm flutter build apk -t lib/main_development.dart --flavor development --debug

build-staging-apk: ## Build a release staging APK
	fvm flutter build apk -t lib/main_staging.dart --flavor staging --release

build-prod-apk: ## Build a release production APK
	fvm flutter build apk -t lib/main_production.dart --flavor production --release

build-dev-aab: ## Build a debug development app bundle
	fvm flutter build appbundle -t lib/main_development.dart --flavor development --debug

build-staging-aab: ## Build a release staging app bundle
	fvm flutter build appbundle -t lib/main_staging.dart --flavor staging --release

build-prod-aab: ## Build a release production app bundle
	fvm flutter build appbundle -t lib/main_production.dart --flavor production --release

build-dev-ipa: ## Build a development IPA
	fvm flutter build ipa -t lib/main_development.dart --flavor development --debug

build-staging-ipa: ## Build a release staging IPA
	fvm flutter build ipa -t lib/main_staging.dart --flavor staging --release

build-prod-ipa: ## Build a release production IPA
	fvm flutter build ipa -t lib/main_production.dart --flavor production --release

get: ## Fetch packages
	fvm flutter pub get

codegen: ## Run build_runner for freezed, json_serializable and injectable
	fvm dart run build_runner build --delete-conflicting-outputs

gen-l10n: ## Regenerate lib/l10n/gen from lib/l10n/arb/*.arb
	fvm flutter gen-l10n

analyze: ## flutter analyze; exits non-zero on info, same as CI
	fvm flutter analyze lib test

bloc-lint: ## The bloc_lint rules flutter analyze does not run
	fvm dart run bloc_tools:bloc lint .

lint: analyze bloc-lint ## Both analyzers CI runs

format: ## Format lib and test in place
	fvm dart format lib test

format-check: ## Fail if formatting lib and test would change a file, same as CI
	fvm dart format --set-exit-if-changed lib test

test: ## Run the full test suite, goldens included
	fvm flutter test

coverage: ## Run the full test suite with an lcov report at coverage/lcov.info
	fvm flutter test --coverage

golden: ## Run only the golden-image tests
	fvm flutter test --tags golden

golden-update: ## Regenerate golden images after an intentional visual change
	fvm flutter test --update-goldens --tags golden

ci: format-check lint coverage ## Every local gate CI also runs, in the same order

clean: ## Remove build output and fetch packages again
	fvm flutter clean && fvm flutter pub get

help: ## List the available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
