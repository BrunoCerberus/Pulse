import Foundation

/// Central HTTPS-only gate for untrusted media / article URLs.
///
/// `Article.url` and `Article.mediaURL` originate from third-party RSS feeds
/// (the primary untrusted input per `THREAT_MODEL.md` §2) and are handed to
/// privileged loaders — `WKWebView` (`VideoPlayerView`), `AVURLAsset`
/// (`AudioPlayerView`), and `UIApplication.open` (the open-in-browser paths).
/// Every one of those sinks funnels through this single gate so the scheme
/// allowlist can never drift apart between call sites again (the gap that left
/// `AudioPlayerView` ungated while `VideoPlayerView` was HTTPS-gated).
///
/// Only `https` is accepted. `http` (downgrade / plaintext MITM), `file`
/// (local-file read), `javascript:` / `data:` (script injection in a JS-enabled
/// web view), and custom schemes are all rejected. `https` content is further
/// bounded by ATS and, for the web view, the absence of any JS↔Swift bridge.
enum SafeMediaURL {
    /// Parses and validates an untrusted URL string, returning it only when it
    /// uses the `https` scheme. `nil` for anything else (unparseable, `http`,
    /// `file`, custom scheme, …).
    static func validated(_ urlString: String) -> URL? {
        guard let url = URL(string: urlString) else { return nil }
        return validated(url)
    }

    /// Validates an already-parsed URL, returning it only when it uses the
    /// `https` scheme.
    static func validated(_ url: URL) -> URL? {
        isSafe(url) ? url : nil
    }

    /// Whether an already-parsed URL is safe to hand to a privileged loader.
    static func isSafe(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https"
    }
}
