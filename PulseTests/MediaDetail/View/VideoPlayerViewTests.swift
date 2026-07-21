import Foundation
@testable import Pulse
import Testing

@Suite("VideoPlayerView inline-URL gate")
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
}
