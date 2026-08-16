import Foundation
#if canImport(UIKit)
    import UIKit
#endif

#if canImport(UIKit)
    /// Keeps the process alive long enough for a pause handshake to persist its
    /// resume data.
    @MainActor
    private final class BackgroundAssertion {
        private var identifier: UIBackgroundTaskIdentifier = .invalid

        init(name: String) {
            identifier = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
                self?.end()
            }
        }

        func end() {
            guard identifier != .invalid else { return }
            UIApplication.shared.endBackgroundTask(identifier)
            identifier = .invalid
        }
    }
#endif

final class LLMModelDownloadOperation: NSObject, @unchecked Sendable {
    /// Minimum progress delta worth publishing. `didWriteData` fires per received
    /// chunk, and every call fans out to the main queue through a domain-state
    /// publish, so unthrottled reporting floods the UI for an 806 MB transfer.
    private static let progressReportingStep = 0.01

    /// How long to wait for a pause handshake before assuming the system
    /// suspended the process mid-cancel and recovering.
    private static let pauseRecoveryInterval: TimeInterval = 5

    private let sourceURL: URL
    private let destinationURL: URL
    private let resumeDataStore: LLMModelResumeDataStore
    private let fileManager: FileManager
    private let expectedSizeBytes: UInt64
    private let expectedSHA256: String
    private let protocolClasses: [AnyClass]?
    private let lock = NSLock()

    private var session: URLSession?
    private var task: URLSessionDownloadTask?
    private var pausedTask: URLSessionDownloadTask?
    private var continuation: CheckedContinuation<URL, Error>?
    private var didFinish = false
    /// Set once a transfer hands its file over for verification. From that
    /// point the async verification owns the outcome, so no new task may start
    /// and no delegate callback may finish the operation.
    private var isCommitting = false
    private var cancellationRequested = false
    private var pausingForBackground = false
    private var waitingForPauseCancellation = false
    private var foregroundRequested = false
    private var generation = 0
    private var startedFromResumeData = false
    private var lastReportedProgress: Double?
    private var progressHandler: (@Sendable (Double) -> Void)?
    private var observers: [NSObjectProtocol] = []

    init(
        sourceURL: URL,
        destinationURL: URL,
        resumeDataURL: URL,
        fileManager: FileManager,
        expectedSizeBytes: UInt64,
        expectedSHA256: String,
        protocolClasses: [AnyClass]? = nil,
    ) {
        self.protocolClasses = protocolClasses
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        resumeDataStore = LLMModelResumeDataStore(url: resumeDataURL, fileManager: fileManager)
        self.fileManager = fileManager
        self.expectedSizeBytes = expectedSizeBytes
        self.expectedSHA256 = expectedSHA256
    }

    func download(progressHandler: @escaping @Sendable (Double) -> Void) async throws -> URL {
        registerLifecycleObservers()
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                lock.lock()
                self.continuation = continuation
                self.progressHandler = progressHandler
                lock.unlock()
                startDownload()
            }
        }, onCancel: { [weak self] in
            self?.cancel()
        })
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.allowsExpensiveNetworkAccess = false
        configuration.allowsConstrainedNetworkAccess = false
        configuration.timeoutIntervalForResource = 24 * 60 * 60
        if let protocolClasses {
            configuration.protocolClasses = protocolClasses
        }
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    private func startDownload() {
        let resumeData = resumeDataStore.load(for: sourceURL)

        lock.lock()
        guard !didFinish,
              !cancellationRequested,
              !isCommitting,
              !pausingForBackground,
              !waitingForPauseCancellation,
              task == nil
        else {
            lock.unlock()
            return
        }

        let session = makeSession()
        let task = resumeData.map(session.downloadTask(withResumeData:)) ?? session.downloadTask(with: sourceURL)
        generation += 1
        startedFromResumeData = resumeData != nil
        lastReportedProgress = nil
        self.session = session
        self.task = task
        lock.unlock()

        task.resume()
    }

    private func cancel() {
        lock.lock()
        guard !didFinish else {
            lock.unlock()
            return
        }
        cancellationRequested = true
        pausingForBackground = true
        let task = task
        let session = session
        self.task = nil
        self.session = nil
        lock.unlock()

        guard let task else {
            resumeDataStore.remove()
            finish(.failure(CancellationError()))
            return
        }

        task.cancel { [weak self] _ in
            guard let self else { return }
            resumeDataStore.remove()
            session?.finishTasksAndInvalidate()
            finish(.failure(CancellationError()))
        }
    }

    #if canImport(UIKit)
        private func registerLifecycleObservers() {
            let center = NotificationCenter.default
            let backgroundObserver = center.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: nil,
            ) { [weak self] _ in
                self?.pauseForBackground()
            }
            let foregroundObserver = center.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: nil,
            ) { [weak self] _ in
                self?.resumeAfterBackground()
            }
            lock.withLock {
                observers = [backgroundObserver, foregroundObserver]
            }
        }

        private func pauseForBackground() {
            lock.lock()
            guard !didFinish, !cancellationRequested, !pausingForBackground, let task else {
                lock.unlock()
                return
            }
            pausingForBackground = true
            waitingForPauseCancellation = true
            foregroundRequested = false
            let pauseGeneration = generation
            let session = session
            // The task stays reachable as `pausedTask` so a transfer that
            // completes concurrently with the cancel is still committed.
            pausedTask = task
            self.task = nil
            self.session = nil
            lock.unlock()

            let assertion = Self.makeBackgroundAssertion()

            task.cancel { [weak self] resumeData in
                guard let self else {
                    Self.endBackgroundAssertion(assertion)
                    return
                }
                defer { Self.endBackgroundAssertion(assertion) }
                completePause(
                    of: task,
                    session: session,
                    resumeData: resumeData,
                    pauseGeneration: pauseGeneration,
                )
            }
        }

        private func completePause(
            of pausedDownloadTask: URLSessionDownloadTask,
            session: URLSession?,
            resumeData: Data?,
            pauseGeneration: Int,
        ) {
            lock.lock()
            let isStale = generation != pauseGeneration
            if pausedTask === pausedDownloadTask {
                pausedTask = nil
            }
            if !isStale {
                waitingForPauseCancellation = false
            }
            let isFinished = didFinish
            let isCancelled = cancellationRequested
            lock.unlock()

            session?.finishTasksAndInvalidate()

            // A newer attempt already owns the sidecar, so leave it alone.
            guard !isStale, !isFinished else { return }
            guard !isCancelled else {
                resumeDataStore.remove()
                return
            }
            resumeDataStore.persist(resumeData, for: sourceURL)

            lock.lock()
            let shouldResume = foregroundRequested
                && !didFinish
                && !cancellationRequested
                && !isCommitting
            if shouldResume {
                foregroundRequested = false
                pausingForBackground = false
            }
            lock.unlock()

            if shouldResume {
                startDownload()
            }
        }

        private func resumeAfterBackground() {
            lock.lock()
            guard !didFinish, !cancellationRequested else {
                lock.unlock()
                return
            }
            foregroundRequested = true
            let isWaitingForPause = waitingForPauseCancellation
            if !isWaitingForPause {
                foregroundRequested = false
                pausingForBackground = false
            }
            let resumeGeneration = generation
            lock.unlock()

            guard isWaitingForPause else {
                startDownload()
                return
            }

            // The pause handshake restarts the download itself. If the system
            // suspended the process before its completion handler ran, that
            // never happens, so recover instead of awaiting forever.
            DispatchQueue.global(qos: .utility).asyncAfter(
                deadline: .now() + Self.pauseRecoveryInterval,
            ) { [weak self] in
                self?.recoverStalledPause(from: resumeGeneration)
            }
        }

        private func recoverStalledPause(from pauseGeneration: Int) {
            lock.lock()
            guard !didFinish,
                  !cancellationRequested,
                  !isCommitting,
                  waitingForPauseCancellation,
                  generation == pauseGeneration
            else {
                lock.unlock()
                return
            }
            waitingForPauseCancellation = false
            pausingForBackground = false
            foregroundRequested = false
            pausedTask = nil
            lock.unlock()

            startDownload()
        }

        private static func makeBackgroundAssertion() -> BackgroundAssertion? {
            guard Thread.isMainThread else { return nil }
            return MainActor.assumeIsolated {
                BackgroundAssertion(name: "PulseLLMModelDownloadPause")
            }
        }

        private static func endBackgroundAssertion(_ assertion: BackgroundAssertion?) {
            guard let assertion else { return }
            Task { @MainActor in
                assertion.end()
            }
        }
    #else
        private func registerLifecycleObservers() {}
    #endif
}

// MARK: - URLSessionDownloadDelegate

extension LLMModelDownloadOperation: URLSessionDownloadDelegate {
    func urlSession(
        _: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData _: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64,
    ) {
        let expectedBytes = totalBytesExpectedToWrite > 0
            ? totalBytesExpectedToWrite
            : Int64(min(expectedSizeBytes, UInt64(Int64.max)))
        guard expectedBytes > 0 else { return }
        let fraction = min(max(Double(totalBytesWritten) / Double(expectedBytes), 0), 1)

        lock.lock()
        // A straggling callback from a paused task would report stale byte
        // counts and walk the progress bar backwards.
        guard task === downloadTask else {
            lock.unlock()
            return
        }
        let shouldReport = lastReportedProgress.map { previous in
            fraction >= previous + Self.progressReportingStep || (fraction >= 1 && previous < 1)
        } ?? true
        if shouldReport {
            lastReportedProgress = fraction
        }
        let progressHandler = shouldReport ? progressHandler : nil
        lock.unlock()

        progressHandler?(fraction)
    }

    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        lock.lock()
        // A transfer that completed while its cancel was in flight still has a
        // usable file, so accept the paused task here.
        guard task === downloadTask || pausedTask === downloadTask else {
            lock.unlock()
            return
        }
        isCommitting = true
        lock.unlock()

        let partialURL = destinationURL.appendingPathExtension("part")
        do {
            guard let response = downloadTask.response as? HTTPURLResponse else {
                throw LLMModelStoreError.downloadFailed
            }
            guard (200 ..< 300).contains(response.statusCode) else {
                resumeDataStore.remove()
                throw LLMModelStoreError.invalidResponse(response.statusCode)
            }
            // URLSession deletes `location` as soon as this method returns, so
            // the move has to happen inline; only hashing is deferred.
            try? fileManager.removeItem(at: partialURL)
            try fileManager.moveItem(at: location, to: partialURL)
        } catch {
            finish(.failure(error))
            return
        }

        // Hashing 806 MB would block the session delegate queue for seconds.
        DispatchQueue.global(qos: .utility).async { [self] in
            guard isVerifiedModel(at: partialURL) else {
                try? fileManager.removeItem(at: partialURL)
                resumeDataStore.remove()
                finish(.failure(LLMModelStoreError.invalidModel))
                return
            }

            do {
                try? fileManager.removeItem(at: destinationURL)
                try fileManager.moveItem(at: partialURL, to: destinationURL)
                finish(.success(destinationURL))
            } catch {
                finish(.failure(LLMModelStoreError.downloadFailed))
            }
        }
    }

    func urlSession(_: URLSession, task completedTask: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        guard task === completedTask else {
            lock.unlock()
            return
        }
        let isPausing = pausingForBackground
        // Verification of a handed-off file runs asynchronously and owns the
        // outcome; completing here would race it to a spurious failure.
        let hasDownloadedFile = isCommitting
        let wasResumed = startedFromResumeData
        lock.unlock()
        guard !isPausing, !hasDownloadedFile else { return }

        if let error {
            let nsError = error as NSError
            let newResumeData = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
            if let newResumeData {
                resumeDataStore.persist(newResumeData, for: sourceURL)
            } else if wasResumed, !Self.isTransient(error) {
                // The stored partial is what failed, so keeping it would make
                // every retry fail the same way. Transient failures keep it.
                resumeDataStore.remove()
            }
            finish(.failure(map(error: error)))
        } else {
            resumeDataStore.remove()
            finish(.failure(LLMModelStoreError.downloadFailed))
        }
    }

    private func isVerifiedModel(at url: URL) -> Bool {
        guard fileManager.fileExists(atPath: url.path),
              let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber,
              size.uint64Value == expectedSizeBytes
        else {
            return false
        }
        return llmModelFileSHA256(fileManager: fileManager, at: url) == expectedSHA256
    }

    /// Failures that say nothing about the stored partial's validity.
    private static func isTransient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        return [
            .dataNotAllowed,
            .notConnectedToInternet,
            .networkConnectionLost,
            .timedOut,
            .internationalRoamingOff,
            .callIsActive,
        ].contains(urlError.code)
    }

    private func map(error: Error) -> Error {
        guard let urlError = error as? URLError, urlError.code == .dataNotAllowed else {
            return LLMModelStoreError.downloadFailed
        }
        return LLMModelStoreError.networkRestricted
    }

    private func finish(_ result: Result<URL, Error>) {
        lock.lock()
        guard !didFinish else {
            lock.unlock()
            return
        }
        didFinish = true
        let continuationToResume = continuation
        continuation = nil
        let sessionToInvalidate = session
        session = nil
        task = nil
        pausedTask = nil
        waitingForPauseCancellation = false
        foregroundRequested = false
        let observersToRemove = observers
        observers.removeAll()
        lock.unlock()

        for observer in observersToRemove {
            NotificationCenter.default.removeObserver(observer)
        }
        if case .success = result {
            resumeDataStore.remove()
        }
        sessionToInvalidate?.finishTasksAndInvalidate()
        continuationToResume?.resume(with: result)
    }
}
