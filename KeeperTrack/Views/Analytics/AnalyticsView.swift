import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var keeperStore: KeeperStore
    @EnvironmentObject var penaltyStore: PenaltyStore
    @State private var selectedPeriod: Period = .allTime
    @State private var selectedKeeperID: UUID?
    @State private var animateIn = false

    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
    }

    private var analytics: AnalyticsSummary {
        selectedKeeperID != nil
            ? penaltyStore.analytics(for: selectedKeeperID!)
            : penaltyStore.globalAnalytics()
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Header ────────────────────────────────
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Analytics")
                                    .font(AppFont.title(28))
                                    .foregroundColor(.textPrimary)
                                Text(selectedKeeperID.flatMap { id in keeperStore.keepers.first { $0.id == id }?.name } ?? "All Keepers")
                                    .font(AppFont.body(13))
                                    .foregroundColor(.accentGreen)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // ── Keeper filter pills ───────────────────
                        if !keeperStore.keepers.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    keeperPill(name: "Global", id: nil)
                                    ForEach(keeperStore.keepers) { k in
                                        keeperPill(name: k.name, id: k.id)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        // ── Period picker ─────────────────────────
                        HStack(spacing: 0) {
                            ForEach(Period.allCases, id: \.self) { p in
                                Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selectedPeriod = p } }) {
                                    Text(p.rawValue)
                                        .font(AppFont.body(14))
                                        .foregroundColor(selectedPeriod == p ? .bgDark : .textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedPeriod == p ? Color.accentGreen : Color.clear))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.bgStadium.opacity(0.5)))
                        .padding(.horizontal, 16)

                        // ── Big save rate hero ────────────────────
                        SaveRateHeroCard(analytics: analytics, animateIn: animateIn)
                            .padding(.horizontal, 16)

                        // ── 3-col mini stats ──────────────────────
                        HStack(spacing: 10) {
                            miniStat(value: "\(analytics.saves)", label: "Saves", color: .accentGreen)
                            miniStat(value: "\(analytics.scored)", label: "Scored", color: .chartMiss)
                            miniStat(value: "\(analytics.missed)", label: "Missed", color: .accentYellow)
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 16)

                        // ── Weekly bar chart ──────────────────────
                        AnimatedBarChart(points: analytics.weeklyData)
                            .padding(.horizontal, 16)

                        // ── Dive split ────────────────────────────
                        DiveSplitCard(analytics: analytics, animateIn: animateIn)
                            .padding(.horizontal, 16)

                        // ── Zone heat strip ───────────────────────
                        ZoneHeatStrip(analytics: analytics, animateIn: animateIn)
                            .padding(.horizontal, 16)

                        // ── Zone table ────────────────────────────
                        ZoneTableCard(analytics: analytics)
                            .padding(.horizontal, 16)

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.12)) {
                animateIn = true
            }
        }
    }

    @ViewBuilder
    func keeperPill(name: String, id: UUID?) -> some View {
        let sel = selectedKeeperID == id
        Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedKeeperID = id } }) {
            Text(name)
                .font(AppFont.body(13))
                .foregroundColor(sel ? .bgDark : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(sel ? Color.accentGreen : Color.bgStadium.opacity(0.5)))
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(AppFont.caption(11))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1))
        )
    }
}

// MARK: - Save Rate Hero Card
struct SaveRateHeroCard: View {
    let analytics: AnalyticsSummary
    let animateIn: Bool

    @State private var ringProgress: Double = 0
    @State private var glowPulse = false

    private var saves: Double { Double(analytics.saves) }
    private var total: Double { Double(analytics.totalPenalties) }
    private var scored: Double { Double(analytics.scored) }
    private var missed: Double { Double(analytics.missed) }

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [Color.bgStadium.opacity(0.6), Color.bgDark.opacity(0.8)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.accentGreen.opacity(0.18), lineWidth: 1))

            // Glow behind ring
            Circle()
                .fill(RadialGradient(
                    colors: [Color.accentGreen.opacity(glowPulse ? 0.16 : 0.08), .clear],
                    center: .center, startRadius: 10, endRadius: 100
                ))
                .frame(width: 200, height: 200)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowPulse)

            HStack(spacing: 28) {
                // Ring
                ZStack {
                    // Track
                    Circle()
                        .stroke(Color.bgDark.opacity(0.6), lineWidth: 14)
                        .frame(width: 140, height: 140)

                    // Missed arc (yellow, outermost)
                    if total > 0 {
                        Circle()
                            .trim(from: 0, to: ringProgress * missed / total)
                            .stroke(Color.accentYellow, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))

                        // Scored arc (red)
                        Circle()
                            .trim(from: ringProgress * missed / total,
                                  to: ringProgress * (missed + scored) / total)
                            .stroke(Color.chartMiss, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))

                        // Saved arc (green)
                        Circle()
                            .trim(from: ringProgress * (missed + scored) / total,
                                  to: ringProgress)
                            .stroke(
                                LinearGradient(colors: [Color.accentGreen, Color(hex: "#4ade80")],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                    }

                    // Center
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f%%", analytics.saveRate))
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [.accentGreen, .accentYellow],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                        Text("save rate")
                            .font(AppFont.caption(11))
                            .foregroundColor(.textSecondary)
                    }
                }
                .onAppear {
                    glowPulse = true
                    withAnimation(.easeOut(duration: 1.1).delay(0.25)) {
                        ringProgress = 1.0
                    }
                }
                .onDisappear { ringProgress = 0; glowPulse = false }

                // Legend
                VStack(alignment: .leading, spacing: 14) {
                    legendRow(color: .accentGreen, label: "Saved", count: analytics.saves, total: analytics.totalPenalties)
                    legendRow(color: .chartMiss, label: "Scored", count: analytics.scored, total: analytics.totalPenalties)
                    legendRow(color: .accentYellow, label: "Missed", count: analytics.missed, total: analytics.totalPenalties)

                    Divider().background(Color.accentGreen.opacity(0.15)).padding(.top, 4)

                    HStack {
                        Text("Total")
                            .font(AppFont.caption(12))
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text("\(analytics.totalPenalties)")
                            .font(AppFont.mono(14))
                            .foregroundColor(.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }

    @ViewBuilder
    func legendRow(color: Color, label: String, count: Int, total: Int) -> some View {
        let pct = total > 0 ? Double(count) / Double(total) * 100 : 0
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(AppFont.body(13))
                .foregroundColor(.textSecondary)
            Spacer()
            Text(String(format: "%.0f%%", pct))
                .font(AppFont.mono(13))
                .foregroundColor(color)
        }
    }
}

// MARK: - Animated Bar Chart
struct AnimatedBarChart: View {
    let points: [AnalyticsSummary.WeeklyPoint]
    @State private var heights: [Double] = []
    @State private var appeared = false

    private var maxTotal: Int { points.map { $0.total }.max() ?? 1 }

    var body: some View {
        AppCard {
            VStack(spacing: 16) {
                SectionHeader(title: "Weekly Progress")

                GeometryReader { geo in
                    let barW = max(16, (geo.size.width - CGFloat(max(1, points.count - 1)) * 10) / CGFloat(max(1, points.count)))
                    HStack(alignment: .bottom, spacing: 10) {
                        ForEach(Array(points.enumerated()), id: \.element.id) { idx, point in
                            let totalH = point.total > 0
                                ? CGFloat(point.total) / CGFloat(maxTotal) * 110
                                : 4
                            let saveH = point.total > 0
                                ? CGFloat(point.saves) / CGFloat(maxTotal) * 110
                                : 4
                            let animH = appeared ? totalH : 4
                            let animSH = appeared ? saveH : 4

                            VStack(spacing: 5) {
                                // Percentage label
                                if point.total > 0 {
                                    Text(String(format: "%.0f%%", point.rate))
                                        .font(AppFont.mono(10))
                                        .foregroundColor(.accentGreen)
                                        .opacity(appeared ? 1 : 0)
                                } else {
                                    Text("—")
                                        .font(AppFont.mono(10))
                                        .foregroundColor(.textSecondary.opacity(0.3))
                                }

                                // Bar stack
                                ZStack(alignment: .bottom) {
                                    // Total (dimmed background)
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.bgDark.opacity(0.5))
                                        .frame(width: barW, height: animH)
                                        .animation(.spring(response: 0.55, dampingFraction: 0.72)
                                            .delay(Double(idx) * 0.06), value: appeared)

                                    // Saves (green)
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(LinearGradient(
                                            colors: [Color(hex: "#16a34a"), Color.accentGreen],
                                            startPoint: .bottom, endPoint: .top
                                        ))
                                        .frame(width: barW, height: max(4, animSH))
                                        .animation(.spring(response: 0.55, dampingFraction: 0.72)
                                            .delay(Double(idx) * 0.06 + 0.05), value: appeared)
                                }

                                Text(point.label)
                                    .font(AppFont.caption(10))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
                .frame(height: 150)

                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.accentGreen).frame(width: 10, height: 10)
                        Text("Saves").font(AppFont.caption(11)).foregroundColor(.textSecondary)
                    }
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.bgDark.opacity(0.6)).frame(width: 10, height: 10)
                        Text("Total shots").font(AppFont.caption(11)).foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
        .onDisappear { appeared = false }
    }
}

// MARK: - Dive Split Card
struct DiveSplitCard: View {
    let analytics: AnalyticsSummary
    let animateIn: Bool
    @State private var barWidths: [CGFloat] = [0, 0, 0]

    private var total: Int { analytics.totalPenalties }

    var body: some View {
        AppCard {
            VStack(spacing: 18) {
                SectionHeader(title: "Dive Direction Split")

                VStack(spacing: 12) {
                    diveRow(label: "Left", count: analytics.leftDiveCount, color: .chartZone, idx: 0)
                    diveRow(label: "Center", count: analytics.centerDiveCount, color: .accentYellow, idx: 1)
                    diveRow(label: "Right", count: analytics.rightDiveCount, color: .accentOrange, idx: 2)
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 16)
        .onAppear {
            let counts = [analytics.leftDiveCount, analytics.centerDiveCount, analytics.rightDiveCount]
            for i in 0..<3 {
                let pct = total > 0 ? CGFloat(counts[i]) / CGFloat(total) : 0
                withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.1 + Double(i) * 0.08)) {
                    barWidths[i] = pct
                }
            }
        }
        .onDisappear { barWidths = [0, 0, 0] }
    }

    @ViewBuilder
    func diveRow(label: String, count: Int, color: Color, idx: Int) -> some View {
        let pct = total > 0 ? Double(count) / Double(total) : 0
        HStack(spacing: 12) {
            Text(label)
                .font(AppFont.body(13))
                .foregroundColor(.textSecondary)
                .frame(width: 52, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.bgDark.opacity(0.4))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [color.opacity(0.7), color],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * barWidths[idx], height: 8)
                }
            }
            .frame(height: 8)

            Text(String(format: "%.0f%%", pct * 100))
                .font(AppFont.mono(13))
                .foregroundColor(color)
                .frame(width: 36, alignment: .trailing)

            Text("\(count)")
                .font(AppFont.caption(11))
                .foregroundColor(.textSecondary.opacity(0.6))
                .frame(width: 24, alignment: .trailing)
        }
    }
}

// MARK: - Zone Heat Strip (visual grid)
struct ZoneHeatStrip: View {
    let analytics: AnalyticsSummary
    let animateIn: Bool
    @State private var cellOpacity: [PenaltyZone: Double] = [:]
    @State private var selectedZone: PenaltyZone? = nil

    private let zones = PenaltyZone.allCases
    private var maxCount: Int { zones.map { analytics.zoneHeatData[$0] ?? 0 }.max() ?? 1 }

    var body: some View {
        AppCard {
            VStack(spacing: 16) {
                SectionHeader(title: "Zone Heat Map")

                GeometryReader { geo in
                    let cols = 3
                    let rows = 3
                    let cellW = geo.size.width / CGFloat(cols)
                    let cellH = geo.size.height / CGFloat(rows)

                    ZStack {
                        // Goal outline
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1.5)

                        ForEach(zones, id: \.self) { zone in
                            let count = analytics.zoneHeatData[zone] ?? 0
                            let intensity = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                            let saveRate = analytics.saveRateByZone[zone] ?? 0
                            let isSelected = selectedZone == zone

                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(heatColor(intensity: intensity))
                                    .opacity(count == 0 ? 0.08 : (animateIn ? (cellOpacity[zone] ?? 0) : 0))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(isSelected ? Color.accentYellow : Color.white.opacity(0.06),
                                                    lineWidth: isSelected ? 2 : 0.5)
                                    )
                                    .scaleEffect(isSelected ? 0.93 : 1.0)

                                if count > 0 {
                                    VStack(spacing: 2) {
                                        Text("\(count)")
                                            .font(AppFont.mono(13))
                                            .foregroundColor(.white)
                                        Text(String(format: "%.0f%%", saveRate))
                                            .font(AppFont.caption(10))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .opacity(cellOpacity[zone] ?? 0)
                                }
                            }
                            .frame(width: cellW - 4, height: cellH - 4)
                            .position(
                                x: CGFloat(zone.col) * cellW + cellW / 2,
                                y: CGFloat(zone.row) * cellH + cellH / 2
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    selectedZone = selectedZone == zone ? nil : zone
                                }
                            }
                        }
                    }
                }
                .frame(height: 180)
                .onAppear {
                    for (i, zone) in zones.enumerated() {
                        withAnimation(.easeOut(duration: 0.4).delay(0.05 + Double(i) * 0.04)) {
                            cellOpacity[zone] = 1.0
                        }
                    }
                }
                .onDisappear { zones.forEach { cellOpacity[$0] = 0 } }

                // Selected zone detail
                if let zone = selectedZone {
                    let count = analytics.zoneHeatData[zone] ?? 0
                    let rate = analytics.saveRateByZone[zone] ?? 0
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(zone.label)
                                .font(AppFont.headline(14))
                                .foregroundColor(.textPrimary)
                            Text("\(count) shots recorded")
                                .font(AppFont.caption(12))
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(String(format: "%.0f%%", rate))
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundColor(rate >= 50 ? .accentGreen : .chartMiss)
                            Text("save rate")
                                .font(AppFont.caption(11))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentGreen.opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.accentGreen.opacity(0.2), lineWidth: 1)))
                    .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity),
                                            removal: .opacity))
                }

                // Heat legend
                HStack(spacing: 0) {
                    ForEach(0..<6) { i in
                        Rectangle()
                            .fill(heatColor(intensity: CGFloat(i) / 5))
                            .frame(maxWidth: .infinity, maxHeight: 6)
                            .cornerRadius(i == 0 ? 3 : (i == 5 ? 3 : 0),
                                          corners: i == 0 ? [.topLeft, .bottomLeft] : (i == 5 ? [.topRight, .bottomRight] : []))
                    }
                }
                .frame(height: 6)
                .overlay(
                    HStack {
                        Text("Low").font(AppFont.caption(10)).foregroundColor(.textSecondary)
                        Spacer()
                        Text("High").font(AppFont.caption(10)).foregroundColor(.textSecondary)
                    }
                    .offset(y: 12)
                )
                .padding(.bottom, 8)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 16)
    }

    func heatColor(intensity: CGFloat) -> Color {
        Color(
            red: 0.08 + Double(intensity) * 0.84,
            green: 0.77 - Double(intensity) * 0.47,
            blue: 0.37 - Double(intensity) * 0.26
        )
    }
}

// Helper for selective corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Zone Table Card
struct ZoneTableCard: View {
    let analytics: AnalyticsSummary
    @State private var appeared = false

    private let zones: [PenaltyZone] = [
        .topLeft, .topCenter, .topRight,
        .middleLeft, .middleCenter, .middleRight,
        .bottomLeft, .bottomCenter, .bottomRight
    ]

    var body: some View {
        AppCard {
            VStack(spacing: 14) {
                SectionHeader(title: "Zone Breakdown")

                // Header
                HStack {
                    Text("Zone").font(AppFont.caption(11)).foregroundColor(.textSecondary).frame(maxWidth: .infinity, alignment: .leading)
                    Text("Shots").font(AppFont.caption(11)).foregroundColor(.textSecondary).frame(width: 44, alignment: .center)
                    Text("Saves").font(AppFont.caption(11)).foregroundColor(.textSecondary).frame(width: 44, alignment: .center)
                    Text("Rate").font(AppFont.caption(11)).foregroundColor(.textSecondary).frame(width: 44, alignment: .trailing)
                }
                .padding(.horizontal, 4)

                Rectangle().fill(Color.accentGreen.opacity(0.12)).frame(height: 1)

                ForEach(Array(zones.enumerated()), id: \.element) { idx, zone in
                    let shots = analytics.zoneHeatData[zone] ?? 0
                    let rate = analytics.saveRateByZone[zone] ?? 0
                    let saves = Int((rate / 100) * Double(shots))

                    HStack {
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(shots > 0 ? rateColor(rate) : Color.bgDark.opacity(0.4))
                                .frame(width: 6, height: 6)
                            Text(zone.label)
                                .font(AppFont.body(13))
                                .foregroundColor(shots > 0 ? .textPrimary : .textSecondary.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(shots > 0 ? "\(shots)" : "—")
                            .font(AppFont.mono(12))
                            .foregroundColor(.textSecondary)
                            .frame(width: 44, alignment: .center)

                        Text(shots > 0 ? "\(saves)" : "—")
                            .font(AppFont.mono(12))
                            .foregroundColor(.accentGreen)
                            .frame(width: 44, alignment: .center)

                        Text(shots > 0 ? String(format: "%.0f%%", rate) : "—")
                            .font(AppFont.mono(12))
                            .foregroundColor(shots > 0 ? rateColor(rate) : .textSecondary.opacity(0.4))
                            .frame(width: 44, alignment: .trailing)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(shots > 0 ? rateColor(rate).opacity(0.05) : Color.clear)
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : -10)
                    .animation(.spring(response: 0.4, dampingFraction: 0.72).delay(Double(idx) * 0.04), value: appeared)
                }
            }
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }

    func rateColor(_ rate: Double) -> Color {
        if rate >= 65 { return .accentGreen }
        if rate >= 35 { return .accentYellow }
        return .chartMiss
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(KeeperStore())
        .environmentObject(PenaltyStore())
}
