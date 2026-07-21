import EntropyCore
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Principal view controller for the Pulse Share Extension.
///
/// Loads the first shared web URL out of the host extension context,
/// presents `ShareRootView` to confirm the action, and on confirm enqueues
/// the URL into the App Group queue and asks the host to open the main app
/// via the `pulse://shared` URL scheme.
@MainActor
final class ShareViewController: UIViewController {
    private var sharedURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        loadSharedURL { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(url):
                sharedURL = url
                installRootView(for: url)
            case .failure:
                dismissWithError()
            }
        }
    }

    // MARK: - View installation

    private func installRootView(for url: URL) {
        let rootView = ShareRootView(
            url: url,
            onSummarize: { [weak self] in self?.handleSummarize() },
            onCancel: { [weak self] in self?.handleCancel() },
        )
        let host = UIHostingController(rootView: rootView)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        host.didMove(toParent: self)
    }

    // MARK: - Actions

    private func handleSummarize() {
        guard let sharedURL else {
            dismissWithError()
            return
        }
        let item = SharedURLItem(url: sharedURL.absoluteString, sharedAt: Date())
        let queue = SharedURLQueue()
        // If the App Group is misconfigured (e.g. entitlement mismatch on a sideloaded
        // build), `enqueue` returns false rather than throwing. Bail out instead of
        // signalling success to the host — otherwise the user sees the share complete
        // but the main app has nothing to drain.
        guard queue.enqueue(item) else {
            dismissWithError()
            return
        }

        guard let url = URL(string: "pulse://shared") else {
            extensionContext?.completeRequest(returningItems: [])
            return
        }
        openHostApp(url) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: [])
        }
    }

    private func handleCancel() {
        extensionContext?.cancelRequest(
            withError: NSError(
                domain: "PulseShareExtension",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "User cancelled."],
            ),
        )
    }

    private func dismissWithError() {
        extensionContext?.cancelRequest(
            withError: NSError(
                domain: "PulseShareExtension",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No shareable URL found."],
            ),
        )
    }

    // MARK: - URL extraction

    private func loadSharedURL(completion: @escaping @MainActor (Result<URL, Error>) -> Void) {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            completion(.failure(ShareExtensionError.noInputItems))
            return
        }
        let urlTypeIdentifier = UTType.url.identifier
        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments where provider.hasItemConformingToTypeIdentifier(urlTypeIdentifier) {
                provider.loadItem(forTypeIdentifier: urlTypeIdentifier, options: nil) { value, error in
                    // Extract Sendable types before hopping to the main actor —
                    // `value` is `Any?` and cannot be safely sent across isolation.
                    let extractedURL: URL? = {
                        if let url = value as? URL {
                            return url
                        }
                        if let urlString = value as? String {
                            return URL(string: urlString)
                        }
                        return nil
                    }()
                    let capturedError = error
                    DispatchQueue.main.async {
                        if let extractedURL,
                           SharedURLQueue.isAcceptable(urlString: extractedURL.absoluteString)
                        {
                            // Reject `javascript:`, `data:`, `file:`, and custom-scheme URLs
                            // here so the host system never sees an attempt to enqueue them.
                            // The queue itself enforces the same rule as defense in depth.
                            completion(.success(extractedURL))
                        } else if let capturedError {
                            completion(.failure(capturedError))
                        } else {
                            completion(.failure(ShareExtensionError.unsupportedAttachment))
                        }
                    }
                }
                return
            }
        }
        completion(.failure(ShareExtensionError.noURLAttachment))
    }

    // MARK: - Host app launch

    /// Asks the host system to open the containing app via URL scheme.
    /// If the extension point declines the request, the queued URL remains
    /// available and the main app drains it on its next foreground launch.
    private func openHostApp(_ url: URL, completion: @escaping @MainActor @Sendable () -> Void) {
        guard let extensionContext else {
            completion()
            return
        }

        extensionContext.open(url) { success in
            if !success {
                Logger.shared.service("Share Extension: host app open request was declined", level: .warning)
            }
            Task { @MainActor in
                completion()
            }
        }
    }
}

private enum ShareExtensionError: Error {
    case noInputItems
    case noURLAttachment
    case unsupportedAttachment
}
