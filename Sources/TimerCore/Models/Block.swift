import Foundation

/// A block's outcome within a session — Blueprint §6.
public enum BlockOutcome: String, Equatable, Sendable, Codable {
    case upcoming
    case active
    case done
    case skipped
    case notReached
}

/// One of the six fixed phases of a practice session — Blueprint §7.
public struct Block: Equatable, Sendable, Codable {
    public let name: String
    public let baseline: Duration
    public var outcome: BlockOutcome
    public var timeSpent: Duration?
    public var wasAlerted: Bool

    public init(
        name: String,
        baseline: Duration,
        outcome: BlockOutcome = .upcoming,
        timeSpent: Duration? = nil,
        wasAlerted: Bool = false
    ) {
        self.name = name
        self.baseline = baseline
        self.outcome = outcome
        self.timeSpent = timeSpent
        self.wasAlerted = wasAlerted
    }
}

extension Block {
    /// The fixed six-block template — Blueprint §7. Not configurable in v1.
    public static let defaultTemplate: [Block] = [
        Block(name: "Requirements", baseline: .seconds(5 * 60)),
        Block(name: "Core Entities", baseline: .seconds(5 * 60)),
        Block(name: "API / System Interface", baseline: .seconds(5 * 60)),
        Block(name: "Data Flow", baseline: .seconds(5 * 60)),
        Block(name: "High-Level Design", baseline: .seconds(15 * 60)),
        Block(name: "Deep Dives", baseline: .seconds(10 * 60)),
    ]

    /// Data Flow is the only block that can be skipped — Blueprint §7.
    public static let skippableBlockName = "Data Flow"
}
