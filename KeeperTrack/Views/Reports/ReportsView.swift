import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var keeperStore: KeeperStore
    @EnvironmentObject var penaltyStore: PenaltyStore
    @State private var selectedKeeperID: UUID?
    @State private var shareText = ""
    @State private var showShareSheet = false
    @State private var animateIn = false

    private var analytics: AnalyticsSummary {
        if let kid = selectedKeeperID { return penaltyStore.analytics(for: kid) }
        return penaltyStore.globalAnalytics()
    }

    private var keeperName: String {
        if let kid = selectedKeeperID {
            return keeperStore.keepers.first { $0.id == kid }?.name ?? "Unknown"
        }
        return "All Keepers"
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Keeper selector
                        if !keeperStore.keepers.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    selectorChip(name: "Global", id: nil)
                                    ForEach(keeperStore.keepers) { k in
                                        selectorChip(name: k.name, id: k.id)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            }
                        }

                        // Summary card
                        AppCard {
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Report Summary")
                                            .font(AppFont.caption())
                                            .foregroundColor(.textSecondary)
                                        Text(keeperName)
                                            .font(AppFont.headline(20))
                                            .foregroundColor(.textPrimary)
                                    }
                                    Spacer()
                                    Text(Date(), style: .date)
                                        .font(AppFont.caption())
                                        .foregroundColor(.textSecondary)
                                }

                                HStack(spacing: 12) {
                                    StatBadge(label: "Penalties", value: "\(analytics.totalPenalties)", color: .chartZone)
                                    StatBadge(label: "Save Rate", value: String(format: "%.0f%%", analytics.saveRate), color: .accentGreen)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)

                        // Dive pattern
                        AppCard {
                            VStack(spacing: 12) {
                                SectionHeader(title: "Dive Patterns")
                                HStack(spacing: 16) {
                                    diveStat(label: "Left", count: analytics.leftDiveCount, total: analytics.totalPenalties, color: .chartZone)
                                    Divider().background(Color.accentGreen.opacity(0.2))
                                    diveStat(label: "Center", count: analytics.centerDiveCount, total: analytics.totalPenalties, color: .accentYellow)
                                    Divider().background(Color.accentGreen.opacity(0.2))
                                    diveStat(label: "Right", count: analytics.rightDiveCount, total: analytics.totalPenalties, color: .accentOrange)
                                }
                                .frame(height: 60)
                            }
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)

                        // Weak zones
                        AppCard {
                            VStack(spacing: 12) {
                                SectionHeader(title: "Weakest Zones")
                                let weakZones = weakestZones()
                                if weakZones.isEmpty {
                                    Text("Add more penalties to see zone analysis")
                                        .font(AppFont.body(13))
                                        .foregroundColor(.textSecondary)
                                } else {
                                    ForEach(weakZones, id: \.self) { zone in
                                        let rate = analytics.saveRateByZone[zone] ?? 0
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.chartMiss)
                                                .font(.system(size: 14))
                                            Text(zone.label)
                                                .font(AppFont.body())
                                                .foregroundColor(.textPrimary)
                                            Spacer()
                                            Text(String(format: "%.0f%% saved", rate))
                                                .font(AppFont.mono(13))
                                                .foregroundColor(.chartMiss)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)

                        // Recommendations
                        AppCard {
                            VStack(spacing: 12) {
                                SectionHeader(title: "Recommendations")
                                ForEach(generateRecommendations(), id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentGreen)
                                            .font(.system(size: 14))
                                        Text(tip)
                                            .font(AppFont.body(13))
                                            .foregroundColor(.textPrimary)
                                            .lineSpacing(3)
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)

                        // Export buttons
                        VStack(spacing: 12) {
                            PrimaryButton("Share Report", icon: "square.and.arrow.up", color: .accentGreen) {
                                shareText = generateReportText()
                                showShareSheet = true
                            }
                        }
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 60)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [shareText])
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { animateIn = true }
        }
    }

    @ViewBuilder
    func selectorChip(name: String, id: UUID?) -> some View {
        let isSelected = selectedKeeperID == id
        Button(action: { selectedKeeperID = id }) {
            Text(name)
                .font(AppFont.body(13))
                .foregroundColor(isSelected ? .bgDark : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(isSelected ? Color.accentGreen : Color.bgStadium.opacity(0.4)))
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    func diveStat(label: String, count: Int, total: Int, color: Color) -> some View {
        let pct = total > 0 ? Double(count) / Double(total) * 100 : 0
        VStack(spacing: 4) {
            Text(String(format: "%.0f%%", pct))
                .font(AppFont.headline(18))
                .foregroundColor(color)
            Text(label)
                .font(AppFont.caption(12))
                .foregroundColor(.textSecondary)
            Text("\(count)")
                .font(AppFont.mono(12))
                .foregroundColor(.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    func weakestZones() -> [PenaltyZone] {
        PenaltyZone.allCases
            .filter { (analytics.zoneHeatData[$0] ?? 0) >= 2 }
            .sorted { (analytics.saveRateByZone[$0] ?? 100) < (analytics.saveRateByZone[$1] ?? 100) }
            .prefix(3)
            .map { $0 }
    }

    func generateRecommendations() -> [String] {
        var tips: [String] = []
        guard analytics.totalPenalties >= 3 else {
            return ["Record at least 3 penalties to receive personalized recommendations."]
        }
        let total = analytics.totalPenalties
        let leftPct = total > 0 ? Double(analytics.leftDiveCount) / Double(total) * 100 : 0
        let rightPct = total > 0 ? Double(analytics.rightDiveCount) / Double(total) * 100 : 0
        if leftPct > 55 { tips.append("Strong left-bias detected. Practice right-side coverage drills to balance reaction.") }
        if rightPct > 55 { tips.append("Right-dive dominance (\(Int(rightPct))%). Work on mid and left side positioning.") }
        if analytics.saveRate < 40 { tips.append("Save rate below 40%. Focus on reading the shooter's body language and planting foot direction.") }
        if analytics.saveRate > 70 { tips.append("Excellent save rate! Maintain consistent positioning and continue logging patterns.") }
        if let weakest = weakestZones().first {
            tips.append("Priority zone for training: \(weakest.label). Practice reaction drills targeting this corner.")
        }
        if tips.isEmpty { tips.append("Keep adding penalty records to unlock more detailed pattern insights.") }
        return tips
    }

    func generateReportText() -> String {
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
        return """
Keeper Track Report — \(keeperName)
Generated: \(dateStr)

📊 SUMMARY
Total Penalties: \(analytics.totalPenalties)
Saves: \(analytics.saves) | Scored: \(analytics.scored) | Missed: \(analytics.missed)
Save Rate: \(String(format: "%.0f%%", analytics.saveRate))

🏃 DIVE DIRECTIONS
Left: \(analytics.leftDiveCount) | Center: \(analytics.centerDiveCount) | Right: \(analytics.rightDiveCount)

💡 RECOMMENDATIONS
\(generateRecommendations().enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))

Generated by Keeper Track
"""
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
