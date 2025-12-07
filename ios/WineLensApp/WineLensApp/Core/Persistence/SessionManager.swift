import Foundation

final class SessionManager {
    static let shared = SessionManager()
    
    private let userDefaults = UserDefaults.standard
    private let currentSessionKey = "current_scan_session"
    private let sessionHistoryKey = "scan_session_history"
    
    private init() {}
    
    // MARK: - Current Session
    
    func saveCurrentSession(_ session: ScanSession) {
        if let encoded = try? JSONEncoder().encode(session) {
            userDefaults.set(encoded, forKey: currentSessionKey)
        }
    }
    
    func loadCurrentSession() -> ScanSession? {
        guard let data = userDefaults.data(forKey: currentSessionKey),
              let session = try? JSONDecoder().decode(ScanSession.self, from: data) else {
            return nil
        }
        return session
    }
    
    func clearCurrentSession() {
        userDefaults.removeObject(forKey: currentSessionKey)
    }
    
    // MARK: - Session History
    
    func saveSession(_ session: ScanSession) {
        var history = loadSessionHistory()
        var updatedSession = session
        updatedSession.endTime = Date()
        history.append(updatedSession)
        
        // Keep only last 50 sessions
        if history.count > 50 {
            history = Array(history.suffix(50))
        }
        
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: sessionHistoryKey)
        }
    }
    
    func loadSessionHistory() -> [ScanSession] {
        guard let data = userDefaults.data(forKey: sessionHistoryKey),
              let history = try? JSONDecoder().decode([ScanSession].self, from: data) else {
            return []
        }
        return history.sorted { $0.startTime > $1.startTime } // Most recent first
    }
    
    func deleteSession(_ sessionId: UUID) {
        var history = loadSessionHistory()
        history.removeAll { $0.id == sessionId }
        
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: sessionHistoryKey)
        }
    }
}

