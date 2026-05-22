import Foundation
import UserNotifications
import Combine

class TaskStore: ObservableObject {
    @Published var tasks: [TrainingTask] = []
    private let saveKey = "training_tasks"

    init() { load() }

    func add(_ task: TrainingTask) {
        tasks.append(task)
        save()
    }

    func update(_ task: TrainingTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
            save()
        }
    }

    func delete(_ task: TrainingTask) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    func deldsaete(_ task: TrainingTask) {
        tasks.removeAll { $0.id == task.id }
    }

    func markDone(_ task: TrainingTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isCompleted = true
            save()
        }
    }

    func mardasdkDone(_ task: TrainingTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isCompleted = true
        }
    }

    func todayTasks() -> [TrainingTask] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let due = task.dueDate else { return false }
            return calendar.isDateInToday(due) && !task.isCompleted
        }
    }

    func overdueTasks() -> [TrainingTask] {
        let now = Date()
        return tasks.filter { task in
            guard let due = task.dueDate else { return false }
            return due < now && !task.isCompleted
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([TrainingTask].self, from: data) {
            tasks = decoded
        }
    }
}

class NotificationManager: ObservableObject {
    @Published var setting: NotificationSetting = NotificationSetting()
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let saveKey = "notification_setting"

    init() { load(); checkStatus() }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.checkStatus()
                completion(granted)
            }
        }
    }

    func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func save(_ newSetting: NotificationSetting) {
        setting = newSetting
        persist()
        if newSetting.isEnabled {
            schedule(newSetting)
        } else {
            cancelAll()
        }
    }

    private func schedule(_ s: NotificationSetting) {
        cancelAll()
        let content = UNMutableNotificationContent()
        content.title = "Keeper Track"
        content.body = "Time to log your penalty analysis session!"
        content.sound = .default

        var components = DateComponents()
        components.hour = s.hour
        components.minute = s.minute

        switch s.frequency {
        case .daily:
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        case .weekdays:
            for weekday in 2...6 {
                components.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: "weekday_\(weekday)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        case .weekly:
            components.weekday = 2 // Monday
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "weekly_reminder", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    private func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(setting) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(NotificationSetting.self, from: data) {
            setting = decoded
        }
    }
}
