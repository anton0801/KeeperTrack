import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    private let pages = 3

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(AppFont.body())
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // Page content
                TabView(selection: $currentPage) {
                    OnboardingPage1(onTap: {})
                        .tag(0)
                    OnboardingPage2()
                        .tag(1)
                    OnboardingPage3()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentPage)

                // Page indicator + buttons
                VStack(spacing: 24) {
                    HStack(spacing: 10) {
                        ForEach(0..<pages, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.accentGreen : Color.accentGreen.opacity(0.25))
                                .frame(width: i == currentPage ? 28 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    if currentPage < pages - 1 {
                        PrimaryButton("Next", icon: "arrow.right") {
                            withAnimation { currentPage += 1 }
                        }
                        .padding(.horizontal, 32)
                    } else {
                        PrimaryButton("Get Started", icon: "checkmark") {
                            completeOnboarding()
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.4)) {
            appState.hasCompletedOnboarding = true
        }
    }
}

// MARK: - Page 1: Tap to burst animation
struct OnboardingPage1: View {
    let onTap: () -> Void
    @State private var isBursting = false
    @State private var particles: [ParticleData] = []
    @State private var iconScale: CGFloat = 1.0
    @State private var iconGlow: Double = 0

    struct ParticleData: Identifiable {
        let id = UUID()
        var offset: CGSize
        var opacity: Double
        var scale: CGFloat
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Particles
                ForEach(particles) { p in
                    Circle()
                        .fill(Color.accentGreen)
                        .frame(width: 8, height: 8)
                        .scaleEffect(p.scale)
                        .offset(p.offset)
                        .opacity(p.opacity)
                }

                // Interactive icon
                ZStack {
                    Circle()
                        .fill(Color.accentGreen.opacity(0.1 + iconGlow * 0.2))
                        .frame(width: 130, height: 130)
                        .blur(radius: 8)

                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(colors: [.accentGreen, .accentYellow], startPoint: .top, endPoint: .bottom)
                        )
                        .scaleEffect(iconScale)
                }
                .onTapGesture { triggerBurst() }

                Text("Tap to activate")
                    .font(AppFont.caption())
                    .foregroundColor(.textSecondary)
                    .offset(y: 80)
            }
            .frame(height: 250)

            Spacer().frame(height: 40)

            VStack(spacing: 16) {
                Text("Organize your activity")
                    .font(AppFont.title(28))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Keep important goalkeeper data in one place. Record every penalty, every dive, every pattern.")
                    .font(AppFont.body())
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 36)

            Spacer()
        }
    }

    private func triggerBurst() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            iconScale = 1.3
            iconGlow = 1
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1)) {
            iconScale = 1.0
            iconGlow = 0
        }

        particles = (0..<12).map { i in
            let angle = Double(i) / 12.0 * 2 * .pi
            let dist = CGFloat.random(in: 60...120)
            return ParticleData(
                offset: CGSize(width: cos(angle) * dist, height: sin(angle) * dist),
                opacity: 1, scale: CGFloat.random(in: 0.5...1.2)
            )
        }

        withAnimation(.easeOut(duration: 0.6)) {
            particles = particles.map { var p = $0; p.opacity = 0; p.scale = 0.1; return p }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            particles = []
        }
    }
}

// MARK: - Page 2: Drag gesture animation
struct OnboardingPage2: View {
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @GestureState private var gestureOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Goal background
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 200, height: 120)

                ForEach(0..<4) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 196, height: 1)
                        .offset(y: -44 + CGFloat(i) * 30)
                }

                // Draggable ball
                VStack(spacing: 6) {
                    Image(systemName: "soccerball")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, Color(hex: "#CCCCCC")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: Color.accentOrange.opacity(isDragging ? 0.7 : 0.3), radius: isDragging ? 18 : 8)
                        .scaleEffect(isDragging ? 1.15 : 1.0)
                        .offset(dragOffset)
                        .offset(gestureOffset)
                        .gesture(
                            DragGesture()
                                .updating($gestureOffset) { v, s, _ in s = v.translation }
                                .onChanged { _ in withAnimation(.spring(response: 0.2)) { isDragging = true } }
                                .onEnded { v in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        dragOffset = v.predictedEndTranslation.clamped(to: -80...80)
                                        isDragging = false
                                    }
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.8)) {
                                        dragOffset = .zero
                                    }
                                }
                        )
                    Text("← Drag to aim →")
                        .font(AppFont.caption())
                        .foregroundColor(.textSecondary)
                        .offset(y: 50)
                }
            }
            .frame(height: 250)

            Spacer().frame(height: 40)

            VStack(spacing: 16) {
                Text("Track your progress")
                    .font(AppFont.title(28))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Visualize dive patterns, save rates, and weak zones. Real data for real decisions.")
                    .font(AppFont.body())
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 36)

            Spacer()
        }
    }
}

extension CGSize {
    func clamped(to range: ClosedRange<CGFloat>) -> CGSize {
        CGSize(width: max(range.lowerBound, min(range.upperBound, width)),
               height: max(range.lowerBound, min(range.upperBound, height)))
    }
}

// MARK: - Page 3: Scroll-parallax illustration
struct OnboardingPage3: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Animated radial ring (parallax via tap)
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.accentGreen.opacity(glowPulse ? 0.08 + Double(i) * 0.04 : 0.02), lineWidth: 1.5)
                        .frame(width: CGFloat(80 + i * 50), height: CGFloat(80 + i * 50))
                        .scaleEffect(glowPulse ? 1.0 + CGFloat(i) * 0.05 : 1.0)
                        .animation(.easeInOut(duration: 1.6 + Double(i) * 0.3).repeatForever(autoreverses: true), value: glowPulse)
                }

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        miniStat(label: "Save Rate", value: "72%", color: .accentGreen)
                        miniStat(label: "Dives", value: "38", color: .accentOrange)
                    }
                    HStack(spacing: 12) {
                        miniStat(label: "Patterns", value: "5", color: .accentYellow)
                        miniStat(label: "Sessions", value: "12", color: .chartZone)
                    }
                }
                .scaleEffect(0.85)
            }
            .frame(height: 250)
            .onAppear { glowPulse = true }
            .onDisappear { glowPulse = false }

            Spacer().frame(height: 40)

            VStack(spacing: 16) {
                Text("Get useful insights")
                    .font(AppFont.title(28))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Make better tactical decisions with simple, visual data about every goalkeeper you study.")
                    .font(AppFont.body())
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 36)

            Spacer()
        }
    }

    @ViewBuilder
    func miniStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFont.title(22))
                .foregroundColor(color)
            Text(label)
                .font(AppFont.caption(11))
                .foregroundColor(.textSecondary)
        }
        .frame(width: 90, height: 70)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.25), lineWidth: 1))
        )
    }
}
