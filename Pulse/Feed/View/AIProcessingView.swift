import SwiftUI

// MARK: - AI Processing View

struct AIProcessingView: View {
    let phase: AIProcessingPhase
    let streamingText: String
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var statusMessage: String {
        switch phase {
        case let .loading(progress):
            return progress < 0.5 ? "Preparing AI..." : "Almost ready..."
        case .generating:
            return "Crafting your digest..."
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Animated orb
                orbAnimation
                    .frame(height: 200)
                    .padding(.top, Spacing.xl)

                // Status text
                statusSection

                // Streaming text content
                if phase.isGenerating, !streamingText.isEmpty {
                    streamingTextSection
                }

                // Cancel button
                cancelButton
                    .padding(.top, Spacing.md)

                Spacer(minLength: Spacing.xl)
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - Orb Animation

    private var orbAnimation: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.Accent.primary.opacity(0.3),
                            Color.Accent.secondary.opacity(0.1),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 20)

            // Orbiting rings
            ForEach(0 ..< 3, id: \.self) { index in
                OrbitRing(
                    index: index,
                    progress: phase.progress,
                    isGenerating: phase.isGenerating,
                    reduceMotion: reduceMotion
                )
            }

            // Central orb
            CentralOrb(
                progress: phase.progress,
                isGenerating: phase.isGenerating,
                reduceMotion: reduceMotion
            )

            // Floating particles
            if !reduceMotion {
                FloatingParticles(
                    isGenerating: phase.isGenerating
                )
            }
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: Spacing.sm) {
            Text(statusMessage)
                .font(Typography.titleSmall)
                .foregroundStyle(.primary)
                .contentTransition(.interpolate)
                .animation(.easeInOut(duration: 0.3), value: statusMessage)

            if case let .loading(progress) = phase {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(Typography.captionLarge)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: progress)
            }
        }
    }

    // MARK: - Streaming Text Section

    private var streamingTextSection: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: IconSize.sm))
                        .foregroundStyle(Color.Accent.gradient)

                    Text("AI Digest")
                        .font(Typography.labelMedium)
                        .foregroundStyle(.secondary)
                }

                StreamingTextView(text: streamingText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity
        ))
    }

    // MARK: - Cancel Button

    private var cancelButton: some View {
        Button {
            HapticManager.shared.tap()
            onCancel()
        } label: {
            Text("Cancel")
                .font(Typography.labelMedium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
        .pressEffect()
    }
}

// MARK: - Central Orb

private struct CentralOrb: View {
    let progress: Double
    let isGenerating: Bool
    let reduceMotion: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowIntensity: Double = 0.6

    var body: some View {
        ZStack {
            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.Accent.primary.opacity(glowIntensity),
                            Color.Accent.secondary.opacity(glowIntensity * 0.5),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 35
                    )
                )
                .frame(width: 70, height: 70)
                .blur(radius: 8)

            // Main orb
            Circle()
                .fill(Color.Accent.vibrantGradient)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.clear,
                                ],
                                center: UnitPoint(x: 0.35, y: 0.35),
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                )
                .scaleEffect(pulseScale)
                .shadow(color: Color.Accent.primary.opacity(0.5), radius: 15)
        }
        .onAppear {
            guard !reduceMotion else { return }
            startPulseAnimation()
        }
        .onChange(of: isGenerating) { _, newValue in
            guard !reduceMotion else { return }
            if newValue {
                // Intensify animation when generating
                withAnimation(.easeInOut(duration: 0.5)) {
                    glowIntensity = 0.9
                }
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: isGenerating ? 0.8 : 1.2)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = isGenerating ? 1.15 : 1.08
        }
    }
}

// MARK: - Orbit Ring

private struct OrbitRing: View {
    let index: Int
    let progress: Double
    let isGenerating: Bool
    let reduceMotion: Bool

    @State private var rotation: Double = 0

    private var ringSize: CGFloat {
        CGFloat(80 + index * 30)
    }

    private var ringOpacity: Double {
        let base = 0.4 - Double(index) * 0.1
        return isGenerating ? base * 1.5 : base * progress
    }

    private var strokeWidth: CGFloat {
        isGenerating ? 2.5 : 2.0
    }

    private var rotationSpeed: Double {
        let baseSpeed: Double = isGenerating ? 8 : 15
        return baseSpeed + Double(index) * 3
    }

    var body: some View {
        ZStack {
            // Ring outline
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.Accent.primary.opacity(ringOpacity),
                            Color.Accent.secondary.opacity(ringOpacity * 0.5),
                            Color.Accent.tertiary.opacity(ringOpacity * 0.3),
                            Color.clear,
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(rotation))

            // Orbital dot
            if progress > 0.3 || isGenerating {
                Circle()
                    .fill(Color.Accent.primary)
                    .frame(width: 6, height: 6)
                    .shadow(color: Color.Accent.primary.opacity(0.8), radius: 4)
                    .offset(x: ringSize / 2)
                    .rotationEffect(.degrees(rotation * (index % 2 == 0 ? 1 : -1)))
                    .opacity(isGenerating ? 1.0 : progress)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            startRotation()
        }
        .onChange(of: isGenerating) { _, _ in
            guard !reduceMotion else { return }
            // Speed up rotation when generating
            startRotation()
        }
    }

    private func startRotation() {
        withAnimation(
            .linear(duration: rotationSpeed)
                .repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }
    }
}

// MARK: - Floating Particles

private struct FloatingParticles: View {
    let isGenerating: Bool

    @State private var particles: [Particle] = []

    private let particleCount = 8

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.positionX, y: particle.positionY)
                    .opacity(particle.opacity)
                    .blur(radius: 1)
            }
        }
        .onAppear {
            initializeParticles()
            animateParticles()
        }
        .onChange(of: isGenerating) { _, newValue in
            if newValue { intensifyParticles() }
        }
    }

    private func initializeParticles() {
        particles = (0 ..< particleCount).map { index in
            let angle = Double(index) / Double(particleCount) * 2 * .pi
            let radius = CGFloat.random(in: 50 ... 90)
            return Particle(
                id: index,
                positionX: cos(angle) * radius,
                positionY: sin(angle) * radius,
                size: CGFloat.random(in: 3 ... 6),
                opacity: Double.random(in: 0.3 ... 0.7),
                color: [Color.Accent.primary, Color.Accent.secondary, Color.Accent.tertiary].randomElement()!
            )
        }
    }

    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2.0)) {
                for index in particles.indices {
                    let angle = Double.random(in: 0 ... 2 * .pi)
                    let radius = CGFloat.random(in: 50 ... 90)
                    particles[index].positionX = cos(angle) * radius
                    particles[index].positionY = sin(angle) * radius
                    particles[index].opacity = Double.random(in: 0.3 ... 0.7)
                }
            }
        }
    }

    private func intensifyParticles() {
        withAnimation(.easeInOut(duration: 0.5)) {
            for index in particles.indices {
                particles[index].opacity = min(particles[index].opacity * 1.5, 1.0)
                particles[index].size = min(particles[index].size * 1.3, 8)
            }
        }
    }
}

// MARK: - Particle Model

private struct Particle: Identifiable {
    let id: Int
    var positionX: CGFloat
    var positionY: CGFloat
    var size: CGFloat
    var opacity: Double
    var color: Color
}

// MARK: - Preview

#Preview("Loading") { AIProcessingView(phase: .loading(progress: 0.5), streamingText: "", onCancel: {}) }
#Preview("Generating") { AIProcessingView(phase: .generating, streamingText: "AI digest...", onCancel: {}) }
