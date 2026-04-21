import Foundation
import FirebaseFirestore

extension Timestamp {
    /// Returns a human-readable "X ago" string.
    func timeAgoDisplay() -> String {
        let diff = Calendar.current.dateComponents(
            [.year, .month, .weekOfYear, .day, .hour, .minute, .second],
            from: dateValue(), to: Date()
        )
        if let y  = diff.year,       y  >= 1 { return "\(y)y ago" }
        if let mo = diff.month,      mo >= 1 { return "\(mo)mo ago" }
        if let w  = diff.weekOfYear, w  >= 1 { return "\(w)w ago" }
        if let d  = diff.day,        d  >= 1 { return "\(d)d ago" }
        if let h  = diff.hour,       h  >= 1 { return "\(h)h ago" }
        if let m  = diff.minute,     m  >= 1 { return "\(m)m ago" }
        if let s  = diff.second,     s  >= 1 { return "\(s)s ago" }
        return "just now"
    }
}
