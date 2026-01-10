import SwiftUI

struct ArticleSkeletonView: View {
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                SkeletonLine(width: 60, height: 12, isAnimating: isAnimating)
                SkeletonLine(width: .infinity, height: 18, isAnimating: isAnimating)
                SkeletonLine(width: 200, height: 18, isAnimating: isAnimating)
                SkeletonLine(width: .infinity, height: 14, isAnimating: isAnimating)
                SkeletonLine(width: 150, height: 12, isAnimating: isAnimating)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: 100, height: 100)
                .shimmer(isAnimating: isAnimating)
        }
        .padding()
        .onAppear {
            if reduceMotion {
                isAnimating = false
            } else {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
        .onDisappear {
            if reduceMotion {
                isAnimating = false
            } else {
                withAnimation(.linear(duration: 0.1)) {
                    isAnimating = false
                }
            }
        }
    }
}

struct SkeletonLine: View {
    let width: CGFloat?
    let height: CGFloat
    let isAnimating: Bool

    init(width: CGFloat, height: CGFloat, isAnimating: Bool = false) {
        self.width = width
        self.height = height
        self.isAnimating = isAnimating
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.quaternary)
            .frame(maxWidth: width == .infinity ? .infinity : width, minHeight: height, maxHeight: height)
            .shimmer(isAnimating: isAnimating)
    }
}

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        opacity(isAnimating ? 0.5 : 1.0)
    }
}

#Preview {
    VStack {
        ArticleSkeletonView()
        ArticleSkeletonView()
        ArticleSkeletonView()
    }
}
