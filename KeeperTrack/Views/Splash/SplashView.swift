import SwiftUI
import Combine
import Network

enum PenaltyPhase {
    case ballIdle
    case approach
    case kick
    case saved
    case scored
    case reset
}

struct SplashView: View {
    // ── Intro (один раз) ──────────────────────────────────────────
    @State private var bgOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 24
    @State private var titleOpacity: Double = 0
    @StateObject private var viewModel = KeeperTrackViewModel()
    @State private var goalOpacity: Double = 0
    @State private var goalScale: CGFloat = 0.85
    
    // ── Penalty loop ──────────────────────────────────────────────
    @State private var phase: PenaltyPhase = .ballIdle
    @State private var isLooping = false
    
    // Ball
    @State private var ballX: CGFloat = 0
    @State private var ballY: CGFloat = 0
    @State private var ballScale: CGFloat = 1.0
    @State private var ballRotation: Double = 0
    @State private var networkMonitor = NWPathMonitor()
    @State private var ballOpacity: Double = 0
    
    // Keeper
    @State private var keeperX: CGFloat = 0
    @State private var keeperY: CGFloat = 0
    @State private var keeperScale: CGFloat = 1.0
    @State private var keeperRotation: Double = 0
    
    // Effects
    @State private var netShakeX: CGFloat = 0
    @State private var flashOpacity: Double = 0
    @State private var flashColor: Color = .accentGreen
    @State private var cancellables = Set<AnyCancellable>()
    @State private var resultText: String = ""
    @State private var resultOpacity: Double = 0
    @State private var resultScale: CGFloat = 0.6
    
    // Stadium pulse
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0
    
    // Exit
    @State private var exitOpacity: Double = 1.0
    @State private var exitScale: CGFloat = 1.0
    
    // Рандомные переменные текущего пенальти
    @State private var targetX: CGFloat = 0      // куда летит мяч (-1 лево, 0 центр, 1 право)
    @State private var keeperGoesRight: Bool = true
    @State private var willScore: Bool = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // ── Фон ──────────────────────────────────────────────
                LinearGradient(
                    colors: [Color(hex: "#030d06"), Color(hex: "#0a1f0e"), Color(hex: "#060f08")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
                .opacity(bgOpacity)
                
                NavigationLink(
                    destination: KeeperTrackWebView().navigationBarHidden(true),
                    isActive: $viewModel.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $viewModel.navigateToMain
                ) { EmptyView() }
                
                // Stadium pulse glow
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.accentGreen.opacity(pulseOpacity), .clear],
                        center: .center, startRadius: 10, endRadius: 280
                    ))
                    .frame(width: 560, height: 560)
                    .scaleEffect(pulseScale)
                    .allowsHitTesting(false)
                
                // ── Goal frame ────────────────────────────────────────
                GeometryReader { geo in
                    let cx = geo.size.width / 2
                    let cy = geo.size.height * 0.38
                    
                    ZStack {
                        // Поле / трава
                        Ellipse()
                            .fill(RadialGradient(
                                colors: [Color(hex: "#14532D").opacity(0.35), .clear],
                                center: .center, startRadius: 10, endRadius: 220
                            ))
                            .frame(width: 360, height: 60)
                            .position(x: cx, y: cy + 118)
                        
                        // Сетка ворот
                        GoalNetView(shakeX: netShakeX)
                            .frame(width: 240, height: 140)
                            .position(x: cx, y: cy)
                            .opacity(goalOpacity)
                            .scaleEffect(goalScale, anchor: .top)
                        
                        // Flash overlay (гол/сейв)
                        RoundedRectangle(cornerRadius: 0)
                            .fill(flashColor.opacity(flashOpacity))
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                        
                        // Вратарь
                        KeeperFigure(
                            isDiv: phase == .saved,
                            goesRight: keeperGoesRight
                        )
                        .frame(width: 54, height: 60)
                        .scaleEffect(x: keeperGoesRight ? 1 : -1, y: 1)
                        .scaleEffect(keeperScale)
                        .rotationEffect(.degrees(keeperRotation))
                        .position(x: cx + keeperX, y: cy + keeperY)
                        .opacity(goalOpacity)
                        
                        // Мяч
                        BallView(rotation: ballRotation)
                            .frame(width: 28, height: 28)
                            .scaleEffect(ballScale)
                            .position(x: cx + ballX, y: cy + ballY)
                            .opacity(ballOpacity)
                        
                        // Текст результата
                        Text(resultText)
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(resultText == "GOAL" ? .accentOrange : .accentGreen)
                            .tracking(4)
                            .scaleEffect(resultScale)
                            .opacity(resultOpacity)
                            .position(x: cx, y: cy - 90)
                            .shadow(color: (resultText == "GOAL" ? Color.accentOrange : Color.accentGreen).opacity(0.6), radius: 16)
                    }
                }
                
                // ── Лого + заголовок (внизу) ──────────────────────────
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.accentGreen.opacity(0.1))
                                .frame(width: 64, height: 64)
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(colors: [.accentGreen, .accentYellow],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        
                        Text("KEEPER TRACK")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .tracking(5)
                            .offset(y: titleOffset)
                            .opacity(titleOpacity)
                        
                        Text("Smart Penalty Analysis")
                            .font(AppFont.body(13))
                            .foregroundColor(.textSecondary)
                            .tracking(1.5)
                            .opacity(titleOpacity)
                    }
                    .padding(.bottom, 56)
                }
            }
            .opacity(exitOpacity)
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                KeeperTrackConsentView(viewModel: viewModel)
            }
            .scaleEffect(exitScale)
            .onDisappear { isLooping = false; resetAll() }
            .fullScreenCover(isPresented: $viewModel.showOfflineView) {
                OfflineView()
            }
            .onAppear {
                setupStreams()
                startIntro()
                setupNetworkMonitoring()
                viewModel.boot()
            }
        }
    }
    
    private func startIntro() {
        // Фон
        withAnimation(.easeOut(duration: 0.5)) { bgOpacity = 1 }
        
        // Pulse start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.15; pulseOpacity = 0.12
            }
        }
        
        // Ворота
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                goalOpacity = 1; goalScale = 1.0
            }
        }
        
        // Лого
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.68)) {
                logoScale = 1.0; logoOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.15)) {
                titleOffset = 0; titleOpacity = 1
            }
        }
        
        // Мяч появляется
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            ballX = 0; ballY = 130
            withAnimation(.easeIn(duration: 0.3)) { ballOpacity = 1 }
        }
        
        // Запуск петли пенальти
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            isLooping = true
            runPenaltyCycle()
        }
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestAttribution(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestDeeplinks(data)
            }
            .store(in: &cancellables)
    }
    
    private func runPenaltyCycle() {
        guard isLooping else { return }
        
        // Рандомизируем сценарий
        let zones: [CGFloat] = [-75, -30, 0, 30, 75]
        targetX = zones.randomElement()!
        willScore = Bool.random()
        // вратарь прыгает туда же куда летит мяч если сейв, иначе — в другую сторону
        if willScore {
            keeperGoesRight = targetX > 0 ? false : true   // прыгает не туда
        } else {
            keeperGoesRight = targetX >= 0                  // прыгает туда же
        }
        
        // Сброс позиций
        ballX = 0; ballY = 130; ballScale = 1.0; ballRotation = 0
        keeperX = 0; keeperY = 0; keeperRotation = 0; keeperScale = 1.0
        netShakeX = 0
        resultOpacity = 0; resultScale = 0.6; resultText = ""
        phase = .ballIdle
        
        // ── Фаза 1: Idle (мяч на точке, лёгкое покачивание) 0–0.4s
        withAnimation(.easeInOut(duration: 0.18).repeatCount(2, autoreverses: true)) {
            ballY = 127
        }
        
        // ── Фаза 2: Разбег (0.4–0.7s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard isLooping else { return }
            phase = .approach
            withAnimation(.easeIn(duration: 0.15)) { ballScale = 1.08 }
        }
        
        // ── Фаза 3: Удар (0.7s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            guard isLooping else { return }
            phase = .kick
            
            // Мяч летит в ворота
            let destY: CGFloat = willScore ? -48 : -38
            let destScale: CGFloat = willScore ? 0.45 : 0.42
            withAnimation(.easeOut(duration: 0.38)) {
                ballX = targetX
                ballY = destY
                ballScale = destScale
            }
            withAnimation(.linear(duration: 0.38)) {
                ballRotation = willScore ? 540 : 360
            }
            
            // Вратарь прыгает
            let keeperDestX: CGFloat = keeperGoesRight ? 72 : -72
            let keeperDestY: CGFloat = -18
            withAnimation(.spring(response: 0.32, dampingFraction: 0.62).delay(0.06)) {
                keeperX = keeperDestX
                keeperY = keeperDestY
                keeperRotation = keeperGoesRight ? 18 : -18
            }
        }
        
        // ── Фаза 4: Результат (1.1s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.08) {
            guard isLooping else { return }
            
            if willScore {
                // ГОЛ
                phase = .scored
                resultText = "GOAL"
                flashColor = Color.accentOrange
                withAnimation(.easeOut(duration: 0.12)) { flashOpacity = 0.22 }
                withAnimation(.easeIn(duration: 0.25).delay(0.12)) { flashOpacity = 0 }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                    resultScale = 1.0; resultOpacity = 1
                }
                // Сетка трясётся
                withAnimation(.spring(response: 0.08, dampingFraction: 0.3)) { netShakeX = 6 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) { netShakeX = -4 }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.12, dampingFraction: 0.4)) { netShakeX = 0 }
                }
            } else {
                // СЕЙВ
                phase = .saved
                resultText = "SAVED"
                flashColor = Color.accentGreen
                withAnimation(.easeOut(duration: 0.12)) { flashOpacity = 0.18 }
                withAnimation(.easeIn(duration: 0.25).delay(0.12)) { flashOpacity = 0 }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                    resultScale = 1.0; resultOpacity = 1
                }
                // Мяч отскакивает
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5).delay(0.05)) {
                    ballX = targetX * 0.4
                    ballY = -10
                    ballScale = 0.55
                }
            }
        }
        
        // ── Фаза 5: Текст исчезает (1.7s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
            guard isLooping else { return }
            withAnimation(.easeIn(duration: 0.25)) { resultOpacity = 0 }
        }
        
        // ── Фаза 6: Сброс и новый пенальти (2.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            guard isLooping else { return }
            phase = .reset
            withAnimation(.easeInOut(duration: 0.3)) {
                ballX = 0; ballY = 130; ballScale = 1.0; ballRotation = 0
                keeperX = 0; keeperY = 0; keeperRotation = 0; keeperScale = 1.0
                netShakeX = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                runPenaltyCycle()
            }
        }
    }
    
    private func resetAll() {
        bgOpacity = 0; logoScale = 0.4; logoOpacity = 0
        titleOffset = 24; titleOpacity = 0; goalOpacity = 0; goalScale = 0.85
        ballOpacity = 0; ballX = 0; ballY = 130
        keeperX = 0; keeperY = 0; keeperRotation = 0
        pulseScale = 1.0; pulseOpacity = 0
        flashOpacity = 0; resultOpacity = 0
        exitOpacity = 1.0; exitScale = 1.0
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                viewModel.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
}

// MARK: - Goal Net
struct GoalNetView: View {
    let shakeX: CGFloat

    var body: some View {
        ZStack {
            // Сетка — горизонтальные линии
            ForEach(0..<5) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)
                    .offset(y: -55 + CGFloat(i) * 28)
            }
            // Вертикальные линии
            ForEach(0..<7) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1)
                    .offset(x: -112 + CGFloat(i) * 37)
            }
            // Штанги
            Rectangle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 2)
                .offset(x: -119)
            Rectangle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 2)
                .offset(x: 119)
            // Перекладина
            Rectangle()
                .fill(Color.white.opacity(0.55))
                .frame(height: 2)
                .offset(y: -69)
        }
        .offset(x: shakeX)
        .clipped()
    }
}

// MARK: - Ball
struct BallView: View {
    let rotation: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .shadow(color: Color.accentOrange.opacity(0.45), radius: 8)
            // Пятиугольники имитация
            Image(systemName: "soccerball")
                .resizable()
                .scaledToFit()
                .foregroundColor(.clear)
                .overlay(
                    Image(systemName: "soccerball")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(hex: "#1a1a1a").opacity(0.85))
                )
        }
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Keeper Figure (SF Symbols based)
struct KeeperFigure: View {
    let isDiv: Bool
    let goesRight: Bool

    var body: some View {
        ZStack {
            if isDiv {
                // Прыжок
                Image(systemName: "figure.handball")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(
                        LinearGradient(colors: [Color.accentGreen, Color(hex: "#16A34A")],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .rotationEffect(.degrees(goesRight ? -35 : 35))
            } else {
                // Стоит
                Image(systemName: "figure.stand")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(
                        LinearGradient(colors: [Color.accentGreen, Color(hex: "#16A34A")],
                                       startPoint: .top, endPoint: .bottom)
                    )
            }
        }
        .shadow(color: Color.accentGreen.opacity(0.5), radius: 10)
    }
}
