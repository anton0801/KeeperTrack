import SwiftUI

struct TrainingView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var keeperStore: KeeperStore
    @State private var showAddTask = false
    @State private var filter: TaskFilter = .all
    @State private var editTask: TrainingTask?
    @State private var animateIn = false

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case overdue = "Overdue"
        case done = "Done"
    }

    private var filteredTasks: [TrainingTask] {
        switch filter {
        case .all: return taskStore.tasks.filter { !$0.isCompleted }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .today: return taskStore.todayTasks()
        case .overdue: return taskStore.overdueTasks()
        case .done: return taskStore.tasks.filter { $0.isCompleted }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Training")
                            .font(AppFont.title())
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button(action: { showAddTask = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.accentGreen)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    // Stats row
                    HStack(spacing: 10) {
                        miniTaskStat(label: "Total", value: "\(taskStore.tasks.count)", color: .chartZone)
                        miniTaskStat(label: "Today", value: "\(taskStore.todayTasks().count)", color: .accentOrange)
                        miniTaskStat(label: "Overdue", value: "\(taskStore.overdueTasks().count)", color: .chartMiss)
                        miniTaskStat(label: "Done", value: "\(taskStore.tasks.filter { $0.isCompleted }.count)", color: .accentGreen)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .opacity(animateIn ? 1 : 0)

                    // Filter tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(TaskFilter.allCases, id: \.self) { f in
                                Button(action: { withAnimation { filter = f } }) {
                                    Text(f.rawValue)
                                        .font(AppFont.body(13))
                                        .foregroundColor(filter == f ? .bgDark : .textSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(Capsule().fill(filter == f ? Color.accentGreen : Color.bgStadium.opacity(0.4)))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 12)

                    if filteredTasks.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "figure.run.circle",
                            title: "No Tasks",
                            subtitle: "Add training drills and tasks to track your work"
                        )
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTasks) { task in
                                    TrainingTaskCard(task: task)
                                        .onTapGesture { editTask = task }
                                        .transition(.asymmetric(insertion: .slide, removal: .opacity))
                                }
                                Spacer().frame(height: 100)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddTask) { AddEditTaskView(task: nil) }
            .sheet(item: $editTask) { task in AddEditTaskView(task: task) }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { animateIn = true }
        }
    }

    @ViewBuilder
    func miniTaskStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(AppFont.headline(18))
                .foregroundColor(color)
            Text(label)
                .font(AppFont.caption(11))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.08)))
    }
}

struct TrainingTaskCard: View {
    let task: TrainingTask
    @EnvironmentObject var taskStore: TaskStore
    @State private var isPressed = false

    private var isOverdue: Bool {
        guard let due = task.dueDate else { return false }
        return due < Date() && !task.isCompleted
    }

    var body: some View {
        AppCard(padding: 14) {
            HStack(spacing: 14) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        taskStore.markDone(task)
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(task.isCompleted ? Color.accentGreen : Color.textSecondary.opacity(0.3), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.accentGreen)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(task.title)
                        .font(AppFont.headline(14))
                        .foregroundColor(task.isCompleted ? .textSecondary : .textPrimary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)
                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(AppFont.body(12))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                    HStack(spacing: 8) {
                        if let due = task.dueDate {
                            Text(due, style: .date)
                                .labelStyle(.titleOnly)
                                .font(AppFont.caption(11))
                                .foregroundColor(isOverdue ? .chartMiss : .textSecondary)
                        }
                        Spacer()
                        priorityBadge(task.priority)
                    }
                }
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { p in isPressed = p }, perform: {})
    }

    @ViewBuilder
    func priorityBadge(_ p: TrainingTask.TaskPriority) -> some View {
        Text(p.rawValue)
            .font(AppFont.caption(10))
            .foregroundColor(p.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(p.color.opacity(0.12)))
    }
}

struct AddEditTaskView: View {
    let task: TrainingTask?
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var keeperStore: KeeperStore
    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
    @State private var priority: TrainingTask.TaskPriority = .medium
    @State private var selectedKeeperID: UUID?
    @State private var saved = false
    @State private var validationError = ""
    @Environment(\.presentationMode) var presentationMode

    init(task: TrainingTask?) {
        self.task = task
        if let t = task {
            _title = State(initialValue: t.title)
            _notes = State(initialValue: t.notes)
            _priority = State(initialValue: t.priority)
            _selectedKeeperID = State(initialValue: t.keeperID)
            if let d = t.dueDate { _dueDate = State(initialValue: d); _hasDueDate = State(initialValue: true) }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        AppCard {
                            VStack(spacing: 14) {
                                FormField(label: "Title *", placeholder: "e.g. Left-side reaction training", text: $title)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Notes")
                                        .font(AppFont.caption())
                                        .foregroundColor(.textSecondary)
                                    TextField("Details...", text: $notes)
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

                        AppCard {
                            VStack(spacing: 14) {
                                // Priority
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
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 7)
                                                    .background(Capsule().fill(priority == p ? p.color : Color.bgStadium.opacity(0.3)))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }

                                // Due date toggle
                                HStack {
                                    Text("Set Due Date")
                                        .font(AppFont.body())
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Toggle("", isOn: $hasDueDate)
                                        .tint(Color.accentGreen)
                                }

                                if hasDueDate {
                                    DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                        .colorScheme(.dark)
                                        .labelsHidden()
                                }

                                // Keeper link
                                if !keeperStore.keepers.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Link to Keeper (optional)")
                                            .font(AppFont.caption())
                                            .foregroundColor(.textSecondary)
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                Button(action: { selectedKeeperID = nil }) {
                                                    Text("None")
                                                        .font(AppFont.body(13))
                                                        .foregroundColor(selectedKeeperID == nil ? .bgDark : .textSecondary)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(Capsule().fill(selectedKeeperID == nil ? Color.accentGreen : Color.bgStadium.opacity(0.4)))
                                                }
                                                .buttonStyle(PlainButtonStyle())

                                                ForEach(keeperStore.keepers) { keeper in
                                                    Button(action: { selectedKeeperID = keeper.id }) {
                                                        Text(keeper.name)
                                                            .font(AppFont.body(13))
                                                            .foregroundColor(selectedKeeperID == keeper.id ? .bgDark : .textSecondary)
                                                            .padding(.horizontal, 12)
                                                            .padding(.vertical, 6)
                                                            .background(Capsule().fill(selectedKeeperID == keeper.id ? Color.accentGreen : Color.bgStadium.opacity(0.4)))
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        if !validationError.isEmpty {
                            Text(validationError).font(AppFont.body(13)).foregroundColor(.chartMiss).padding(.horizontal, 16)
                        }
                        if saved {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.accentGreen)
                                Text("Task saved!").font(AppFont.body()).foregroundColor(.accentGreen)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        VStack(spacing: 12) {
                            PrimaryButton("Save Task", icon: "checkmark") { saveTask() }
                            if task != nil {
                                Button(action: {
                                    if let t = task { taskStore.delete(t) }
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Text("Delete Task").foregroundColor(.chartMiss).font(AppFont.body())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            SecondaryButton("Cancel") { presentationMode.wrappedValue.dismiss() }
                        }
                        .padding(.horizontal, 16)
                        Spacer().frame(height: 32)
                    }
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func saveTask() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { validationError = "Title is required" }
            return
        }
        validationError = ""
        var t = task ?? TrainingTask(title: "")
        t.title = title.trimmingCharacters(in: .whitespaces)
        t.notes = notes
        t.priority = priority
        t.dueDate = hasDueDate ? dueDate : nil
        t.keeperID = selectedKeeperID
        if task != nil { taskStore.update(t) } else { taskStore.add(t) }
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { presentationMode.wrappedValue.dismiss() }
    }
}
