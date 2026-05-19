import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var penaltyStore: PenaltyStore
    @EnvironmentObject var keeperStore: KeeperStore
    @EnvironmentObject var taskStore: TaskStore

    @AppStorage("useMetricUnits") private var useMetricUnits = true
    @AppStorage("selectedLanguage") private var selectedLanguage = "English"

    @State private var notifSetting: NotificationSetting = NotificationSetting()
    @State private var showNotifPermissionAlert = false
    @State private var showClearDataConfirm = false
    @State private var showClearConfirmation = false
    @State private var showShareSheet = false
    @State private var exportText = ""
    @State private var showResetOnboarding = false

    private let languages = ["English", "Spanish", "German", "French", "Russian"]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // APPEARANCE
                    settingsSection(title: "Appearance") {
                        VStack(spacing: 0) {
                            settingsRow(icon: "paintpalette.fill", iconColor: .accentOrange, title: "Color Theme") {
                                HStack(spacing: 8) {
                                    ForEach(AppState.ColorTheme.allCases, id: \.self) { theme in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                                appState.colorTheme = theme
                                            }
                                        }) {
                                            Text(theme.label)
                                                .font(AppFont.body(13))
                                                .foregroundColor(appState.colorTheme == theme ? .bgDark : .textSecondary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Capsule().fill(appState.colorTheme == theme ? Color.accentGreen : Color.bgStadium.opacity(0.4)))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }

                            Divider().background(Color.accentGreen.opacity(0.1)).padding(.leading, 52)

                            settingsRow(icon: "speedometer", iconColor: .accentYellow, title: "Animation Speed") {
                                HStack(spacing: 10) {
                                    Text("Slow")
                                        .font(AppFont.caption(11))
                                        .foregroundColor(.textSecondary)
                                    Slider(value: $appState.animationSpeed, in: 0.5...2.0, step: 0.5)
                                        .tint(Color.accentGreen)
                                        .frame(width: 120)
                                    Text("Fast")
                                        .font(AppFont.caption(11))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                    }

                    // NOTIFICATIONS
                    settingsSection(title: "Notifications") {
                        VStack(spacing: 0) {
                            settingsRow(icon: "bell.fill", iconColor: .chartMiss, title: "Reminders") {
                                Toggle("", isOn: Binding(
                                    get: { notifSetting.isEnabled },
                                    set: { newVal in
                                        if newVal && notificationManager.authorizationStatus != .authorized {
                                            notificationManager.requestPermission { granted in
                                                if granted {
                                                    notifSetting.isEnabled = true
                                                    notificationManager.save(notifSetting)
                                                } else {
                                                    showNotifPermissionAlert = true
                                                }
                                            }
                                        } else {
                                            notifSetting.isEnabled = newVal
                                            notificationManager.save(notifSetting)
                                        }
                                    }
                                ))
                                .tint(Color.accentGreen)
                            }

                            if notifSetting.isEnabled {
                                Divider().background(Color.accentGreen.opacity(0.1)).padding(.leading, 52)

                                settingsRow(icon: "clock.fill", iconColor: .accentGreen, title: "Time") {
                                    DatePicker("", selection: Binding(
                                        get: {
                                            var c = Calendar.current.dateComponents([.hour, .minute], from: Date())
                                            c.hour = notifSetting.hour
                                            c.minute = notifSetting.minute
                                            return Calendar.current.date(from: c) ?? Date()
                                        },
                                        set: { newDate in
                                            let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                            notifSetting.hour = c.hour ?? 9
                                            notifSetting.minute = c.minute ?? 0
                                            notificationManager.save(notifSetting)
                                        }
                                    ), displayedComponents: .hourAndMinute)
                                    .colorScheme(.dark)
                                    .labelsHidden()
                                }

                                Divider().background(Color.accentGreen.opacity(0.1)).padding(.leading, 52)

                                settingsRow(icon: "repeat", iconColor: .chartZone, title: "Frequency") {
                                    Picker("", selection: Binding(
                                        get: { notifSetting.frequency },
                                        set: { notifSetting.frequency = $0; notificationManager.save(notifSetting) }
                                    )) {
                                        ForEach(NotificationSetting.NotificationFrequency.allCases, id: \.self) { f in
                                            Text(f.rawValue).tag(f)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color.accentGreen)
                                }
                            }
                        }
                    }

                    // DATA
                    settingsSection(title: "Data") {
                        VStack(spacing: 0) {
                            settingsRow(icon: "ruler.fill", iconColor: .accentGreen, title: "Units") {
                                Toggle("Metric", isOn: $useMetricUnits)
                                    .tint(Color.accentGreen)
                                    .font(AppFont.body(13))
                                    .foregroundColor(.textSecondary)
                            }

                            Divider().background(Color.accentGreen.opacity(0.1)).padding(.leading, 52)

                            settingsRow(icon: "square.and.arrow.up.fill", iconColor: .chartZone, title: "Export Data") {
                                Button(action: {
                                    exportText = generateExportText()
                                    showShareSheet = true
                                }) {
                                    Text("Export")
                                        .font(AppFont.body(13))
                                        .foregroundColor(.accentGreen)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            Divider().background(Color.accentGreen.opacity(0.1)).padding(.leading, 52)

                            settingsRow(icon: "trash.fill", iconColor: .chartMiss, title: "Clear All Data") {
                                Button(action: { showClearDataConfirm = true }) {
                                    Text("Clear")
                                        .font(AppFont.body(13))
                                        .foregroundColor(.chartMiss)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    // GENERAL
                    settingsSection(title: "General") {
                        VStack(spacing: 0) {
                            settingsRow(icon: "globe", iconColor: .accentYellow, title: "Language") {
                                Picker("", selection: $selectedLanguage) {
                                    ForEach(languages, id: \.self) { lang in
                                        Text(lang).tag(lang)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color.accentGreen)
                            }

                            Divider().background(Color.accentGreen.opacity(0.1)).padding(.leading, 52)

                            settingsRow(icon: "arrow.counterclockwise", iconColor: .textSecondary, title: "Reset Onboarding") {
                                Button(action: { showResetOnboarding = true }) {
                                    Text("Reset")
                                        .font(AppFont.body(13))
                                        .foregroundColor(.textSecondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    // App info
                    VStack(spacing: 4) {
                        Text("Keeper Track")
                            .font(AppFont.body(13))
                            .foregroundColor(.textSecondary)
                        Text("v1.0.0 • Built with SwiftUI")
                            .font(AppFont.caption())
                            .foregroundColor(.textSecondary.opacity(0.5))
                    }
                    .padding(.top, 8)

                    Spacer().frame(height: 100)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { notifSetting = notificationManager.setting }
        .alert("Notification Permission Required", isPresented: $showNotifPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in Settings to use reminders.")
        }
        .alert("Clear All Data?", isPresented: $showClearDataConfirm) {
            Button("Clear Everything", role: .destructive) {
                clearAllData()
                showClearConfirmation = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all keepers, penalties, and tasks. This cannot be undone.")
        }
        .alert("Data Cleared", isPresented: $showClearConfirmation) {
            Button("OK") {}
        } message: {
            Text("All app data has been removed.")
        }
        .alert("Reset Onboarding?", isPresented: $showResetOnboarding) {
            Button("Reset", role: .destructive) {
                // We don't actually dismiss here since that would navigate away
                // Just mark as not completed so next launch shows onboarding
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [exportText])
        }
    }

    @ViewBuilder
    func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(AppFont.caption(12))
                .foregroundColor(.textSecondary.opacity(0.6))
                .padding(.horizontal, 16)

            content()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.bgStadium.opacity(0.45))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.accentGreen.opacity(0.12), lineWidth: 1))
                )
                .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    func settingsRow<Trailing: View>(icon: String, iconColor: Color, title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(AppFont.body())
                .foregroundColor(.textPrimary)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func clearAllData() {
        keeperStore.keepers.removeAll()
        penaltyStore.penalties.removeAll()
        taskStore.tasks.removeAll()
        UserDefaults.standard.removeObject(forKey: "keeper_profiles")
        UserDefaults.standard.removeObject(forKey: "penalty_records")
        UserDefaults.standard.removeObject(forKey: "training_tasks")
    }

    private func generateExportText() -> String {
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        var lines = ["Keeper Track Data Export", "Exported: \(dateStr)", "", "=== KEEPERS ==="]
        for keeper in keeperStore.keepers {
            let rate = penaltyStore.saveRate(for: keeper.id)
            let count = penaltyStore.penalties(for: keeper.id).count
            lines.append("\(keeper.name) | \(keeper.team) | \(count) penalties | \(String(format: "%.0f%%", rate)) save rate")
        }
        lines.append("\n=== PENALTIES ===")
        for record in penaltyStore.penalties.sorted(by: { $0.date > $1.date }) {
            let keeperName = keeperStore.keepers.first { $0.id == record.keeperID }?.name ?? "?"
            let dateStr2 = DateFormatter.localizedString(from: record.date, dateStyle: .short, timeStyle: .none)
            lines.append("\(dateStr2) | \(keeperName) | \(record.shotZone.label) | Dive:\(record.diveDirection.rawValue) | \(record.outcome.rawValue)")
        }
        return lines.joined(separator: "\n")
    }
}
