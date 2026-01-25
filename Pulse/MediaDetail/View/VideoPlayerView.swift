import SwiftUI
import WebKit

/// A WKWebView wrapper for embedding video content (YouTube, etc.).
///
/// This view embeds the video URL in a WKWebView with inline playback enabled,
/// allowing videos to play directly within the app without redirecting to Safari.
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
        let embedURL = convertToEmbedURL(url)
        guard context.coordinator.loadedURL != embedURL else { return }

        context.coordinator.loadedURL = embedURL
        let request = URLRequest(url: embedURL)
        webView.load(request)
    }

    /// Converts a regular video URL to an embeddable format.
    /// - YouTube watch URLs are converted to embed URLs
    /// - Other URLs are returned as-is
    private func convertToEmbedURL(_ url: URL) -> URL {
        let urlString = url.absoluteString

        // Handle YouTube watch URLs
        // Formats: youtube.com/watch?v=VIDEO_ID, youtu.be/VIDEO_ID, www.youtube.com/watch?v=VIDEO_ID
        if let videoID = extractYouTubeVideoID(from: urlString) {
            let embedURLString = "https://www.youtube.com/embed/\(videoID)?playsinline=1&autoplay=0"
            if let embedURL = URL(string: embedURLString) {
                return embedURL
            }
        }

        return url
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
            return nil // Already in embed format
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
