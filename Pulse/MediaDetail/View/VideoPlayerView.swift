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

        return webView
    }

    func updateUIView(_ webView: WKWebView, context _: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        var onLoadingStarted: (() -> Void)?
        var onLoadingFinished: (() -> Void)?
        var onError: ((String) -> Void)?

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
            onError?(error.localizedDescription)
        }

        func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
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
