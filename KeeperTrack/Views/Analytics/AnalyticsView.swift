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
        if let kid = selectedKeeperID {
            return penaltyStore.analytics(for: kid)
        }
        return penaltyStore.globalAnalytics()
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Text("Analytics")
                                .font(AppFont.title())
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // Keeper filter
                        if !keeperStore.keepers.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    filterPill(name: "Global", id: nil)
                                    ForEach(keeperStore.keepers) { k in
                                        filterPill(name: k.name, id: k.id)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        // Period picker
                        HStack(spacing: 0) {
                            ForEach(Period.allCases, id: \.self) { p in
                                Button(action: { withAnimation { selectedPeriod = p } }) {
                                    Text(p.rawValue)
                                        .font(AppFont.body(14))
                                        .foregroundColor(selectedPeriod == p ? .bgDark : .textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(selectedPeriod == p ? Color.accentGreen : Color.clear))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.bgStadium.opacity(0.4)))
                        .padding(.horizontal, 16)

                        // Overview stats
                        HStack(spacing: 12) {
                            StatBadge(label: "Total", value: "\(analytics.totalPenalties)", color: .chartZone)
                            StatBadge(label: "Saved", value: "\(analytics.saves)", color: .accentGreen)
                            StatBadge(label: "Scored", value: "\(analytics.scored)", color: .chartMiss)
                            StatBadge(label: "Missed", value: "\(analytics.missed)", color: .accentYellow)
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)

                        // Save rate donut
                        AppCard {
                            VStack(spacing: 16) {
                                SectionHeader(title: "Success Rate")
                                SaveRateDonut(analytics: analytics)
                                    .frame(height: 180)
                            }
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)

                        // Weekly bar chart
                        AppCard {
                            VStack(spacing: 12) {
                                SectionHeader(title: "Weekly Progress")
                                WeeklyBarChart(points: analytics.weeklyData)
                                    .frame(height: 140)
                            }
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)

                        // Dive direction pie
                        AppCard {
                            VStack(spacing: 12) {
                                SectionHeader(title: "Dive Direction Split")
                                DiveDirectionChart(analytics: analytics)
                                    .frame(height: 120)
                            }
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)

                        // Zone performance table
                        AppCard {
                            VStack(spacing: 12) {
                                SectionHeader(title: "Zone Performance")
                                ZonePerformanceTable(analytics: analytics)
                            }
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { animateIn = true }
        }
    }

    @ViewBuilder
    func filterPill(name: String, id: UUID?) -> some View {
        let isSelected = selectedKeeperID == id
        Button(action: { selectedKeeperID = id }) {
            Text(name)
                .font(AppFont.body(13))
                .foregroundColor(isSelected ? .bgDark : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(isSelected ? Color.accentGreen : Color.bgStadium.opacity(0.5)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SaveRateDonut: View {
    let analytics: AnalyticsSummary
    @State private var drawProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.bgDark.opacity(0.5), lineWidth: 20)

            // Saved arc
            if analytics.totalPenalties > 0 {
                Circle()
                    .trim(from: 0, to: drawProgress * CGFloat(analytics.saves) / CGFloat(analytics.totalPenalties))
                    .stroke(Color.accentGreen, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(
                        from: drawProgress * CGFloat(analytics.saves) / CGFloat(analytics.totalPenalties),
                        to: drawProgress * CGFloat(analytics.saves + analytics.scored) / CGFloat(analytics.totalPenalties)
                    )
                    .stroke(Color.chartMiss, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(
                        from: drawProgress * CGFloat(analytics.saves + analytics.scored) / CGFloat(analytics.totalPenalties),
                        to: drawProgress
                    )
                    .stroke(Color.accentYellow, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            // Center label
            VStack(spacing: 2) {
                Text(String(format: "%.0f%%", analytics.saveRate))
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.accentGreen, .accentYellow], startPoint: .leading, endPoint: .trailing))
                Text("Save Rate")
                    .font(AppFont.caption())
                    .foregroundColor(.textSecondary)
            }

            // Legend
            HStack(spacing: 20) {
                legendItem(color: .accentGreen, label: "Saved \(analytics.saves)")
                legendItem(color: .chartMiss, label: "Scored \(analytics.scored)")
                legendItem(color: .accentYellow, label: "Missed \(analytics.missed)")
            }
            .offset(y: 100)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) { drawProgress = 1.0 }
        }
        .onDisappear { drawProgress = 0 }
    }

    @ViewBuilder
    func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(AppFont.caption(11)).foregroundColor(.textSecondary)
        }
    }
}

struct WeeklyBarChart: View {
    let points: [AnalyticsSummary.WeeklyPoint]
    @State private var animateIn = false

    private var maxTotal: Int { points.map { $0.total }.max() ?? 1 }

    var body: some View {
        GeometryReader { geo in
            let barW = max(20, (geo.size.width - CGFloat(points.count) * 8) / CGFloat(max(1, points.count)))
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(points) { point in
                    VStack(spacing: 4) {
                        if point.total > 0 {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.bgDark.opacity(0.4))
                                    .frame(height: animateIn ? CGFloat(point.total) / CGFloat(maxTotal) * 100 : 4)

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(colors: [.accentGreen.opacity(0.8), .accentGreen], startPoint: .top, endPoint: .bottom))
                                    .frame(height: animateIn ? max(4, CGFloat(point.saves) / CGFloat(maxTotal) * 100) : 4)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.bgDark.opacity(0.2))
                                .frame(height: 8)
                        }

                        Text(point.label)
                            .font(AppFont.caption(10))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(width: barW)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(points.firstIndex(where: { $0.id == point.id }) ?? 0) * 0.05), value: animateIn)
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
        .onAppear { animateIn = true }
        .onDisappear { animateIn = false }
    }
}

struct DiveDirectionChart: View {
    let analytics: AnalyticsSummary
    @State private var animateIn = false

    private var total: Int { analytics.totalPenalties }

    var body: some View {
        HStack(spacing: 20) {
            dirBar(label: "Left", count: analytics.leftDiveCount, color: .chartZone)
            dirBar(label: "Center", count: analytics.centerDiveCount, color: .accentYellow)
            dirBar(label: "Right", count: analytics.rightDiveCount, color: .accentOrange)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.7).delay(0.2)) { animateIn = true } }
        .onDisappear { animateIn = false }
    }

    @ViewBuilder
    func dirBar(label: String, count: Int, color: Color) -> some View {
        let pct = total > 0 ? CGFloat(count) / CGFloat(total) : 0
        VStack(spacing: 8) {
            Text(String(format: "%.0f%%", pct * 100))
                .font(AppFont.headline(18))
                .foregroundColor(color)
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.12))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [color.opacity(0.5), color], startPoint: .top, endPoint: .bottom))
                        .frame(height: animateIn ? geo.size.height * pct : 4)
                }
            }
            .frame(height: 70)
            Text(label)
                .font(AppFont.caption(12))
                .foregroundColor(.textSecondary)
            Text("\(count)")
                .font(AppFont.mono(12))
                .foregroundColor(.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ZonePerformanceTable: View {
    let analytics: AnalyticsSummary
    private let topZones: [PenaltyZone] = [.topLeft, .topCenter, .topRight, .middleLeft, .middleCenter, .middleRight, .bottomLeft, .bottomCenter, .bottomRight]

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Zone").font(AppFont.caption()).foregroundColor(.textSecondary).frame(maxWidth: .infinity, alignment: .leading)
                Text("Shots").font(AppFont.caption()).foregroundColor(.textSecondary).frame(width: 48, alignment: .center)
                Text("Saves").font(AppFont.caption()).foregroundColor(.textSecondary).frame(width: 48, alignment: .center)
                Text("Rate").font(AppFont.caption()).foregroundColor(.textSecondary).frame(width: 48, alignment: .trailing)
            }
            .padding(.horizontal, 4)

            Divider().background(Color.accentGreen.opacity(0.2))

            ForEach(topZones, id: \.self) { zone in
                let shots = analytics.zoneHeatData[zone] ?? 0
                let rate = analytics.saveRateByZone[zone] ?? 0
                let saves = Int(rate / 100 * Double(shots))
                HStack {
                    Text(zone.label).font(AppFont.body(13)).foregroundColor(.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(shots)").font(AppFont.mono(13)).foregroundColor(.textSecondary).frame(width: 48, alignment: .center)
                    Text("\(saves)").font(AppFont.mono(13)).foregroundColor(.accentGreen).frame(width: 48, alignment: .center)
                    Text(String(format: "%.0f%%", rate))
                        .font(AppFont.mono(13))
                        .foregroundColor(rate >= 50 ? .accentGreen : .chartMiss)
                        .frame(width: 48, alignment: .trailing)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
                .background(shots > 0 ? Color.accentGreen.opacity(0.04) : Color.clear)
                .cornerRadius(6)
            }
        }
    }
}
