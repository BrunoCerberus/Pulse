import EntropyCore
import Lottie
import SwiftUI

/**
 * A splash screen view that displays a Lottie animation during app launch.
 *
 * This view shows a glamorous confetti celebration animation with colorful
 * stars and streamers, then transitions to the main app content.
 */
struct SplashScreenView: View {
    /// Callback invoked when the splash animation completes
    var onComplete: () -> Void

    /// Controls whether the animation has finished playing
    @State private var isAnimationComplete = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            meshBackground
                .ignoresSafeArea()

            LottieView(animation: .named("splash_animation"))
                .playing(loopMode: .playOnce)
                .animationSpeed(reduceMotion ? 100.0 : 2.0)
                .animationDidFinish { _ in
                    if reduceMotion {
                        isAnimationComplete = true
                    } else {
                        withAnimation(.easeOut(duration: AnimationTiming.normal)) {
                            isAnimationComplete = true
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        Logger.shared.debug("Animation complete!")
                        onComplete()
                    }
                }
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            logoView
        }
        .opacity(isAnimationComplete ? 0 : 1)
        .onAppear {
            if reduceMotion {
                logoScale = 1.0
                logoOpacity = 1.0
            } else {
                withAnimation(AnimationTiming.springBouncy.delay(0.2)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
            }
        }
    }

    private var meshBackground: some View {
        ZStack {
            Color.black

            LinearGradient(
                colors: [
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.2),
                    Color.black,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var logoView: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)

                Image(systemName: "newspaper.fill")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(.white)
            }
            .glowEffect(color: Color.Accent.primary, radius: 16)

            Text("Pulse")
                .font(Typography.displayMedium)
                .foregroundStyle(.white)
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
    }
}

#Preview {
    SplashScreenView {
        Logger.shared.debug("Animation complete!")
    }
}
