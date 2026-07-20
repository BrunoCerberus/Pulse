import Foundation
@testable import Pulse
import Testing

/// Regression tests for the shared HTTPS-only gate that every untrusted
/// media/article URL sink funnels through (inline video, audio, open-in-browser).
@Suite("SafeMediaURL gate")
struct SafeMediaURLTests {
    @Test(
        "Only HTTPS URLs validate; http/file/javascript/data/custom/scheme-less are rejected",
        arguments: [
            ("https://cdn.example.com/clip.mp4", true),
            ("https://EXAMPLE.com/audio.m4a", true), // scheme compared case-insensitively
            ("HTTPS://example.com/x", true),
            ("http://cdn.example.com/clip.mp4", false),
            ("file:///etc/passwd", false),
            ("javascript:alert(1)", false),
            ("data:text/html,<script>alert(1)</script>", false),
            ("ftp://example.com/clip.mp4", false),
            ("pulse://home", false),
            ("/relative/path.mp4", false), // no scheme
        ],
    )
    func validatesOnlyHTTPS(urlString: String, expected: Bool) {
        #expect((SafeMediaURL.validated(urlString) != nil) == expected)
        if let url = URL(string: urlString) {
            #expect(SafeMediaURL.isSafe(url) == expected)
        }
    }

    @Test("validated returns the same URL it was given when accepted")
    func validatedReturnsSameURL() throws {
        let url = try #require(SafeMediaURL.validated("https://cdn.example.com/a.mp4"))
        #expect(url.absoluteString == "https://cdn.example.com/a.mp4")
    }

    @Test("Unparseable input returns nil rather than crashing")
    func unparseableReturnsNil() {
        #expect(SafeMediaURL.validated("") == nil)
    }
}
