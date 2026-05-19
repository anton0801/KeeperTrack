import SwiftUI

struct SplashView: View {
    @Binding var isVisible: Bool

    // Phase 1: background
    @State private var bgOpacity: Double = 0
    @State private var bgScale: CGFloat = 1.1
    // Phase 2: field lines animation
    @State private var fieldLineOffset: CGFloat = 60
    @State private var fieldLineOpacity: Double = 0
    // Looping stadium pulse
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.15
    // Ball trajectory
    @State private var ballOffset: CGFloat = 120
    @State private var ballOpacity: Double = 0
    @State private var ballRotation: Double = 0
    // Keeper dive
    @State private var keeperOffset: CGFloat = -60
    @State private var keeperOpacity: Double = 0
    @State private var keeperScale: CGFloat = 0.6
    // Phase 3: logo
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var subtitleOpacity: Double = 0
    // Exit
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#052E16"), Color(hex: "#14532D"), Color(hex: "#0A2417")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .scaleEffect(bgScale)
            .opacity(bgOpacity)

            // Stadium glow pulse
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.accentGreen.opacity(pulseOpacity), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 220
                    )
                )
                .frame(width: 440, height: 440)
                .scaleEffect(pulseScale)

            // Field lines (goal post)
            GoalPostView()
                .opacity(fieldLineOpacity)
                .offset(y: fieldLineOffset)

            // Animated ball
            Image(systemName: "soccerball")
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(colors: [.white, Color(hex: "#D4D4D4")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .rotationEffect(.degrees(ballRotation))
                .offset(x: ballOffset, y: -30)
                .opacity(ballOpacity)
                .shadow(color: Color.accentOrange.opacity(0.6), radius: 12)

            // Keeper
            Image(systemName: "figure.handball")
                .font(.system(size: 52))
                .foregroundStyle(
                    LinearGradient(colors: [Color.accentGreen, Color(hex: "#16A34A")], startPoint: .top, endPoint: .bottom)
                )
                .offset(x: keeperOffset, y: 20)
                .scaleEffect(keeperScale)
                .opacity(keeperOpacity)
                .shadow(color: Color.accentGreen.opacity(0.5), radius: 16)

            // Logo + title
            VStack(spacing: 10) {
                Spacer()
                    .frame(height: 200)

                ZStack {
                    Circle()
                        .fill(Color.accentGreen.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [Color.accentGreen, Color.accentYellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Text("KEEPER TRACK")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .tracking(4)
                    .offset(y: titleOffset)
                    .opacity(logoOpacity)

                Text("Smart Penalty Analysis")
                    .font(AppFont.body(14))
                    .foregroundColor(.textSecondary)
                    .tracking(1.5)
                    .opacity(subtitleOpacity)
            }

        }
        .opacity(exitOpacity)
        .scaleEffect(exitScale)
        .onAppear { startAnimation() }
        .onDisappear { resetAnimations() }
    }

    private func startAnimation() {
        // Phase 1: background builds in (0–0.6s)
        withAnimation(.easeOut(duration: 0.6)) {
            bgOpacity = 1
            bgScale = 1.0
        }

        // Start looping pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
                pulseOpacity = 0.08
            }
        }

        // Phase 2: field lines + ball + keeper animate in (0.6–1.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                fieldLineOpacity = 1
                fieldLineOffset = 0
            }

            withAnimation(.easeIn(duration: 0.5)) {
                ballOpacity = 1
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                ballOffset = -80
            }
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                ballRotation = 360
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.2)) {
                keeperOpacity = 1
                keeperOffset = 50
                keeperScale = 1.0
            }
        }

        // Phase 3: logo + title appear (1.4–2.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                logoScale = 1.0
                logoOpacity = 1
                titleOffset = 0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.2)) {
                subtitleOpacity = 1
            }
        }

        // Phase 4: exit (2.5s) — logo scales up and fades
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            withAnimation(.easeIn(duration: 0.45)) {
                exitScale = 1.15
                exitOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isVisible = false
            }
        }
    }

    private func resetAnimations() {
        bgOpacity = 0; bgScale = 1.1
        fieldLineOffset = 60; fieldLineOpacity = 0
        pulseScale = 1.0; pulseOpacity = 0.15
        ballOffset = 120; ballOpacity = 0; ballRotation = 0
        keeperOffset = -60; keeperOpacity = 0; keeperScale = 0.6
        logoScale = 0.3; logoOpacity = 0; titleOffset = 30; subtitleOpacity = 0
        exitScale = 1.0; exitOpacity = 1.0
    }
}

struct GoalPostView: View {
    var body: some View {
        ZStack {
            // Goal frame
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.25), lineWidth: 2)
                .frame(width: 200, height: 110)
                .offset(y: -20)

            // Net lines horizontal
            ForEach(0..<5) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 196, height: 1)
                    .offset(y: -65 + CGFloat(i) * 22)
            }
            // Net lines vertical
            ForEach(0..<7) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 1, height: 106)
                    .offset(x: -99 + CGFloat(i) * 33, y: -20)
            }

            // Penalty spot
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 6, height: 6)
                .offset(y: 70)

            // D-arc
            Path { p in
                p.addArc(center: CGPoint(x: 100, y: 0), radius: 40, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            }
            .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
            .frame(width: 200, height: 40)
            .offset(y: 52)
        }
        .offset(y: 40)
    }
}
