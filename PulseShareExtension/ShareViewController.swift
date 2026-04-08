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
                self.sharedURL = url
                self.installRootView(for: url)
            case .failure:
                self.dismissWithError()
            }
        }
    }

    // MARK: - View installation

    private func installRootView(for url: URL) {
        let rootView = ShareRootView(
            url: url,
            onSummarize: { [weak self] in self?.handleSummarize() },
            onCancel: { [weak self] in self?.handleCancel() }
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
        queue.enqueue(item)

        extensionContext?.completeRequest(returningItems: []) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.openHostApp(URL(string: "pulse://shared")!)
            }
        }
    }

    private func handleCancel() {
        extensionContext?.cancelRequest(
            withError: NSError(
                domain: "PulseShareExtension",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "User cancelled."]
            )
        )
    }

    private func dismissWithError() {
        extensionContext?.cancelRequest(
            withError: NSError(
                domain: "PulseShareExtension",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No shareable URL found."]
            )
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
                        if let url = value as? URL { return url }
                        if let urlString = value as? String { return URL(string: urlString) }
                        return nil
                    }()
                    let capturedError = error
                    DispatchQueue.main.async {
                        if let extractedURL {
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

    /// Walks the responder chain to find a `UIApplication` instance and
    /// invokes its `open(_:)` selector. App extensions cannot link
    /// `UIApplication.shared` directly, so the responder-chain trick is the
    /// supported way to open the host app via URL scheme.
    private func openHostApp(_ url: URL) {
        var responder: UIResponder? = self
        let selector = sel_registerName("openURL:")
        while let current = responder {
            if current.responds(to: selector) {
                _ = current.perform(selector, with: url)
                return
            }
            responder = current.next
        }
    }
}

private enum ShareExtensionError: Error {
    case noInputItems
    case noURLAttachment
    case unsupportedAttachment
}
