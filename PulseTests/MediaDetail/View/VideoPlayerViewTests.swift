import Foundation
@testable import Pulse
import Testing

@Suite("VideoPlayerView inline-URL gate")
@MainActor
struct VideoPlayerViewTests {
    @Test(
        "Only HTTPS media URLs are allowed into the inline web view",
        arguments: [
            ("https://cdn.example.com/clip.mp4", true),
            ("https://EXAMPLE.com/clip.mp4", true),
            ("http://cdn.example.com/clip.mp4", false),
            ("HTTP://cdn.example.com/clip.mp4", false),
            ("file:///etc/passwd", false),
            ("ftp://example.com/clip.mp4", false),
            ("javascript:alert(1)", false),
            ("data:text/html,<script>alert(1)</script>", false),
        ],
    )
    func gateAllowsOnlyHTTPS(urlString: String, expected: Bool) throws {
        let url = try #require(URL(string: urlString))
        #expect(VideoPlayerView.isSafeInlineVideoURL(url) == expected)
    }

    @Test(
        "Direct-video navigation is pinned to the originally-loaded HTTPS host",
        arguments: [
            // Same host as loaded → allowed
            ("https://cdn.example.com/clip.mp4", "cdn.example.com", true),
            ("https://CDN.example.com/seek?t=10", "cdn.example.com", true), // host case-insensitive
            // Cross-host redirect (in-WebView phishing) → cancelled
            ("https://attacker.tld/fake-login.html", "cdn.example.com", false),
            // Non-HTTPS navigation → cancelled even if host matches
            ("http://cdn.example.com/clip.mp4", "cdn.example.com", false),
            ("file:///etc/passwd", "cdn.example.com", false),
        ],
    )
    func directVideoNavigationIsHostPinned(urlString: String, host: String, expected: Bool) {
        let url = URL(string: urlString)
        #expect(VideoPlayerView.Coordinator.allowsDirectVideoNavigation(to: url, host: host) == expected)
    }

    @Test("about: bootstrap document is permitted; nil url / nil host are rejected")
    func directVideoNavigationEdgeCases() {
        typealias Policy = VideoPlayerView.Coordinator
        let host = "cdn.example.com"
        #expect(Policy.allowsDirectVideoNavigation(to: URL(string: "about:blank"), host: host))
        #expect(!Policy.allowsDirectVideoNavigation(to: nil, host: host))
        #expect(!Policy.allowsDirectVideoNavigation(to: URL(string: "https://cdn.example.com/x"), host: nil))
    }

    @Test(
        "YouTube-embed navigations are pinned to YouTube / Google origins",
        arguments: [
            // Trusted embed surface → allowed
            ("about:blank", true),
            ("https://www.youtube.com/embed/dQw4w9WgXcQ", true),
            ("https://www.youtube.com/", true),
            ("https://m.youtube.com/watch?v=x", true), // Google-controlled zone: suffix OK
            ("https://www.YOUTUBE.com/embed/x", true), // host case-insensitive
            ("https://www.youtube-nocookie.com/embed/x", true),
            // google.com hosts third-party content: exact-match origins only
            ("https://www.google.com/", true),
            ("https://accounts.google.com/", true),
            ("https://sites.google.com/evil-page", false),
            ("https://script.google.com/macros", false),
            ("https://drive.google.com/file/d/x", false),
            // Redirect to an untrusted origin (JS on) → cancelled
            ("https://attacker.tld/fake-player.html", false),
            // Lookalike domain: dot-anchored suffix must not match
            ("https://notyoutube.com/embed/x", false),
            ("https://evil-youtube.com/", false),
            ("https://google.com.evil.tld/", false),
            // Non-HTTPS → cancelled even for trusted hosts
            ("http://www.youtube.com/embed/x", false),
            ("ftp://www.youtube.com/embed/x", false),
        ],
    )
    func youTubeNavigationIsOriginPinned(urlString: String, expected: Bool) {
        let url = URL(string: urlString)
        #expect(VideoPlayerView.Coordinator.allowsYouTubeNavigation(to: url) == expected)
    }

    @Test("YouTube navigation policy rejects a nil request URL")
    func youTubeNavigationNilURL() {
        #expect(!VideoPlayerView.Coordinator.allowsYouTubeNavigation(to: nil))
    }
}
