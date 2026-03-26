import Foundation

@MainActor
final class TaskCenter {
    static let shared = TaskCenter()
    static let didUpdateNotification = Notification.Name("ConnectMate.TaskCenter.didUpdate")

    private(set) var tasks: [TaskProgress] = [] {
        didSet {
            NotificationCenter.default.post(name: Self.didUpdateNotification, object: self)
        }
    }

    @discardableResult
    func startTask(title: String, detail: String) -> UUID {
        let task = TaskProgress(title: title, detail: detail, state: .running)
        tasks.insert(task, at: 0)
        return task.id
    }

    func updateTask(id: UUID, detail: String? = nil, fractionCompleted: Double? = nil, state: TaskState? = nil) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }

        if let detail {
            tasks[index].detail = detail
        }

        if let fractionCompleted {
            tasks[index].fractionCompleted = max(0, min(1, fractionCompleted))
        }

        if let state {
            tasks[index].state = state
            if [.succeeded, .failed, .cancelled].contains(state) {
                tasks[index].finishedAt = Date()
            }
        }
    }

    func finishTask(id: UUID, state: TaskState, detail: String? = nil) {
        updateTask(id: id, detail: detail, state: state)
    }

    func activeTasks() -> [TaskProgress] {
        tasks.filter { $0.state == .queued || $0.state == .running }
    }
}
