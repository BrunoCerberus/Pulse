import EntropyCore
import SwiftUI

// MARK: - AI Processing View

struct AIProcessingView: View {
    let phase: AIProcessingPhase
    let streamingText: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let statusMessage = "Crafting your digest..."

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Animated orb
            orbAnimation
                .frame(height: 200)

            // Status text
            statusSection

            // Streaming text content
            if phase.isGenerating, !streamingText.isEmpty {
                streamingTextSection
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
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
        Text(statusMessage)
            .font(Typography.titleSmall)
            .foregroundStyle(.primary)
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
}

// MARK: - Central Orb

private struct CentralOrb: View {
    let progress: Double
    let isGenerating: Bool
    let reduceMotion: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowIntensity: Double = 0.6

    // MARK: - Constants

    private enum Constants {
        static let pulseDurationNormal: Double = 1.2
        static let pulseDurationGenerating: Double = 0.8
        static let pulseScaleNormal: CGFloat = 1.08
        static let pulseScaleGenerating: CGFloat = 1.15
        static let glowIntensityNormal: Double = 0.6
        static let glowIntensityGenerating: Double = 0.9
        static let glowTransitionDuration: Double = 0.5
    }

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
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            startPulseAnimation()
        }
        .onChange(of: isGenerating) { _, newValue in
            guard !reduceMotion else { return }
            if newValue {
                // Intensify animation when generating
                withAnimation(.easeInOut(duration: Constants.glowTransitionDuration)) {
                    glowIntensity = Constants.glowIntensityGenerating
                }
            }
            // Restart animation with new timing
            pulseScale = 1.0
            startPulseAnimation()
        }
    }

    private func startPulseAnimation() {
        let duration = isGenerating ? Constants.pulseDurationGenerating : Constants.pulseDurationNormal
        let scale = isGenerating ? Constants.pulseScaleGenerating : Constants.pulseScaleNormal
        withAnimation(
            .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = scale
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

    // MARK: - Constants

    private enum Constants {
        static let baseRingSize: CGFloat = 80
        static let ringSizeIncrement: CGFloat = 30
        static let baseOpacity: Double = 0.4
        static let opacityDecrement: Double = 0.1
        static let generatingOpacityMultiplier: Double = 1.5
        static let strokeWidthNormal: CGFloat = 2.0
        static let strokeWidthGenerating: CGFloat = 2.5
        static let baseSpeedNormal: Double = 15
        static let baseSpeedGenerating: Double = 8
        static let speedIncrement: Double = 3
        static let orbitalDotVisibilityThreshold: Double = 0.3
    }

    private var ringSize: CGFloat {
        Constants.baseRingSize + CGFloat(index) * Constants.ringSizeIncrement
    }

    private var ringOpacity: Double {
        let base = Constants.baseOpacity - Double(index) * Constants.opacityDecrement
        return isGenerating ? base * Constants.generatingOpacityMultiplier : base * progress
    }

    private var strokeWidth: CGFloat {
        isGenerating ? Constants.strokeWidthGenerating : Constants.strokeWidthNormal
    }

    private var rotationSpeed: Double {
        let baseSpeed = isGenerating ? Constants.baseSpeedGenerating : Constants.baseSpeedNormal
        return baseSpeed + Double(index) * Constants.speedIncrement
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
            if progress > Constants.orbitalDotVisibilityThreshold || isGenerating {
                Circle()
                    .fill(Color.Accent.primary)
                    .frame(width: 6, height: 6)
                    .shadow(color: Color.Accent.primary.opacity(0.8), radius: 4)
                    .offset(x: ringSize / 2)
                    .rotationEffect(.degrees(rotation * (index % 2 == 0 ? 1 : -1)))
                    .opacity(isGenerating ? 1.0 : progress)
            }
        }
        .accessibilityHidden(true)
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
        .accessibilityHidden(true)
        .onAppear {
            initializeParticles()
        }
        .task {
            await animateParticles()
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
                color: [Color.Accent.primary, Color.Accent.secondary, Color.Accent.tertiary]
                    .randomElement() ?? Color.Accent.primary
            )
        }
    }

    private func animateParticles() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2))
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

#Preview("Generating") { AIProcessingView(phase: .generating, streamingText: "") }
#Preview("With Text") { AIProcessingView(phase: .generating, streamingText: "AI digest content streaming...") }
