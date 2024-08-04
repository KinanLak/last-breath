import SwiftUI


struct Session: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var duration: TimeInterval = 0
    var BPMList: [BPMCheck] = []
    var highestBPM: Int?
    var lowestBPM: Int?
    var averageBPM: Int?
    //var location:
}

struct BPMCheck: Identifiable, Codable {
    var id = UUID()
    var seconds: TimeInterval
    var BPM: Int
}

struct ElapsedTime: Codable {
    var minutes: Int
    var seconds: Int
}

extension Array where Element == BPMCheck {
    func avgBPM() -> Int? {
        guard !isEmpty else { return nil }
        let sum = self.reduce(0) { $0 + Double($1.BPM) }
        return Int(sum / Double(count))
    }
    
    func maxBPM() -> Int? {
        return self.map { $0.BPM }.max()
    }
    
    func minBPM() -> Int? {
        return self.map { $0.BPM }.min()
    }
}

extension Session: Equatable {
    static func == (lhs: Session, rhs: Session) -> Bool {
        return lhs.id == rhs.id
    }
}
