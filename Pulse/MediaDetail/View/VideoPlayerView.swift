import SwiftUI
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
            let html = createYouTubeEmbedHTML(videoID: videoID)
            webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
        } else {
            // For non-YouTube videos, load the URL directly
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    /// Creates an HTML page with an embedded YouTube iframe using the IFrame Player API.
    private func createYouTubeEmbedHTML(videoID: String) -> String {
        let src = "https://www.youtube.com/embed/\(videoID)?playsinline=1" +
            "&enablejsapi=1&rel=0&modestbranding=1&fs=1"
        let allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; " +
            "picture-in-picture; web-share"

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
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

    /// Extracts YouTube video ID from various URL formats.
    private func extractYouTubeVideoID(from urlString: String) -> String? {
        // Pattern 1: youtube.com/watch?v=VIDEO_ID
        if urlString.contains("youtube.com/watch") {
            guard let components = URLComponents(string: urlString),
                  let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value
            else {
                return nil
            }
            return videoID
        }

        // Pattern 2: youtu.be/VIDEO_ID
        if urlString.contains("youtu.be/") {
            let parts = urlString.components(separatedBy: "youtu.be/")
            if parts.count > 1 {
                // Remove any query parameters
                return parts[1].components(separatedBy: "?").first
            }
        }

        // Pattern 3: youtube.com/embed/VIDEO_ID (already embed format)
        if urlString.contains("youtube.com/embed/") {
            let parts = urlString.components(separatedBy: "youtube.com/embed/")
            if parts.count > 1 {
                return parts[1].components(separatedBy: "?").first
            }
        }

        return nil
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        var onLoadingStarted: (() -> Void)?
        var onLoadingFinished: (() -> Void)?
        var onError: ((String) -> Void)?

        /// Tracks the currently loaded URL to prevent duplicate loads
        var loadedURL: URL?

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
}
