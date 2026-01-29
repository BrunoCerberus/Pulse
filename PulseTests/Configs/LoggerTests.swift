import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("Logger Tests")
@MainActor
struct LoggerTests {
    let sut = Logger.shared

    // MARK: - Singleton Tests

    @Test("Shared instance is accessible")
    func sharedInstanceIsAccessible() {
        #expect(Logger.shared === sut)
    }

    // MARK: - Severity Level Tests

    @Test("Debug logging executes without crashing")
    func debugLoggingExecutes() {
        // Should not crash
        sut.debug("Test debug message")
        sut.debug("Test debug message", category: "TestCategory")
    }

    @Test("Info logging executes without crashing")
    func infoLoggingExecutes() {
        sut.info("Test info message")
        sut.info("Test info message", category: "TestCategory")
    }

    @Test("Warning logging executes without crashing")
    func warningLoggingExecutes() {
        sut.warning("Test warning message")
        sut.warning("Test warning message", category: "TestCategory")
    }

    @Test("Error logging executes without crashing")
    func errorLoggingExecutes() {
        sut.error("Test error message")
        sut.error("Test error message", category: "TestCategory")
    }

    @Test("Critical logging executes without crashing")
    func criticalLoggingExecutes() {
        sut.critical("Test critical message")
        sut.critical("Test critical message", category: "TestCategory")
    }

    // MARK: - Category Method Tests

    @Test("Network category logging executes")
    func networkLoggingExecutes() {
        sut.network("Network request started")
        sut.network("Network request failed", level: .error)
    }

    @Test("Database category logging executes")
    func databaseLoggingExecutes() {
        sut.database("Database query executed")
        sut.database("Database error", level: .error)
    }

    @Test("UI category logging executes")
    func uiLoggingExecutes() {
        sut.ui("UI event triggered")
        sut.ui("UI warning", level: .warning)
    }

    @Test("Domain category logging executes")
    func domainLoggingExecutes() {
        sut.domain("Domain action dispatched")
        sut.domain("Domain error", level: .error)
    }

    @Test("ViewModel category logging executes")
    func viewModelLoggingExecutes() {
        sut.viewModel("ViewModel state changed")
        sut.viewModel("ViewModel error", level: .error)
    }

    @Test("Service category logging executes")
    func serviceLoggingExecutes() {
        sut.service("Service called")
        sut.service("Service error", level: .error)
    }

    // MARK: - LogLevel Tests

    @Test("LogLevel debug maps to correct OSLogType")
    func logLevelDebugMapping() {
        let level = LogLevel.debug
        #expect(level.osLogType == .debug)
    }

    @Test("LogLevel info maps to correct OSLogType")
    func logLevelInfoMapping() {
        let level = LogLevel.info
        #expect(level.osLogType == .info)
    }

    @Test("LogLevel warning maps to correct OSLogType")
    func logLevelWarningMapping() {
        let level = LogLevel.warning
        #expect(level.osLogType == .default)
    }

    @Test("LogLevel error maps to correct OSLogType")
    func logLevelErrorMapping() {
        let level = LogLevel.error
        #expect(level.osLogType == .error)
    }

    @Test("LogLevel critical maps to correct OSLogType")
    func logLevelCriticalMapping() {
        let level = LogLevel.critical
        #expect(level.osLogType == .fault)
    }

    // MARK: - Global Function Tests (DEBUG only)

    #if DEBUG
        @Test("Global logDebug function executes")
        func globalLogDebugExecutes() {
            logDebug("Global debug message")
            logDebug("Global debug message", category: "Test")
        }

        @Test("Global logInfo function executes")
        func globalLogInfoExecutes() {
            logInfo("Global info message")
            logInfo("Global info message", category: "Test")
        }

        @Test("Global logWarning function executes")
        func globalLogWarningExecutes() {
            logWarning("Global warning message")
            logWarning("Global warning message", category: "Test")
        }

        @Test("Global logError function executes")
        func globalLogErrorExecutes() {
            logError("Global error message")
            logError("Global error message", category: "Test")
        }
    #endif
}
