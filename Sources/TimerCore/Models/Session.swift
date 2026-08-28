import Foundation

/// A practice session's lifecycle — Blueprint §6.
public enum SessionStatus: String, Equatable, Sendable, Codable {
    case notStarted
    case inProgress
    case completed
    case cancelled
}

/// One practice session: six blocks, a session-level elapsed clock,
/// and the outcome once it ends — Blueprint §6, §9.
public struct Session: Equatable, Sendable, Codable {
    public let id: UUID
    public let startedAt: Date
    public var status: SessionStatus
    public var blocks: [Block]
    public var elapsed: Duration
    public var cancelledAtBlock: String?
    public var wasInterrupted: Bool

    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        status: SessionStatus = .notStarted,
        blocks: [Block] = Block.defaultTemplate,
        elapsed: Duration = .zero,
        cancelledAtBlock: String? = nil,
        wasInterrupted: Bool = false
    ) {
        self.id = id
        self.startedAt = startedAt
        self.status = status
        self.blocks = blocks
        self.elapsed = elapsed
        self.cancelledAtBlock = cancelledAtBlock
        self.wasInterrupted = wasInterrupted
    }
}

extension Session {
    /// Sum of all block baselines — Blueprint §7: 45m, fixed regardless
    /// of whether Data Flow is skipped in a given session.
    public static let target: Duration = Block.defaultTemplate.reduce(.zero) { $0 + $1.baseline }
}
