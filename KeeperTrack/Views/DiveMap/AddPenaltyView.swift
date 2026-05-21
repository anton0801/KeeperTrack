import SwiftUI

struct AddPenaltyView: View {
    let preselectedKeeperID: UUID?
    @EnvironmentObject var keeperStore: KeeperStore
    @EnvironmentObject var penaltyStore: PenaltyStore
    @State private var selectedKeeperID: UUID?
    @State private var selectedZone: PenaltyZone = .middleCenter
    @State private var diveDirection: DiveDirection = .center
    @State private var outcome: PenaltyOutcome = .saved
    @State private var notes: String = ""
    @State private var sessionTag: String = ""
    @State private var date: Date = Date()
    @State private var saved = false
    @State private var validationError = ""
    @Environment(\.presentationMode) var presentationMode

    init(preselectedKeeperID: UUID?) {
        self.preselectedKeeperID = preselectedKeeperID
        _selectedKeeperID = State(initialValue: preselectedKeeperID)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Keeper picker
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Goalkeeper")
                                    .font(AppFont.caption())
                                    .foregroundColor(.textSecondary)
                                if keeperStore.keepers.isEmpty {
                                    Text("No keepers yet — add one first.")
                                        .font(AppFont.body(13))
                                        .foregroundColor(.chartMiss)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(keeperStore.keepers) { keeper in
                                                Button(action: { selectedKeeperID = keeper.id }) {
                                                    Text(keeper.name)
                                                        .font(AppFont.body(13))
                                                        .foregroundColor(selectedKeeperID == keeper.id ? .bgDark : .textSecondary)
                                                        .padding(.horizontal, 14)
                                                        .padding(.vertical, 7)
                                                        .background(Capsule().fill(selectedKeeperID == keeper.id ? Color.accentGreen : Color.bgStadium.opacity(0.5)))
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Shot zone picker (goal grid)
                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Shot Zone — tap to select")
                                    .font(AppFont.caption())
                                    .foregroundColor(.textSecondary)

                                ZonePicker(selectedZone: $selectedZone)
                                    .frame(height: 140)
                            }
                        }
                        .padding(.horizontal, 16)

                        // Dive direction
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Keeper Dive Direction")
                                    .font(AppFont.caption())
                                    .foregroundColor(.textSecondary)
                                HStack(spacing: 10) {
                                    ForEach(DiveDirection.allCases, id: \.self) { dir in
                                        Button(action: { diveDirection = dir }) {
                                            VStack(spacing: 6) {
                                                Image(systemName: diveDirection == dir ? "figure.handball.circle.fill" : "figure.handball.circle")
                                                    .font(.system(size: 22))
                                                    .foregroundColor(diveDirection == dir ? dirColor(dir) : .textSecondary.opacity(0.5))
                                                Text(dir.rawValue)
                                                    .font(AppFont.caption(12))
                                                    .foregroundColor(diveDirection == dir ? dirColor(dir) : .textSecondary)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(diveDirection == dir ? dirColor(dir).opacity(0.12) : Color.clear)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(diveDirection == dir ? dirColor(dir).opacity(0.4) : Color.clear, lineWidth: 1.5)
                                                    )
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Outcome
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Outcome")
                                    .font(AppFont.caption())
                                    .foregroundColor(.textSecondary)
                                HStack(spacing: 10) {
                                    ForEach(PenaltyOutcome.allCases, id: \.self) { o in
                                        Button(action: { outcome = o }) {
                                            VStack(spacing: 6) {
                                                Image(systemName: o.icon)
                                                    .font(.system(size: 22))
                                                    .foregroundColor(outcome == o ? o.color : .textSecondary.opacity(0.5))
                                                Text(o.rawValue)
                                                    .font(AppFont.caption(12))
                                                    .foregroundColor(outcome == o ? o.color : .textSecondary)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(outcome == o ? o.color.opacity(0.12) : Color.clear)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(outcome == o ? o.color.opacity(0.4) : Color.clear, lineWidth: 1.5)
                                                    )
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Details
                        AppCard {
                            VStack(spacing: 14) {
                                FormField(label: "Session Tag", placeholder: "e.g. Pre-match vs Arsenal", text: $sessionTag)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Date")
                                        .font(AppFont.caption())
                                        .foregroundColor(.textSecondary)
                                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                        .colorScheme(.dark)
                                        .labelsHidden()
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Notes")
                                        .font(AppFont.caption())
                                        .foregroundColor(.textSecondary)
                                    TextField("Optional notes...", text: $notes)
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
                        .padding(.horizontal, 16)

                        if !validationError.isEmpty {
                            Text(validationError)
                                .font(AppFont.body(13))
                                .foregroundColor(.chartMiss)
                                .padding(.horizontal, 16)
                        }

                        if saved {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.accentGreen)
                                Text("Penalty saved!").font(AppFont.body()).foregroundColor(.accentGreen)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        VStack(spacing: 12) {
                            PrimaryButton("Save Penalty", icon: "checkmark") { savePenalty() }
                            SecondaryButton("Cancel") { presentationMode.wrappedValue.dismiss() }
                        }
                        .padding(.horizontal, 16)
                        Spacer().frame(height: 32)
                    }
                }
            }
            .navigationTitle("Add Penalty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func dirColor(_ d: DiveDirection) -> Color {
        switch d {
        case .left: return .chartZone
        case .center: return .accentYellow
        case .right: return .accentOrange
        }
    }

    private func savePenalty() {
        guard let keeperID = selectedKeeperID else {
            withAnimation { validationError = "Please select a goalkeeper" }
            return
        }
        validationError = ""
        let record = PenaltyRecord(
            keeperID: keeperID, date: date, shotZone: selectedZone,
            diveDirection: diveDirection, outcome: outcome, notes: notes, sessionTag: sessionTag
        )
        penaltyStore.add(record)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { presentationMode.wrappedValue.dismiss() }
    }
}

struct OfflineView: View {
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("traawck")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 3)
                    .opacity(0.6)
                
                Image("traawack")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}


struct ZonePicker: View {
    @Binding var selectedZone: PenaltyZone
    private let zones = PenaltyZone.allCases

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cellW = w / 3
            let cellH = h / 3

            ZStack {
                // Goal outline
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)

                ForEach(zones, id: \.self) { zone in
                    let isSelected = selectedZone == zone
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                            selectedZone = zone
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isSelected ? Color.accentGreen.opacity(0.35) : Color.bgDark.opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(isSelected ? Color.accentGreen : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
                                )
                                .scaleEffect(isSelected ? 0.95 : 1.0)
                            if isSelected {
                                Image(systemName: "soccerball")
                                    .font(.system(size: 14))
                                    .foregroundColor(.accentGreen)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: cellW - 4, height: cellH - 4)
                    .position(
                        x: CGFloat(zone.col) * cellW + cellW / 2,
                        y: CGFloat(zone.row) * cellH + cellH / 2
                    )
                }
            }
        }
    }
}

// MARK: - Penalty History
struct PenaltyHistoryView: View {
    let keeperID: UUID?
    @EnvironmentObject var penaltyStore: PenaltyStore
    @EnvironmentObject var keeperStore: KeeperStore
    @State private var filterOutcome: PenaltyOutcome? = nil
    @State private var showDeleteConfirm: PenaltyRecord? = nil

    private var records: [PenaltyRecord] {
        let base = keeperID != nil ? penaltyStore.penalties(for: keeperID!) : penaltyStore.penalties
        let sorted = base.sorted { $0.date > $1.date }
        if let f = filterOutcome { return sorted.filter { $0.outcome == f } }
        return sorted
    }

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                // Filter bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        filterChip(label: "All", color: .textSecondary, isSelected: filterOutcome == nil) {
                            filterOutcome = nil
                        }
                        ForEach(PenaltyOutcome.allCases, id: \.self) { o in
                            filterChip(label: o.rawValue, color: o.color, isSelected: filterOutcome == o) {
                                filterOutcome = filterOutcome == o ? nil : o
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                if records.isEmpty {
                    Spacer()
                    EmptyStateView(icon: "clock.fill", title: "No Records", subtitle: "Add penalties to build your history.")
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(records) { record in
                                HistoryRowView(record: record, keeperName: keeperStore.keepers.first(where: { $0.id == record.keeperID })?.name ?? "Unknown")
                                    .contextMenu {
                                        Button(role: .destructive) { showDeleteConfirm = record } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Delete penalty record?", isPresented: Binding(get: { showDeleteConfirm != nil }, set: { if !$0 { showDeleteConfirm = nil } })) {
            Button("Delete", role: .destructive) {
                if let r = showDeleteConfirm { penaltyStore.delete(r) }
                showDeleteConfirm = nil
            }
            Button("Cancel", role: .cancel) { showDeleteConfirm = nil }
        }
    }

    @ViewBuilder
    func filterChip(label: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.body(13))
                .foregroundColor(isSelected ? .bgDark : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(isSelected ? color : Color.bgStadium.opacity(0.4)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HistoryRowView: View {
    let record: PenaltyRecord
    let keeperName: String

    var body: some View {
        AppCard(padding: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(record.outcome.color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: record.outcome.icon)
                        .foregroundColor(record.outcome.color)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(keeperName)
                        .font(AppFont.headline(14))
                        .foregroundColor(.textPrimary)
                    HStack(spacing: 8) {
                        Text(record.shotZone.label)
                            .font(AppFont.body(12))
                            .foregroundColor(.textSecondary)
                        Text("→")
                            .foregroundColor(.textSecondary.opacity(0.5))
                        Text(record.diveDirection.rawValue)
                            .font(AppFont.body(12))
                            .foregroundColor(.textSecondary)
                    }
                    if !record.sessionTag.isEmpty {
                        Text(record.sessionTag)
                            .font(AppFont.caption(11))
                            .foregroundColor(.accentYellow.opacity(0.8))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(record.outcome.rawValue)
                        .font(AppFont.caption(11))
                        .foregroundColor(record.outcome.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(record.outcome.color.opacity(0.12)))
                    Text(record.date, style: .date)
                        .font(AppFont.caption(10))
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}
