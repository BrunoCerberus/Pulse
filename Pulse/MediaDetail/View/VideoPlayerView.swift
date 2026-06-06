import SwiftUI
import UIKit
import WebKit

/// A WKWebView wrapper for embedding video content (YouTube, etc.).
///
/// This view embeds videos using an HTML iframe with proper configuration
/// for mobile playback, allowing videos to play directly within the app.
struct VideoPlayerView: UIViewRepresentable {
    /// The URL of the video to embed.
    let url: URL

    /// Callback when the web view starts loading.
    var onLoadingStarted: (() -> Void)?

    /// Callback when the web view finishes loading.
    var onLoadingFinished: (() -> Void)?

    /// Callback when an error occurs.
    var onError: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onLoadingStarted: onLoadingStarted,
            onLoadingFinished: onLoadingFinished,
            onError: onError
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.navigationDelegate = context.coordinator

        // Store the initial URL to prevent reloading
        context.coordinator.loadedURL = nil

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Prevent reloading if URL hasn't changed
        guard context.coordinator.loadedURL != url else { return }
        context.coordinator.loadedURL = url

        // Check if it's a YouTube video
        if let videoID = extractYouTubeVideoID(from: url.absoluteString) {
            // Trusted in-app embed HTML, constrained by a strict CSP to YouTube
            // origins. JavaScript stays on for the IFrame Player API.
            context.coordinator.loadMode = .youTube
            let html = createYouTubeEmbedHTML(videoID: videoID)
            webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
        } else if Self.isSafeInlineVideoURL(url) {
            // Non-YouTube direct video: load only over HTTPS. `url` originates from
            // `article.mediaURL` (untrusted third-party RSS), so the coordinator
            // disables JavaScript and pins navigation to this host (see
            // `decidePolicyFor`) — an attacker HTTPS page can't run scripts or
            // redirect into in-WebView phishing. A rejected URL renders nothing.
            context.coordinator.loadMode = .directVideo(host: url.host?.lowercased())
            webView.load(URLRequest(url: url))
        }
    }

    /// Whether an untrusted media URL may be loaded into the inline web view.
    ///
    /// `article.mediaURL` is third-party RSS data, so the inline player applies the
    /// same shared HTTPS-only gate (`SafeMediaURL`) the open-in-browser and audio
    /// paths enforce. Rejects `http`, `file`, and custom schemes. The direct-video
    /// branch additionally disables JavaScript and pins navigation to the loaded
    /// host (see `Coordinator.decidePolicyFor`); `https` content is further bounded
    /// by ATS, the absence of any JS↔Swift message handler, and `load(_:)` not
    /// granting file-system read.
    static func isSafeInlineVideoURL(_ url: URL) -> Bool {
        SafeMediaURL.isSafe(url)
    }

    /// Creates an HTML page with an embedded YouTube iframe using the IFrame Player API.
    private func createYouTubeEmbedHTML(videoID: String) -> String {
        let src = "https://www.youtube.com/embed/\(videoID)?playsinline=1" +
            "&enablejsapi=1&rel=0&modestbranding=1&fs=1"
        let allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; " +
            "picture-in-picture; web-share"

        let ytDomains = "https://www.youtube.com https://www.youtube-nocookie.com"
        let scriptDomains = "\(ytDomains) https://www.google.com"
        let csp = "default-src 'self' \(ytDomains); script-src 'self' \(scriptDomains); " +
            "frame-src \(ytDomains); style-src 'unsafe-inline'"

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="\
        width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <meta http-equiv="Content-Security-Policy" content="\(csp)">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
                .video-container {
                    position: relative;
                    width: 100%;
                    height: 100%;
                }
                iframe {
                    position: absolute;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    border: none;
                }
            </style>
        </head>
        <body>
            <div class="video-container">
                <iframe
                    src="\(src)"
                    allow="\(allow)"
                    allowfullscreen
                    referrerpolicy="strict-origin-when-cross-origin">
                </iframe>
            </div>
        </body>
        </html>
        """
    }

    /// Valid YouTube video ID pattern: 11 characters of alphanumeric, hyphens, and underscores.
    private static let youtubeVideoIDPattern = /^[A-Za-z0-9_-]{11}$/

    /// Extracts YouTube video ID from various URL formats.
    /// Returns nil if the extracted ID doesn't match the expected format.
    private func extractYouTubeVideoID(from urlString: String) -> String? {
        let rawID: String?

        if urlString.contains("youtube.com/watch") {
            // Pattern 1: youtube.com/watch?v=VIDEO_ID (uses URLComponents for safe parsing)
            guard let components = URLComponents(string: urlString) else { return nil }
            rawID = components.queryItems?.first(where: { $0.name == "v" })?.value
        } else if urlString.contains("youtu.be/") {
            // Pattern 2: youtu.be/VIDEO_ID
            guard let components = URLComponents(string: urlString) else { return nil }
            rawID = components.path.split(separator: "/").first.map(String.init)
        } else if urlString.contains("youtube.com/embed/") {
            // Pattern 3: youtube.com/embed/VIDEO_ID
            guard let components = URLComponents(string: urlString) else { return nil }
            let pathParts = components.path.split(separator: "/")
            rawID = pathParts.count >= 2 ? String(pathParts[1]) : nil
        } else {
            return nil
        }

        // Validate video ID format to prevent HTML injection
        guard let id = rawID, id.wholeMatch(of: Self.youtubeVideoIDPattern) != nil else {
            return nil
        }
        return id
    }

    // MARK: - Coordinator

    /// What the web view is currently displaying, which determines the
    /// navigation policy applied in `decidePolicyFor`.
    enum LoadMode: Equatable {
        /// Our own trusted embed HTML, already constrained by a strict CSP to
        /// YouTube origins. JavaScript is required for the IFrame Player API.
        case youTube
        /// An untrusted third-party direct-video URL. JavaScript is disabled and
        /// navigation is pinned to the original host so the page can't run
        /// scripts or redirect into in-WebView phishing.
        case directVideo(host: String?)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var onLoadingStarted: (() -> Void)?
        var onLoadingFinished: (() -> Void)?
        var onError: ((String) -> Void)?

        /// Tracks the currently loaded URL to prevent duplicate loads
        var loadedURL: URL?

        /// Set by `updateUIView` before each load; drives the navigation policy.
        var loadMode: LoadMode = .youTube

        /// Decides whether a navigation is allowed, and with what JavaScript
        /// posture. The trusted YouTube embed keeps JS on (its CSP constrains
        /// it); the untrusted direct-video branch disables JS and pins
        /// navigation to the originally-loaded host.
        func webView(
            _: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            preferences: WKWebpagePreferences,
            decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
        ) {
            switch loadMode {
            case .youTube:
                preferences.allowsContentJavaScript = true
                decisionHandler(.allow, preferences)
            case let .directVideo(host):
                preferences.allowsContentJavaScript = false
                let allowed = Self.allowsDirectVideoNavigation(
                    to: navigationAction.request.url,
                    host: host
                )
                decisionHandler(allowed ? .allow : .cancel, preferences)
            }
        }

        /// Direct-video navigations are pinned to the originally-loaded HTTPS
        /// host. `about:` (the empty bootstrap document) is also permitted; any
        /// cross-host or non-HTTPS navigation is cancelled. Static so the policy
        /// is unit-testable without a live `WKWebView`.
        static func allowsDirectVideoNavigation(to url: URL?, host: String?) -> Bool {
            guard let url else { return false }
            if url.scheme == "about" { return true }
            guard SafeMediaURL.isSafe(url), let host else { return false }
            return url.host?.lowercased() == host
        }

        init(
            onLoadingStarted: (() -> Void)?,
            onLoadingFinished: (() -> Void)?,
            onError: ((String) -> Void)?
        ) {
            self.onLoadingStarted = onLoadingStarted
            self.onLoadingFinished = onLoadingFinished
            self.onError = onError
        }

        func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
            onLoadingStarted?()
        }

        func webView(_: WKWebView, didFinish _: WKNavigation!) {
            onLoadingFinished?()
        }

        func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
            // Ignore cancellation errors (code -999)
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                return
            }
            onError?(error.localizedDescription)
        }

        func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
            // Ignore cancellation errors (code -999)
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                return
            }
            onError?(error.localizedDescription)
        }
    }
}

#Preview {
    VideoPlayerView(url: URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!)
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
        .preferredColorScheme(.dark)
}
