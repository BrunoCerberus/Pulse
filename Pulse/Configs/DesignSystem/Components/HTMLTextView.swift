import SwiftUI
import UIKit

/// A SwiftUI view that renders HTML content with styled formatting.
/// Supports headings, paragraphs, links, blockquotes, lists, and images.
struct HTMLTextView: UIViewRepresentable {
    let html: String
    var textColor: Color = .secondary
    var linkColor: Color = Color.Accent.primary
    var baseFont: UIFont = .systemFont(ofSize: 15, weight: .regular)

    func makeUIView(context _: Context) -> IntrinsicTextView {
        let textView = IntrinsicTextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = []
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }

    func updateUIView(_ uiView: IntrinsicTextView, context _: Context) {
        let resolvedTextColor = UIColor(textColor).resolvedColor(with: uiView.traitCollection)
        let resolvedLinkColor = UIColor(linkColor).resolvedColor(with: uiView.traitCollection)
        uiView.textColor = resolvedTextColor
        uiView.tintColor = resolvedLinkColor
        uiView.attributedText = makeAttributedString(
            html: html,
            baseFont: baseFont,
            textColor: resolvedTextColor,
            linkColor: resolvedLinkColor
        )
        uiView.linkTextAttributes = [
            .foregroundColor: resolvedLinkColor,
            .underlineStyle: 0,
        ]
        uiView.invalidateIntrinsicContentSize()
    }
}

// MARK: - HTML Processing

private extension HTMLTextView {
    func makeAttributedString(
        html: String,
        baseFont: UIFont,
        textColor: UIColor,
        linkColor: UIColor
    ) -> NSAttributedString {
        let wrappedHTML = styledHTML(
            body: html,
            baseFont: baseFont,
            textColor: textColor,
            linkColor: linkColor
        )
        guard let data = wrappedHTML.data(using: .utf8) else {
            return NSAttributedString(string: html)
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        if let attributedString = try? NSMutableAttributedString(
            data: data,
            options: options,
            documentAttributes: nil
        ) {
            return attributedString
        }

        return NSAttributedString(string: stripHTML(from: html))
    }

    // swiftlint:disable:next function_body_length
    func styledHTML(
        body: String,
        baseFont: UIFont,
        textColor: UIColor,
        linkColor: UIColor
    ) -> String {
        let textRGBA = textColor.cssRGBA()
        let linkRGBA = linkColor.cssRGBA()
        let linkWash = linkColor.cssRGBA(alpha: 0.12)
        let dividerWash = linkColor.cssRGBA(alpha: 0.16)
        let baseSize = baseFont.pointSize
        let heading1Size = baseSize * 1.6
        let heading2Size = baseSize * 1.35
        let heading3Size = baseSize * 1.2

        let css = """
        <style>
            :root { color-scheme: light dark; }
            body {
                margin: 0;
                font-family: -apple-system;
                font-size: \(baseSize)px;
                line-height: 1.7;
                color: \(textRGBA);
                letter-spacing: -0.1px;
            }
            p { margin: 0 0 16px 0; }
            h1, h2, h3 {
                margin: 24px 0 12px;
                font-weight: 700;
                letter-spacing: -0.3px;
            }
            h1 { font-size: \(heading1Size)px; }
            h2 { font-size: \(heading2Size)px; }
            h3 { font-size: \(heading3Size)px; }
            a {
                color: \(linkRGBA);
                text-decoration: none;
                font-weight: 600;
            }
            strong { font-weight: 600; }
            blockquote {
                margin: 16px 0;
                padding: 12px 16px;
                border-left: 3px solid \(linkRGBA);
                background: \(linkWash);
                border-radius: 12px;
            }
            ul, ol { margin: 0 0 16px 0; padding-left: 22px; }
            li { margin: 6px 0; }
            hr {
                border: none;
                height: 1px;
                background: \(dividerWash);
                margin: 20px 0;
            }
            img {
                max-width: 100%;
                height: auto;
                border-radius: 12px;
            }
            figure { margin: 0 0 16px 0; }
        </style>
        """

        return """
        <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                \(css)
            </head>
            <body>\(body)</body>
        </html>
        """
    }

    func stripHTML(from html: String) -> String {
        html.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
    }
}

// MARK: - Intrinsic Text View

final class IntrinsicTextView: UITextView {
    override var intrinsicContentSize: CGSize {
        let targetSize = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let size = sizeThatFits(targetSize)
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width > 0 {
            invalidateIntrinsicContentSize()
        }
    }
}

// MARK: - UIColor Extension

private extension UIColor {
    func cssRGBA(alpha: CGFloat? = nil) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var currentAlpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &currentAlpha)

        let resolvedAlpha = alpha ?? currentAlpha
        let redInt = Int(round(red * 255))
        let greenInt = Int(round(green * 255))
        let blueInt = Int(round(blue * 255))

        let alphaString = String(
            format: "%.2f",
            locale: Locale(identifier: "en_US_POSIX"),
            resolvedAlpha
        )
        return "rgba(\(redInt), \(greenInt), \(blueInt), \(alphaString))"
    }
}
