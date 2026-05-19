import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var keeperStore: KeeperStore
    @EnvironmentObject var penaltyStore: PenaltyStore
    @EnvironmentObject var taskStore: TaskStore
    @State private var showAddPenalty = false
    @State private var showReports = false
    @State private var animateIn = false

    private var globalAnalytics: AnalyticsSummary {
        penaltyStore.globalAnalytics()
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Dashboard")
                                    .font(AppFont.title(26))
                                    .foregroundColor(.textPrimary)
                                Text(Date(), style: .date)
                                    .font(AppFont.body(13))
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.textSecondary)
                                    .padding(10)
                                    .background(Circle().fill(Color.bgStadium.opacity(0.5)))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // Main status card
                        AppCard {
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Overall Save Rate")
                                            .font(AppFont.body(13))
                                            .foregroundColor(.textSecondary)
                                        Text(String(format: "%.0f%%", globalAnalytics.saveRate))
                                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                                            .foregroundStyle(
                                                LinearGradient(colors: [.accentGreen, .accentYellow], startPoint: .leading, endPoint: .trailing)
                                            )
                                    }
                                    Spacer()
                                    Image(systemName: "hand.raised.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.accentGreen.opacity(0.5))
                                }

                                HStack(spacing: 12) {
                                    StatBadge(label: "Penalties", value: "\(globalAnalytics.totalPenalties)", color: .chartZone)
                                    StatBadge(label: "Saved", value: "\(globalAnalytics.saves)", color: .chartSave)
                                    StatBadge(label: "Scored", value: "\(globalAnalytics.scored)", color: .chartMiss)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                        // Today tasks
                        VStack(spacing: 12) {
                            SectionHeader(title: "Today's Tasks", action: "See All") {
                                // handled by tab navigation
                            }
                            .padding(.horizontal, 16)

                            let todayTasks = taskStore.todayTasks()
                            if todayTasks.isEmpty {
                                AppCard {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentGreen)
                                        Text("No tasks for today")
                                            .font(AppFont.body())
                                            .foregroundColor(.textSecondary)
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal, 16)
                            } else {
                                ForEach(todayTasks.prefix(3)) { task in
                                    TaskRowMini(task: task)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                        // Quick actions
                        VStack(spacing: 12) {
                            SectionHeader(title: "Quick Actions")
                                .padding(.horizontal, 16)

                            HStack(spacing: 12) {
                                quickActionButton(icon: "plus.circle.fill", label: "Add Record", color: .accentGreen) {
                                    showAddPenalty = true
                                }
                                quickActionButton(icon: "chart.bar.fill", label: "View Reports", color: .accentOrange) {
                                    showReports = true
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                        // Top keepers
                        if !keeperStore.keepers.isEmpty {
                            VStack(spacing: 12) {
                                SectionHeader(title: "Keeper Profiles", action: "See All") {}
                                    .padding(.horizontal, 16)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(keeperStore.keepers.prefix(5)) { keeper in
                                            KeeperMiniCard(keeper: keeper, saveRate: penaltyStore.saveRate(for: keeper.id))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .opacity(animateIn ? 1 : 0)
                        }

                        // Dive direction summary
                        AppCard {
                            VStack(spacing: 12) {
                                SectionHeader(title: "Dive Tendencies")
                                HStack(spacing: 16) {
                                    diveBar(label: "Left", count: globalAnalytics.leftDiveCount, total: globalAnalytics.totalPenalties, color: .chartZone)
                                    diveBar(label: "Center", count: globalAnalytics.centerDiveCount, total: globalAnalytics.totalPenalties, color: .accentYellow)
                                    diveBar(label: "Right", count: globalAnalytics.rightDiveCount, total: globalAnalytics.totalPenalties, color: .accentOrange)
                                }
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
            .sheet(isPresented: $showAddPenalty) {
                AddPenaltyView(preselectedKeeperID: keeperStore.keepers.first?.id)
            }
            .sheet(isPresented: $showReports) {
                ReportsView()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) {
                animateIn = true
            }
        }
    }

    @ViewBuilder
    func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(color)
                Text(label)
                    .font(AppFont.caption())
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.25), lineWidth: 1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    func diveBar(label: String, count: Int, total: Int, color: Color) -> some View {
        let pct = total > 0 ? CGFloat(count) / CGFloat(total) : 0
        VStack(spacing: 6) {
            Text("\(count)")
                .font(AppFont.headline(18))
                .foregroundColor(color)
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.12))
                        .frame(height: 60)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.7))
                        .frame(height: max(4, 60 * pct))
                }
            }
            .frame(height: 60)
            Text(label)
                .font(AppFont.caption(11))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TaskRowMini: View {
    let task: TrainingTask
    @EnvironmentObject var taskStore: TaskStore

    var body: some View {
        AppCard(padding: 12) {
            HStack(spacing: 12) {
                Button(action: { taskStore.markDone(task) }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .accentGreen : .textSecondary.opacity(0.5))
                        .font(.system(size: 20))
                }
                .buttonStyle(PlainButtonStyle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(AppFont.body(14))
                        .foregroundColor(.textPrimary)
                        .strikethrough(task.isCompleted)
                    if let due = task.dueDate {
                        Text(due, style: .time)
                            .font(AppFont.caption(11))
                            .foregroundColor(.textSecondary)
                    }
                }
                Spacer()
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct KeeperMiniCard: View {
    let keeper: Keeper
    let saveRate: Double

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.15))
                    .frame(width: 56, height: 56)
                Text(keeper.name.prefix(2).uppercased())
                    .font(AppFont.headline(18))
                    .foregroundColor(.accentGreen)
            }
            Text(keeper.name)
                .font(AppFont.body(13))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
            Text(String(format: "%.0f%%", saveRate))
                .font(AppFont.mono(13))
                .foregroundColor(saveRate >= 50 ? .accentGreen : .chartMiss)
        }
        .frame(width: 90)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.bgStadium.opacity(0.4))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentGreen.opacity(0.15), lineWidth: 1))
        )
    }
}
