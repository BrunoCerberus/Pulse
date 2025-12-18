# Pulse Makefile
# Build, test, and development automation

.PHONY: help init install-xcodegen generate setup test test-unit test-ui test-snapshot test-debug clean clean-packages coverage coverage-report coverage-badge deeplink-test lint format build build-release

# Default target
help:
	@echo "Available commands:"
	@echo "  init              - Setup Mint, SwiftFormat, and SwiftLint"
	@echo "  install-xcodegen  - Install XcodeGen using Homebrew"
	@echo "  generate          - Generate Xcode project from project.yml"
	@echo "  setup             - install-xcodegen + generate"
	@echo "  build             - Build for development (Debug)"
	@echo "  build-release     - Build for release"
	@echo "  lint              - Run SwiftLint and SwiftFormat checks"
	@echo "  format            - Auto-fix formatting with SwiftFormat"
	@echo "  test              - Run all tests on iOS 26.1 iPhone Air"
	@echo "  test-unit         - Run only unit tests"
	@echo "  test-ui           - Run only UI tests"
	@echo "  test-snapshot     - Run only snapshot tests"
	@echo "  test-debug        - Run tests with full verbose output for debugging"
	@echo "  clean             - Remove generated Xcode project"
	@echo "  clean-packages    - Clean Swift Package Manager dependencies"
	@echo "  coverage          - Run tests with coverage and show app %"
	@echo "  coverage-report   - Show detailed per-file coverage report"
	@echo "  coverage-badge    - Generate SVG badge at badges/coverage.svg"
	@echo "  deeplink-test     - Test deeplink functionality specifically"
	@echo "  help              - Show this help message"

# Setup Mint, SwiftFormat, and SwiftLint
init:
	@echo "Setting up development environment..."
	@echo "Checking for Homebrew..."
	@if ! command -v brew &> /dev/null; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	else \
		echo "Homebrew already installed"; \
	fi
	@echo "Installing XcodeGen..."
	@brew install xcodegen || true
	@echo "Installing Mint..."
	@brew install mint || true
	@echo "Installing SwiftLint..."
	@brew install swiftlint || true
	@echo "Installing SwiftFormat via Mint..."
	@mint install nicklockwood/SwiftFormat
	@echo "Setting up git hooks..."
	@mkdir -p .git/hooks
	@echo '#!/bin/sh\nmake lint' > .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Development environment setup complete!"

# Run linting checks (SwiftFormat + SwiftLint)
lint:
	@echo "Running SwiftFormat lint check..."
	@mint run swiftformat Pulse PulseTests --lint
	@echo "SwiftFormat check passed"
	@echo ""
	@echo "Running SwiftLint..."
	@swiftlint lint --path Pulse --path PulseTests
	@echo "SwiftLint check passed"

# Auto-fix formatting with SwiftFormat
format:
	@echo "Running SwiftFormat..."
	@mint run swiftformat Pulse PulseTests
	@echo "Formatting complete!"

# Install XcodeGen
install-xcodegen:
	@echo "Installing XcodeGen..."
	@brew install xcodegen

# Generate Xcode project
generate:
	@echo "Generating Xcode project..."
	@xcodegen generate
	@echo "Project generated successfully!"

# Install and generate in one command
setup: install-xcodegen generate
	@echo "Setup complete!"

# Clean Swift Package Manager dependencies
clean-packages:
	@echo "Cleaning Swift Package Manager dependencies..."
	@rm -rf Pulse.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
	@rm -rf Pulse.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/configuration
	@rm -rf Pulse.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/artifacts
	@echo "Package dependencies cleaned!"

# Build commands
build:
	@echo "Building Pulse (Debug)..."
	@xcodebuild build \
		-project Pulse.xcodeproj \
		-scheme PulseDev \
		-destination 'platform=iOS Simulator,name=iPhone Air,OS=26.1' \
		-configuration Debug \
		CODE_SIGNING_ALLOWED=NO

build-release:
	@echo "Building Pulse (Release)..."
	@xcodebuild build \
		-project Pulse.xcodeproj \
		-scheme PulseProd \
		-destination 'platform=iOS Simulator,name=iPhone Air,OS=26.1' \
		-configuration Release \
		CODE_SIGNING_ALLOWED=NO

# Run all tests
test:
	@echo "Running all tests on iOS 26.1 iPhone Air..."
	@make clean-packages
	@if xcodebuild clean test -project Pulse.xcodeproj -scheme PulseDev -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.1' CODE_SIGNING_ALLOWED=NO 2>&1 | tee /tmp/test_output.log; then \
		echo "All tests completed successfully!"; \
		grep -E "(Test run.*passed|Test run.*failed)" /tmp/test_output.log | tail -2; \
	else \
		echo "Tests failed! Here are the failure details:"; \
		echo ""; \
		grep -E "(✘|failed|FAIL|Fatal error|error:|Expectation failed)" /tmp/test_output.log | head -20; \
		echo ""; \
		echo "Full output saved to /tmp/test_output.log"; \
		exit 1; \
	fi

# Run tests with coverage and print app target percent
coverage:
	@echo "Running tests with coverage on iOS 26.1 iPhone Air..."
	@rm -rf build/TestResults.xcresult
	@xcodebuild clean test -project Pulse.xcodeproj -scheme PulseDev -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.1' -enableCodeCoverage YES -resultBundlePath build/TestResults.xcresult CODE_SIGNING_ALLOWED=NO 2>&1 | tee /tmp/coverage_output.log | grep -E '(Testing|Test Suite|Test Case|passed|failed)' || true
	@echo ""
	@if grep -E "Executed .* tests, with [1-9][0-9]* failures" /tmp/coverage_output.log > /dev/null; then \
		echo "Tests failed! Coverage report may be incomplete."; \
		echo ""; \
		echo "Failure details:"; \
		grep -E "(✘|failed|FAIL|Fatal error|error:|Expectation failed)" /tmp/coverage_output.log | head -20; \
		echo ""; \
		echo "Full output saved to /tmp/coverage_output.log"; \
		exit 1; \
	elif grep -E "Executed .* tests, with 0 failures" /tmp/coverage_output.log > /dev/null; then \
		echo "All tests passed!"; \
		echo ""; \
		echo "Coverage summary (Pulse.app):"; \
		xcrun xccov view --report --only-targets build/TestResults.xcresult | awk '/Pulse.app/{print $$0}'; \
		echo ""; \
		echo "Use 'make coverage-report' for details."; \
	else \
		echo "Could not determine test status!"; \
		echo ""; \
		echo "Full output saved to /tmp/coverage_output.log"; \
		exit 1; \
	fi

# Show full per-file coverage report
coverage-report:
	@test -d build/TestResults.xcresult || (echo "No xcresult found. Run 'make coverage' first." && exit 1)
	@xcrun xccov view --report build/TestResults.xcresult

# Generate a simple SVG badge with current app coverage
coverage-badge:
	@bash scripts/generate-coverage-badge.sh build/TestResults.xcresult
	@echo "Badge generated at badges/coverage.svg"

# Run only unit tests
test-unit:
	@echo "Running unit tests on iOS 26.1 iPhone Air..."
	@make clean-packages
	@if xcodebuild clean test -project Pulse.xcodeproj -scheme PulseDev -only-testing:PulseTests -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.1' CODE_SIGNING_ALLOWED=NO 2>&1 | tee /tmp/test_output.log; then \
		echo "Unit tests completed successfully!"; \
		grep -E "(Test run.*passed|Test run.*failed)" /tmp/test_output.log | tail -5; \
	else \
		echo "Unit tests failed! Here are the failure details:"; \
		echo ""; \
		grep -E "(✘|failed|FAIL|Fatal error|error:|Expectation failed)" /tmp/test_output.log | head -20; \
		echo ""; \
		echo "Full output saved to /tmp/test_output.log"; \
		exit 1; \
	fi

# Run only UI tests
test-ui:
	@echo "Running UI tests on iOS 26.1 iPhone Air..."
	@make clean-packages
	@if xcodebuild clean test -project Pulse.xcodeproj -scheme PulseDev -only-testing:PulseUITests -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.1' CODE_SIGNING_ALLOWED=NO 2>&1 | tee /tmp/test_output.log; then \
		echo "UI tests completed successfully!"; \
		grep -E "(Test run.*passed|Test run.*failed)" /tmp/test_output.log | tail -1; \
	else \
		echo "UI tests failed! Here are the failure details:"; \
		echo ""; \
		grep -E "(✘|failed|FAIL|Fatal error|error:|Expectation failed)" /tmp/test_output.log | head -20; \
		echo ""; \
		echo "Full output saved to /tmp/test_output.log"; \
		exit 1; \
	fi

# Run only snapshot tests
test-snapshot:
	@echo "Running snapshot tests on iOS 26.1 iPhone Air..."
	@make clean-packages
	@if xcodebuild clean test -project Pulse.xcodeproj -scheme PulseSnapshotTests -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.1' CODE_SIGNING_ALLOWED=NO 2>&1 | tee /tmp/test_output.log; then \
		echo "Snapshot tests completed successfully!"; \
		grep -E "(Test run.*passed|Test run.*failed)" /tmp/test_output.log | tail -1; \
	else \
		echo "Snapshot tests failed! Here are the failure details:"; \
		echo ""; \
		grep -E "(✘|failed|FAIL|Fatal error|error:|Expectation failed)" /tmp/test_output.log | head -20; \
		echo ""; \
		echo "Full output saved to /tmp/test_output.log"; \
		exit 1; \
	fi

# Run tests with full verbose output for debugging
test-debug:
	@echo "Running unit tests with full verbose output for debugging..."
	@echo "This will show all test output including passing tests"
	@make clean-packages
	@xcodebuild clean test -project Pulse.xcodeproj -scheme PulseDev -only-testing:PulseTests -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.1' CODE_SIGNING_ALLOWED=NO 2>&1 | tee /tmp/test_debug.log
	@echo ""
	@echo "Full debug output saved to /tmp/test_debug.log"

# Test deeplink functionality specifically
deeplink-test:
	@echo "Testing deeplink functionality..."
	@make clean-packages
	@xcodebuild clean test -project Pulse.xcodeproj -scheme PulseDev -only-testing:PulseTests/DeeplinkManagerTests -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.1' CODE_SIGNING_ALLOWED=NO
	@echo "Deeplink tests completed!"

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -rf Pulse.xcodeproj
	@rm -rf build/TestResults.xcresult
	@echo "Cleaned!"
