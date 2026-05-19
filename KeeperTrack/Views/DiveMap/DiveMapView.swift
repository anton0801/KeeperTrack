import SwiftUI

struct DiveMapView: View {
    let keeperID: UUID?
    @EnvironmentObject var keeperStore: KeeperStore
    @EnvironmentObject var penaltyStore: PenaltyStore
    @State private var selectedKeeper: Keeper?
    @State private var showAddPenalty = false
    @State private var showDrill = false
    @State private var animateIn = false
    @State private var selectedZone: PenaltyZone?
    @State private var viewMode: ViewMode = .heatMap

    enum ViewMode: String, CaseIterable {
        case heatMap = "Heat Map"
        case saveRate = "Save Rate"
    }

    private var activeKeeper: Keeper? {
        if let kid = keeperID ?? selectedKeeper?.id {
            return keeperStore.keepers.first { $0.id == kid }
        }
        return nil
    }

    private var analytics: AnalyticsSummary {
        if let kid = activeKeeper?.id {
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
                            Text("Dive Map")
                                .font(AppFont.title())
                                .foregroundColor(.textPrimary)
                            Spacer()
                            NavigationLink(destination: PenaltyHistoryView(keeperID: activeKeeper?.id)) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.textSecondary)
                                    .padding(10)
                                    .background(Circle().fill(Color.bgStadium.opacity(0.5)))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // Keeper selector
                        if keeperID == nil {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    keeperChip(name: "All", isSelected: selectedKeeper == nil) {
                                        selectedKeeper = nil
                                    }
                                    ForEach(keeperStore.keepers) { keeper in
                                        keeperChip(name: keeper.name, isSelected: selectedKeeper?.id == keeper.id) {
                                            selectedKeeper = keeper
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        // View mode toggle
                        HStack(spacing: 0) {
                            ForEach(ViewMode.allCases, id: \.self) { mode in
                                Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { viewMode = mode } }) {
                                    Text(mode.rawValue)
                                        .font(AppFont.body(14))
                                        .foregroundColor(viewMode == mode ? .bgDark : .textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(viewMode == mode ? Color.accentGreen : Color.clear)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.bgStadium.opacity(0.4)))
                        .padding(.horizontal, 16)

                        // Stats summary row
                        HStack(spacing: 12) {
                            StatBadge(label: "Total", value: "\(analytics.totalPenalties)", color: .chartZone)
                            StatBadge(label: "Saves", value: "\(analytics.saves)", color: .accentGreen)
                            StatBadge(label: "Rate", value: String(format: "%.0f%%", analytics.saveRate), color: analytics.saveRate >= 50 ? .accentGreen : .chartMiss)
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)

                        // Main goal + heat map
                        AppCard(padding: 20) {
                            VStack(spacing: 16) {
                                GoalHeatMap(
                                    analytics: analytics,
                                    viewMode: viewMode,
                                    selectedZone: $selectedZone
                                )
                                .frame(height: 220)

                                // Zone detail
                                if let zone = selectedZone {
                                    ZoneDetailCard(zone: zone, analytics: analytics)
                                        .transition(.scale.combined(with: .opacity))
                                }

                                // Dive tendency row
                                HStack(spacing: 0) {
                                    diveTendency(direction: .left, count: analytics.leftDiveCount, total: analytics.totalPenalties)
                                    diveTendency(direction: .center, count: analytics.centerDiveCount, total: analytics.totalPenalties)
                                    diveTendency(direction: .right, count: analytics.rightDiveCount, total: analytics.totalPenalties)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.bgDark.opacity(0.3))
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                        // Recommendations
                        let tips = generateTips(analytics: analytics)
                        if !tips.isEmpty {
                            VStack(spacing: 10) {
                                SectionHeader(title: "Pattern Insights")
                                    .padding(.horizontal, 16)
                                ForEach(tips, id: \.self) { tip in
                                    tipCard(tip)
                                }
                            }
                            .opacity(animateIn ? 1 : 0)
                        }

                        // Action buttons
                        VStack(spacing: 12) {
                            PrimaryButton("Add Penalty", icon: "plus.circle.fill") { showAddPenalty = true }
                            HStack(spacing: 12) {
                                SecondaryButton("Create Drill", icon: "figure.run") { showDrill = true }
                                NavigationLink(destination: PenaltyHistoryView(keeperID: activeKeeper?.id)) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock.arrow.circlepath")
                                        Text("History")
                                    }
                                    .font(AppFont.body())
                                    .foregroundColor(.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.accentGreen.opacity(0.4), lineWidth: 1.5)
                                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.bgStadium.opacity(0.3)))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddPenalty) {
                AddPenaltyView(preselectedKeeperID: activeKeeper?.id)
            }
            .sheet(isPresented: $showDrill) {
                CreateDrillView(analytics: analytics)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.15)) { animateIn = true }
        }
    }

    @ViewBuilder
    func keeperChip(name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(name)
                .font(AppFont.body(13))
                .foregroundColor(isSelected ? .bgDark : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(isSelected ? Color.accentGreen : Color.bgStadium.opacity(0.5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    func diveTendency(direction: DiveDirection, count: Int, total: Int) -> some View {
        let pct = total > 0 ? Double(count) / Double(total) * 100 : 0
        VStack(spacing: 4) {
            Text(direction.rawValue)
                .font(AppFont.caption(11))
                .foregroundColor(.textSecondary)
            Text(String(format: "%.0f%%", pct))
                .font(AppFont.mono(16))
                .foregroundColor(direction == .left ? .chartZone : direction == .center ? .accentYellow : .accentOrange)
            Text("\(count)")
                .font(AppFont.caption(11))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    func tipCard(_ tip: String) -> some View {
        AppCard(padding: 12) {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.accentYellow)
                    .font(.system(size: 16))
                Text(tip)
                    .font(AppFont.body(13))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, 16)
    }

    func generateTips(analytics: AnalyticsSummary) -> [String] {
        guard analytics.totalPenalties >= 3 else { return [] }
        var tips: [String] = []
        let total = analytics.totalPenalties

        let leftPct = total > 0 ? Double(analytics.leftDiveCount) / Double(total) * 100 : 0
        let rightPct = total > 0 ? Double(analytics.rightDiveCount) / Double(total) * 100 : 0
        let centerPct = total > 0 ? Double(analytics.centerDiveCount) / Double(total) * 100 : 0

        if leftPct > 55 { tips.append("Strong left-dive tendency (\(Int(leftPct))%). Shoot right side to exploit the gap.") }
        if rightPct > 55 { tips.append("Right-dive dominant (\(Int(rightPct))%). Consider striking to the left.") }
        if centerPct > 40 { tips.append("Frequently stays center (\(Int(centerPct))%). Down-the-middle may be risky.") }

        let maxHeatZone = analytics.zoneHeatData.max { a, b in (a.value) < (b.value) }
        if let hot = maxHeatZone, hot.value >= 3 {
            tips.append("Hottest zone: \(hot.key.label). Keeper most active here — aim elsewhere.")
        }

        let coldZone = analytics.saveRateByZone.filter { analytics.zoneHeatData[$0.key] ?? 0 > 0 }.min { $0.value < $1.value }
        if let cold = coldZone {
            tips.append("Weakest zone by save rate: \(cold.key.label) (\(Int(cold.value))%). Target this area.")
        }

        return Array(tips.prefix(3))
    }
}

struct GoalHeatMap: View {
    let analytics: AnalyticsSummary
    let viewMode: DiveMapView.ViewMode
    @Binding var selectedZone: PenaltyZone?
    private let zones = PenaltyZone.allCases

    var maxCount: Int {
        zones.map { analytics.zoneHeatData[$0] ?? 0 }.max() ?? 1
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cellW = w / 3
            let cellH = (h - 40) / 3  // leave space for goal frame decorations

            ZStack {
                // Goal outline
                goalFrame(width: w, height: h - 30)
                    .offset(y: -15)

                // Zone grid
                ForEach(zones, id: \.self) { zone in
                    let count = analytics.zoneHeatData[zone] ?? 0
                    let saveRate = analytics.saveRateByZone[zone] ?? 0
                    let intensity = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                    let isSelected = selectedZone == zone

                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(viewMode == .heatMap ? heatColor(intensity: intensity) : saveRateColor(saveRate))
                            .opacity(count == 0 ? 0.1 : (isSelected ? 1.0 : 0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isSelected ? Color.accentYellow : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                            )
                            .scaleEffect(isSelected ? 1.05 : 1.0)

                        VStack(spacing: 2) {
                            if viewMode == .heatMap {
                                Text("\(count)")
                                    .font(AppFont.mono(15))
                                    .foregroundColor(.white)
                            } else {
                                Text(String(format: "%.0f%%", saveRate))
                                    .font(AppFont.mono(13))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(width: cellW - 4, height: cellH - 4)
                    .position(
                        x: CGFloat(zone.col) * cellW + cellW / 2,
                        y: CGFloat(zone.row) * cellH + cellH / 2 + 4
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedZone = selectedZone == zone ? nil : zone
                        }
                    }
                }

                // Penalty spot
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .position(x: w / 2, y: h - 8)

                // Legend
                HStack(spacing: 16) {
                    legendDot(color: heatColor(intensity: 0.9), label: viewMode == .heatMap ? "High" : "Saved")
                    legendDot(color: heatColor(intensity: 0.45), label: "Medium")
                    legendDot(color: heatColor(intensity: 0.1), label: viewMode == .heatMap ? "Low" : "Scored")
                }
                .position(x: w / 2, y: h)
            }
        }
    }

    @ViewBuilder
    func goalFrame(width: CGFloat, height: CGFloat) -> some View {
        // Posts
        ZStack {
            // Top bar
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: width, height: 3)
                .position(x: width / 2, y: 3)
            // Left post
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 3, height: height)
                .position(x: 1.5, y: height / 2)
            // Right post
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 3, height: height)
                .position(x: width - 1.5, y: height / 2)
        }
    }

    func heatColor(intensity: CGFloat) -> Color {
        let r = 0.08 + Double(intensity) * 0.86
        let g = 0.77 - Double(intensity) * 0.5
        let b = 0.37 - Double(intensity) * 0.28
        return Color(red: r, green: g, blue: b)
    }

    func saveRateColor(_ rate: Double) -> Color {
        if rate >= 70 { return Color.accentGreen }
        if rate >= 40 { return Color.accentYellow }
        return Color.chartMiss
    }

    @ViewBuilder
    func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(AppFont.caption(10)).foregroundColor(.textSecondary)
        }
    }
}

struct ZoneDetailCard: View {
    let zone: PenaltyZone
    let analytics: AnalyticsSummary

    var count: Int { analytics.zoneHeatData[zone] ?? 0 }
    var saveRate: Double { analytics.saveRateByZone[zone] ?? 0 }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(zone.label)
                    .font(AppFont.headline())
                    .foregroundColor(.textPrimary)
                Text("\(count) shots recorded")
                    .font(AppFont.body(13))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.0f%%", saveRate))
                    .font(AppFont.title(22))
                    .foregroundColor(saveRate >= 50 ? .accentGreen : .chartMiss)
                Text("save rate")
                    .font(AppFont.caption())
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentGreen.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentGreen.opacity(0.3), lineWidth: 1))
        )
    }
}

struct CreateDrillView: View {
    let analytics: AnalyticsSummary
    @EnvironmentObject var taskStore: TaskStore
    @State private var drillTitle = ""
    @State private var drillNotes = ""
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var priority: TrainingTask.TaskPriority = .high
    @State private var saved = false
    @Environment(\.presentationMode) var presentationMode

    var suggestedFocus: String {
        let weakZone = analytics.saveRateByZone.filter { analytics.zoneHeatData[$0.key] ?? 0 > 0 }.min { $0.value < $1.value }?.key
        return weakZone?.label ?? "General"
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        AppCard {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.accentYellow)
                                    Text("Suggested Focus: \(suggestedFocus)")
                                        .font(AppFont.body())
                                        .foregroundColor(.textPrimary)
                                }
                                Text("Based on your heat map data, practicing this zone will improve overall save rate.")
                                    .font(AppFont.body(13))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(.horizontal, 16)

                        AppCard {
                            VStack(spacing: 14) {
                                FormField(label: "Drill Title *", placeholder: "e.g. Left-side reaction drill", text: $drillTitle)
                                    .onAppear { drillTitle = "Focus on \(suggestedFocus) Zone" }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Notes")
                                        .font(AppFont.caption())
                                        .foregroundColor(.textSecondary)
                                    TextEditor(text: $drillNotes)
                                        .font(AppFont.body())
                                        .foregroundColor(.textPrimary)
                                        .frame(height: 80)
                                        .scrollContentBackground(.hidden)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Due Date")
                                        .font(AppFont.caption())
                                        .foregroundColor(.textSecondary)
                                    DatePicker("", selection: $dueDate, displayedComponents: [.date])
                                        .colorScheme(.dark)
                                        .labelsHidden()
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Priority")
                                        .font(AppFont.caption())
                                        .foregroundColor(.textSecondary)
                                    HStack(spacing: 10) {
                                        ForEach(TrainingTask.TaskPriority.allCases, id: \.self) { p in
                                            Button(action: { priority = p }) {
                                                Text(p.rawValue)
                                                    .font(AppFont.body(13))
                                                    .foregroundColor(priority == p ? .bgDark : .textSecondary)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Capsule().fill(priority == p ? p.color : Color.bgStadium.opacity(0.3)))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        if saved {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.accentGreen)
                                Text("Drill added to Training!").font(AppFont.body()).foregroundColor(.accentGreen)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        VStack(spacing: 12) {
                            PrimaryButton("Add to Training", icon: "plus.circle.fill") { saveDrill() }
                            SecondaryButton("Cancel") { presentationMode.wrappedValue.dismiss() }
                        }
                        .padding(.horizontal, 16)
                        Spacer().frame(height: 32)
                    }
                }
            }
            .navigationTitle("Create Drill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func saveDrill() {
        guard !drillTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let task = TrainingTask(title: drillTitle, notes: drillNotes, dueDate: dueDate, priority: priority)
        taskStore.add(task)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { presentationMode.wrappedValue.dismiss() }
    }
}
