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
        ]
    )
    func gateAllowsOnlyHTTPS(urlString: String, expected: Bool) throws {
        let url = try #require(URL(string: urlString))
        #expect(VideoPlayerView.isSafeInlineVideoURL(url) == expected)
    }
}
