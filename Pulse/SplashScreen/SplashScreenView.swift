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

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            LottieView(animation: .named("splash_animation"))
                .playing(loopMode: .playOnce)
                .animationSpeed(2.0)
                .animationDidFinish { _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        isAnimationComplete = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onComplete()
                    }
                }
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Text("Pulse")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .opacity(isAnimationComplete ? 0 : 1)
    }
}

#Preview {
    SplashScreenView {
        print("Animation complete!")
    }
}
