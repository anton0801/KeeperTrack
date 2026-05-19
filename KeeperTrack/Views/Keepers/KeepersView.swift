import SwiftUI

struct KeepersView: View {
    @EnvironmentObject var keeperStore: KeeperStore
    @EnvironmentObject var penaltyStore: PenaltyStore
    @State private var showAddKeeper = false
    @State private var selectedKeeper: Keeper?
    @State private var animateIn = false

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Keepers")
                            .font(AppFont.title())
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button(action: { showAddKeeper = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.accentGreen)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                    if keeperStore.keepers.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "person.3.fill",
                            title: "No Keeper Profiles",
                            subtitle: "Add your first goalkeeper to start tracking penalty patterns"
                        )
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 14) {
                                ForEach(keeperStore.keepers) { keeper in
                                    KeeperCard(
                                        keeper: keeper,
                                        saveRate: penaltyStore.saveRate(for: keeper.id),
                                        penaltyCount: penaltyStore.penalties(for: keeper.id).count
                                    )
                                    .onTapGesture { selectedKeeper = keeper }
                                }
                                Spacer().frame(height: 100)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddKeeper) {
                AddEditKeeperView(keeper: nil) { newKeeper in
                    keeperStore.add(newKeeper)
                }
            }
            .sheet(item: $selectedKeeper) { keeper in
                KeeperDetailView(keeper: keeper)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { animateIn = true }
        }
    }
}

struct KeeperCard: View {
    let keeper: Keeper
    let saveRate: Double
    let penaltyCount: Int
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.accentGreen.opacity(0.25), .accentYellow.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 56, height: 56)
                Text(keeper.name.prefix(2).uppercased())
                    .font(AppFont.headline(20))
                    .foregroundColor(.accentGreen)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(keeper.name)
                    .font(AppFont.headline())
                    .foregroundColor(.textPrimary)
                Text(keeper.team.isEmpty ? "No team" : keeper.team)
                    .font(AppFont.body(13))
                    .foregroundColor(.textSecondary)
                Text("Updated \(keeper.updatedAt, style: .relative) ago")
                    .font(AppFont.caption(11))
                    .foregroundColor(.textSecondary.opacity(0.6))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.0f%%", saveRate))
                    .font(AppFont.mono(18))
                    .foregroundColor(saveRate >= 50 ? .accentGreen : .chartMiss)
                Text("\(penaltyCount) penalties")
                    .font(AppFont.caption(11))
                    .foregroundColor(.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.textSecondary.opacity(0.4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bgStadium.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentGreen.opacity(isPressed ? 0.4 : 0.15), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in isPressed = pressing }, perform: {})
    }
}

struct AddEditKeeperView: View {
    let keeper: Keeper?
    let onSave: (Keeper) -> Void
    @EnvironmentObject var keeperStore: KeeperStore

    @State private var name: String = ""
    @State private var team: String = ""
    @State private var notes: String = ""
    @State private var showValidationError = false
    @State private var saved = false
    @Environment(\.presentationMode) var presentationMode

    init(keeper: Keeper?, onSave: @escaping (Keeper) -> Void) {
        self.keeper = keeper
        self.onSave = onSave
        if let k = keeper {
            _name = State(initialValue: k.name)
            _team = State(initialValue: k.team)
            _notes = State(initialValue: k.notes)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Avatar preview
                        ZStack {
                            Circle()
                                .fill(Color.accentGreen.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Text(name.isEmpty ? "?" : name.prefix(2).uppercased())
                                .font(AppFont.headline(28))
                                .foregroundColor(.accentGreen)
                        }
                        .padding(.top, 8)

                        AppCard {
                            VStack(spacing: 16) {
                                FormField(label: "Name *", placeholder: "e.g. David De Gea", text: $name)
                                FormField(label: "Team", placeholder: "e.g. Manchester United", text: $team)
                            }
                        }
                        .padding(.horizontal, 16)

                        AppCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(AppFont.caption())
                                    .foregroundColor(.textSecondary)
                                TextEditor(text: $notes)
                                    .font(AppFont.body())
                                    .foregroundColor(.textPrimary)
                                    .frame(minHeight: 80)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                            }
                        }
                        .padding(.horizontal, 16)

                        if showValidationError {
                            Text("Name is required")
                                .font(AppFont.body(13))
                                .foregroundColor(.chartMiss)
                                .padding(.horizontal, 16)
                        }

                        if saved {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentGreen)
                                Text("Saved!")
                                    .font(AppFont.body())
                                    .foregroundColor(.accentGreen)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        VStack(spacing: 12) {
                            PrimaryButton("Save Keeper", icon: "checkmark") { saveKeeper() }
                            SecondaryButton("Cancel") { presentationMode.wrappedValue.dismiss() }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(keeper == nil ? "New Keeper" : "Edit Keeper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func saveKeeper() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { showValidationError = true }
            return
        }
        showValidationError = false
        var newKeeper = keeper ?? Keeper(name: "", team: "", notes: "")
        newKeeper.name = name.trimmingCharacters(in: .whitespaces)
        newKeeper.team = team
        newKeeper.notes = notes
        newKeeper.updatedAt = Date()

        if keeper != nil {
            keeperStore.update(newKeeper)
        } else {
            onSave(newKeeper)
        }
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(.textSecondary)
            TextField(placeholder, text: $text)
                .font(AppFont.body())
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.bgDark.opacity(0.5))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.accentGreen.opacity(0.2), lineWidth: 1))
                )
        }
    }
}

struct KeeperDetailView: View {
    let keeper: Keeper
    @EnvironmentObject var keeperStore: KeeperStore
    @EnvironmentObject var penaltyStore: PenaltyStore
    @EnvironmentObject var taskStore: TaskStore
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var showAddPenalty = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentGreen.opacity(0.12))
                                    .frame(width: 80, height: 80)
                                Text(keeper.name.prefix(2).uppercased())
                                    .font(AppFont.headline(28))
                                    .foregroundColor(.accentGreen)
                            }
                            Text(keeper.name)
                                .font(AppFont.title(24))
                                .foregroundColor(.textPrimary)
                            if !keeper.team.isEmpty {
                                Text(keeper.team)
                                    .font(AppFont.body())
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(.top, 8)

                        // Stats
                        let analytics = penaltyStore.analytics(for: keeper.id)
                        HStack(spacing: 12) {
                            StatBadge(label: "Penalties", value: "\(analytics.totalPenalties)", color: .chartZone)
                            StatBadge(label: "Save Rate", value: String(format: "%.0f%%", analytics.saveRate), color: .accentGreen)
                            StatBadge(label: "Scored", value: "\(analytics.scored)", color: .chartMiss)
                        }
                        .padding(.horizontal, 16)

                        // Dive heat map preview
                        NavigationLink(destination: DiveMapView(keeperID: keeper.id)) {
                            AppCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Dive Map")
                                            .font(AppFont.headline())
                                            .foregroundColor(.textPrimary)
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                            .foregroundColor(.accentGreen)
                                    }
                                    MiniHeatMap(analytics: analytics)
                                        .frame(height: 80)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Recent penalties
                        let recentPenalties = penaltyStore.penalties(for: keeper.id).sorted { $0.date > $1.date }
                        if !recentPenalties.isEmpty {
                            VStack(spacing: 10) {
                                SectionHeader(title: "Recent Penalties")
                                    .padding(.horizontal, 16)
                                ForEach(recentPenalties.prefix(5)) { p in
                                    PenaltyRowView(record: p)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }

                        // Notes
                        if !keeper.notes.isEmpty {
                            AppCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Notes")
                                        .font(AppFont.caption())
                                        .foregroundColor(.textSecondary)
                                    Text(keeper.notes)
                                        .font(AppFont.body())
                                        .foregroundColor(.textPrimary)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Action buttons
                        VStack(spacing: 12) {
                            PrimaryButton("Add Penalty", icon: "plus.circle.fill") { showAddPenalty = true }
                            SecondaryButton("Edit Profile", icon: "pencil") { showEdit = true }
                            Button(action: { showDeleteConfirm = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Keeper")
                                }
                                .foregroundColor(.chartMiss)
                                .font(AppFont.body())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 32)
                    }
                }
            }
            .navigationTitle(keeper.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.accentGreen)
                }
            }
            .sheet(isPresented: $showEdit) {
                AddEditKeeperView(keeper: keeper) { _ in }
            }
            .sheet(isPresented: $showAddPenalty) {
                AddPenaltyView(preselectedKeeperID: keeper.id)
            }
            .alert("Delete Keeper?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    keeperStore.delete(keeper)
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will also delete all associated data.")
            }
        }
    }
}

struct MiniHeatMap: View {
    let analytics: AnalyticsSummary
    private let zones = PenaltyZone.allCases

    var maxCount: Int {
        zones.map { analytics.zoneHeatData[$0] ?? 0 }.max() ?? 1
    }

    var body: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / 3
            let cellH = geo.size.height / 3
            ZStack {
                // Goal frame
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)

                ForEach(zones, id: \.self) { zone in
                    let count = analytics.zoneHeatData[zone] ?? 0
                    let intensity = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                    Rectangle()
                        .fill(heatColor(intensity: intensity))
                        .frame(width: cellW - 2, height: cellH - 2)
                        .cornerRadius(3)
                        .position(
                            x: CGFloat(zone.col) * cellW + cellW / 2,
                            y: CGFloat(zone.row) * cellH + cellH / 2
                        )
                }
            }
        }
    }

    func heatColor(intensity: CGFloat) -> Color {
        if intensity < 0.01 { return Color.bgDark.opacity(0.3) }
        return Color(
            red: 0.14 + Double(intensity) * 0.72,
            green: 0.77 - Double(intensity) * 0.4,
            blue: 0.37 - Double(intensity) * 0.2
        )
    }
}

struct PenaltyRowView: View {
    let record: PenaltyRecord

    var body: some View {
        AppCard(padding: 12) {
            HStack(spacing: 12) {
                Image(systemName: record.outcome.icon)
                    .foregroundColor(record.outcome.color)
                    .font(.system(size: 18))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(record.shotZone.label) → \(record.diveDirection.rawValue)")
                        .font(AppFont.body(13))
                        .foregroundColor(.textPrimary)
                    Text(record.outcome.rawValue)
                        .font(AppFont.caption(11))
                        .foregroundColor(record.outcome.color)
                }

                Spacer()

                Text(record.date, style: .date)
                    .font(AppFont.caption(11))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}
