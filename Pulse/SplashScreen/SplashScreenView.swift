import SwiftUI
import Lottie

struct SplashScreenView: View {
    @State private var isAnimationComplete = false
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, options: .repeating)

                Text("Pulse")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Stay Connected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    SplashScreenView {
        print("Splash complete")
    }
}
