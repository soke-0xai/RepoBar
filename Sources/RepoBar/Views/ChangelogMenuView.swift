import AppKit
import SwiftUI

struct ChangelogMenuView: View {
    let content: ChangelogContent

    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: MenuStyle.submenuIconSpacing) {
                SubmenuIconColumnView {
                    Image(systemName: "doc.text")
                        .symbolRenderingMode(.hierarchical)
                        .font(.caption)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                }

                Text(self.content.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                    .lineLimit(1)

                Text(self.content.source.label)
                    .font(.caption2)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }

            MarkdownPreviewView(
                markdown: self.content.markdown,
                isHighlighted: self.isHighlighted
            )
            .frame(height: MenuStyle.changelogPreviewHeight)

            if self.content.isTruncated {
                Text("Preview truncated")
                    .font(.caption2)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
            }
        }
        .padding(.horizontal, MenuStyle.cardHorizontalPadding)
        .padding(.vertical, MenuStyle.cardVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@MainActor
private struct MarkdownPreviewView: NSViewRepresentable {
    let markdown: String
    let isHighlighted: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView(frame: .zero)
        context.coordinator.textView = textView
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        textView.textStorage?.setAttributedString(self.renderedAttributedString())
        let width = nsView.contentView.bounds.width
        textView.textContainer?.containerSize = NSSize(
            width: max(width, 1),
            height: .greatestFiniteMagnitude
        )
    }

    private func renderedAttributedString() -> NSAttributedString {
        let source = self.normalizedMarkdown
        let parsed: NSMutableAttributedString
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        options.failurePolicy = .returnPartiallyParsedIfPossible
        if let attributed = try? AttributedString(markdown: source, options: options) {
            parsed = NSMutableAttributedString(attributedString: NSAttributedString(attributed))
        } else {
            parsed = NSMutableAttributedString(string: source)
        }

        let baseFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let baseColor = NSColor(MenuHighlightStyle.primary(self.isHighlighted))
        let fullRange = NSRange(location: 0, length: parsed.length)
        parsed.addAttributes([.font: baseFont, .foregroundColor: baseColor], range: fullRange)

        parsed.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
            guard let font = value as? NSFont else { return }
            if font.pointSize > baseFont.pointSize + 2 {
                let clamped = NSFont.systemFont(ofSize: baseFont.pointSize + 1, weight: .semibold)
                parsed.addAttribute(.font, value: clamped, range: range)
            }
        }

        return parsed
    }

    final class Coordinator {
        var textView: NSTextView?
    }

    private var normalizedMarkdown: String {
        self.markdown.replacingOccurrences(of: "\r\n", with: "\n")
    }
}
