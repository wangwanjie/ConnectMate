import Foundation

enum TaskState: String {
    case queued
    case running
    case succeeded
    case failed
    case cancelled
}

struct TaskProgress: Identifiable, Equatable {
    let id: UUID
    var title: String
    var detail: String
    var fractionCompleted: Double?
    var state: TaskState
    var startedAt: Date
    var finishedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        fractionCompleted: Double? = nil,
        state: TaskState = .queued,
        startedAt: Date = Date(),
        finishedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.fractionCompleted = fractionCompleted
        self.state = state
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }
}
