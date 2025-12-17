import SwiftUI

struct ArticleSkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                SkeletonLine(width: 60, height: 12)
                SkeletonLine(width: .infinity, height: 18)
                SkeletonLine(width: 200, height: 18)
                SkeletonLine(width: .infinity, height: 14)
                SkeletonLine(width: 150, height: 12)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: 100, height: 100)
                .shimmer(isAnimating: isAnimating)
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct SkeletonLine: View {
    let width: CGFloat?
    let height: CGFloat

    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }

    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.quaternary)
            .frame(maxWidth: width == .infinity ? .infinity : width, minHeight: height, maxHeight: height)
            .shimmer(isAnimating: isAnimating)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
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
