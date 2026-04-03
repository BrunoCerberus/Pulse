import Foundation
@testable import Pulse
import Testing

@Suite("String+HTMLStripping Tests")
struct StringHTMLStrippingTests {
    @Test("Strips simple HTML tags")
    func stripsSimpleTags() {
        let html = "<p>Hello world</p>"
        #expect(html.strippingHTML() == "Hello world")
    }

    @Test("Strips nested HTML tags")
    func stripsNestedTags() {
        let html = "<div><p>Hello <strong>world</strong></p></div>"
        #expect(html.strippingHTML() == "Hello world")
    }

    @Test("Strips self-closing tags")
    func stripsSelfClosingTags() {
        let html = "Hello<br/>world"
        #expect(html.strippingHTML() == "Hello world")
    }

    @Test("Decodes HTML entities")
    func decodesHTMLEntities() {
        let html = "Tom &amp; Jerry &lt;3&gt; cats &quot;always&quot; it&#39;s"
        let result = html.strippingHTML()
        #expect(result == "Tom & Jerry <3> cats \"always\" it's")
    }

    @Test("Replaces &nbsp; with space")
    func replacesNbsp() {
        let html = "Hello&nbsp;world"
        #expect(html.strippingHTML() == "Hello world")
    }

    @Test("Collapses multiple whitespace")
    func collapsesWhitespace() {
        let html = "<p>Hello</p>   <p>world</p>"
        #expect(html.strippingHTML() == "Hello world")
    }

    @Test("Trims leading and trailing whitespace")
    func trimsWhitespace() {
        let html = "  <p>Hello world</p>  "
        #expect(html.strippingHTML() == "Hello world")
    }

    @Test("Returns empty string for empty input")
    func emptyInput() {
        #expect("".strippingHTML() == "")
    }

    @Test("Returns plain text unchanged")
    func plainTextUnchanged() {
        let text = "Hello world"
        #expect(text.strippingHTML() == "Hello world")
    }

    @Test("Handles real-world article description with HTML")
    func realWorldDescription() {
        let html = "<ol><li>Breaking news:</li><li>Market &amp; economy update</li></ol>"
        let result = html.strippingHTML()
        #expect(!result.contains("<"))
        #expect(!result.contains(">"))
        #expect(result.contains("Breaking news"))
        #expect(result.contains("Market & economy"))
    }
}
