# Pulse Makefile
# Build, test, and development automation

# Configuration
SCHEME_DEV = PulseDev
SCHEME_PROD = PulseProd
SCHEME_TESTS = PulseTests
SCHEME_UI_TESTS = PulseUITests
SCHEME_SNAPSHOT_TESTS = PulseSnapshotTests
DESTINATION = platform=iOS Simulator,name=iPhone Air,OS=26.1
PROJECT = Pulse.xcodeproj

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help init install-xcodegen generate setup test test-unit test-ui test-snapshot test-debug coverage coverage-report coverage-badge lint format clean clean-packages build build-release

help:
	@echo "$(GREEN)Pulse - Available Commands$(NC)"
	@echo ""
	@echo "$(YELLOW)Setup:$(NC)"
	@echo "  make init              - Setup Mint, SwiftFormat, SwiftLint, git hooks"
	@echo "  make install-xcodegen  - Install XcodeGen via Homebrew"
	@echo "  make generate          - Generate Xcode project from project.yml"
	@echo "  make setup             - install-xcodegen + generate"
	@echo ""
	@echo "$(YELLOW)Build:$(NC)"
	@echo "  make build             - Build for development (Debug)"
	@echo "  make build-release     - Build for release"
	@echo ""
	@echo "$(YELLOW)Testing:$(NC)"
	@echo "  make test              - Run all tests"
	@echo "  make test-unit         - Run unit tests only"
	@echo "  make test-ui           - Run UI tests only"
	@echo "  make test-snapshot     - Run snapshot tests only"
	@echo "  make test-debug        - Run tests with verbose output"
	@echo ""
	@echo "$(YELLOW)Coverage:$(NC)"
	@echo "  make coverage          - Run tests with coverage report"
	@echo "  make coverage-report   - Show detailed per-file coverage"
	@echo "  make coverage-badge    - Generate SVG badge"
	@echo ""
	@echo "$(YELLOW)Code Quality:$(NC)"
	@echo "  make lint              - Run SwiftFormat + SwiftLint checks"
	@echo "  make format            - Auto-fix formatting with SwiftFormat"
	@echo ""
	@echo "$(YELLOW)Cleanup:$(NC)"
	@echo "  make clean             - Remove generated Xcode project"
	@echo "  make clean-packages    - Clean SPM dependencies"

# Setup commands
init:
	@echo "$(GREEN)Setting up development environment...$(NC)"
	@which mint > /dev/null || brew install mint
	@mint bootstrap
	@mint install nicklockwood/SwiftFormat
	@mint install realm/SwiftLint
	@echo "$(GREEN)Installing git hooks...$(NC)"
	@mkdir -p .git/hooks
	@echo '#!/bin/sh\nmake lint' > .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "$(GREEN)Setup complete!$(NC)"

install-xcodegen:
	@echo "$(GREEN)Installing XcodeGen...$(NC)"
	@which xcodegen > /dev/null || brew install xcodegen
	@echo "$(GREEN)XcodeGen installed!$(NC)"

generate:
	@echo "$(GREEN)Generating Xcode project...$(NC)"
	@xcodegen generate
	@echo "$(GREEN)Project generated!$(NC)"

setup: install-xcodegen generate

# Build commands
build:
	@echo "$(GREEN)Building Pulse (Debug)...$(NC)"
	@xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME_DEV) \
		-destination "$(DESTINATION)" \
		-configuration Debug \
		CODE_SIGNING_ALLOWED=NO \
		| xcpretty

build-release:
	@echo "$(GREEN)Building Pulse (Release)...$(NC)"
	@xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME_PROD) \
		-destination "$(DESTINATION)" \
		-configuration Release \
		CODE_SIGNING_ALLOWED=NO \
		| xcpretty

# Test commands
test:
	@echo "$(GREEN)Running all tests...$(NC)"
	@xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME_DEV) \
		-destination "$(DESTINATION)" \
		-retry-tests-on-failure \
		CODE_SIGNING_ALLOWED=NO \
		| xcpretty

test-unit:
	@echo "$(GREEN)Running unit tests...$(NC)"
	@xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME_TESTS) \
		-destination "$(DESTINATION)" \
		-retry-tests-on-failure \
		CODE_SIGNING_ALLOWED=NO \
		| xcpretty

test-ui:
	@echo "$(GREEN)Running UI tests...$(NC)"
	@xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME_UI_TESTS) \
		-destination "$(DESTINATION)" \
		-retry-tests-on-failure \
		CODE_SIGNING_ALLOWED=NO \
		| xcpretty

test-snapshot:
	@echo "$(GREEN)Running snapshot tests...$(NC)"
	@xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME_SNAPSHOT_TESTS) \
		-destination "$(DESTINATION)" \
		CODE_SIGNING_ALLOWED=NO \
		| xcpretty

test-debug:
	@echo "$(GREEN)Running tests with verbose output...$(NC)"
	@xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME_DEV) \
		-destination "$(DESTINATION)" \
		-retry-tests-on-failure \
		CODE_SIGNING_ALLOWED=NO

# Coverage commands
coverage:
	@echo "$(GREEN)Running tests with coverage...$(NC)"
	@xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME_DEV) \
		-destination "$(DESTINATION)" \
		-enableCodeCoverage YES \
		-resultBundlePath ./TestResults.xcresult \
		CODE_SIGNING_ALLOWED=NO \
		| xcpretty
	@echo "$(GREEN)Coverage report generated!$(NC)"

coverage-report:
	@echo "$(GREEN)Generating detailed coverage report...$(NC)"
	@xcrun xccov view --report --files-for-target Pulse.app ./TestResults.xcresult

coverage-badge:
	@echo "$(GREEN)Generating coverage badge...$(NC)"
	@./scripts/generate-coverage-badge.sh

# Code quality commands
lint:
	@echo "$(GREEN)Running SwiftFormat check...$(NC)"
	@swiftformat --lint Pulse PulseTests || true
	@echo "$(GREEN)Running SwiftLint...$(NC)"
	@swiftlint lint --path Pulse --path PulseTests || true

format:
	@echo "$(GREEN)Formatting code with SwiftFormat...$(NC)"
	@swiftformat Pulse PulseTests
	@echo "$(GREEN)Code formatted!$(NC)"

# Cleanup commands
clean:
	@echo "$(YELLOW)Removing generated Xcode project...$(NC)"
	@rm -rf $(PROJECT)
	@rm -rf TestResults.xcresult
	@echo "$(GREEN)Clean complete!$(NC)"

clean-packages:
	@echo "$(YELLOW)Cleaning SPM dependencies...$(NC)"
	@rm -rf ~/Library/Developer/Xcode/DerivedData/Pulse-*
	@rm -rf .build
	@echo "$(GREEN)Packages cleaned!$(NC)"
