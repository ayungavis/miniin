.DEFAULT_GOAL := help

APP_DIR      := apps/Miniin
KIT_DIR      := packages/MiniinKit
PROJECT      := $(APP_DIR)/Miniin.xcodeproj
SCHEME       := Miniin
DERIVED      := build/DerivedData
IOS_SIM      ?= iPhone 17 Pro
IOS_DEST     := platform=iOS Simulator,name=$(IOS_SIM)
MAC_DEST     := platform=macOS
BUNDLE_ID    := com.miniin.app
XCB          := xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED)

.PHONY: help hooks generate format lint test build-ios build-macos ios-validate ios-run clean

help:
	@grep -E '^[a-z][a-z-]*:.*## ' $(MAKEFILE_LIST) | sed 's/:.*## /\t/' | expand -t24

hooks: ## Install git hooks into .git/hooks (keeps Git LFS hooks intact)
	cp .githooks/commit-msg .git/hooks/commit-msg
	chmod +x .git/hooks/commit-msg
	@echo "installed .git/hooks/commit-msg"

generate: ## Regenerate Miniin.xcodeproj from project.yml
	cd $(APP_DIR) && xcodegen generate --quiet

format: ## Apply SwiftFormat
	swiftformat .

lint: ## Run SwiftLint in strict mode
	swiftlint lint --strict --quiet

test: ## Run MiniinKit unit tests
	swift test --package-path $(KIT_DIR)

build-ios: generate ## Build the iOS Simulator app
	set -o pipefail && $(XCB) -destination 'generic/platform=iOS Simulator' -configuration Debug build | xcbeautify

build-macos: generate ## Build the macOS app
	set -o pipefail && $(XCB) -destination '$(MAC_DEST)' -configuration Debug CODE_SIGNING_ALLOWED=NO build | xcbeautify

ios-validate: format lint test build-ios build-macos ## Format, lint, test, and build both platforms
	@echo "ios-validate: OK"

ios-run: generate ## Build, install, and launch on the iOS Simulator
	set -o pipefail && $(XCB) -destination '$(IOS_DEST)' -configuration Debug build | xcbeautify
	xcrun simctl boot "$(IOS_SIM)" 2>/dev/null || true
	open -a Simulator
	xcrun simctl install booted $(DERIVED)/Build/Products/Debug-iphonesimulator/Miniin.app
	xcrun simctl launch booted $(BUNDLE_ID)

clean: ## Remove build artifacts
	rm -rf build $(KIT_DIR)/.build
