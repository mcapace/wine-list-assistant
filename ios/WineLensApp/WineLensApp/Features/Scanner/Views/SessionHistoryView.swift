import SwiftUI
import UIKit

struct SessionHistoryView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var sessions: [ScanSession] = []
    @State private var selectedSession: ScanSession?
    @State private var showSessionDetail = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.95),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if sessions.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(sessions) { session in
                                SessionCard(session: session) {
                                    selectedSession = session
                                    showSessionDetail = true
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            sessionManager.deleteSession(session.id)
                                            loadSessions()
                                        }
                                        // Use UISelectionFeedbackGenerator directly to avoid indexing issues with HapticManager
                                        let generator = UISelectionFeedbackGenerator()
                                        generator.selectionChanged()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Scan History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.secondaryColor)
                }
            }
            .onAppear {
                loadSessions()
            }
            .sheet(isPresented: $showSessionDetail) {
                if let session = selectedSession {
                    SessionDetailView(session: session)
                }
            }
        }
    }
    
    private func loadSessions() {
        sessions = sessionManager.loadSessionHistory()
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: ScanSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            // Use UIImpactFeedbackGenerator directly to avoid indexing issues with HapticManager
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let location = session.location {
                            Text(location)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("Scan Session")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text(session.startTime, style: .date)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Top score badge
                    if let topScore = session.topScore {
                        ZStack {
                            Circle()
                                .fill(Theme.scoreColor(for: topScore).opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Text("\(topScore)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.scoreColor(for: topScore))
                        }
                    }
                }
                
                HStack(spacing: 16) {
                    StatBadge(icon: "wineglass.fill", value: "\(session.matchedCount)", label: "matched")
                    
                    if let topScore = session.topScore {
                        StatBadge(icon: "star.fill", value: "\(topScore)", label: "top score")
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(value)
                .font(.system(size: 14, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.15))
        )
    }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
    let session: ScanSession
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWine: RecognizedWine?
    
    var matchedWines: [RecognizedWine] {
        session.wines.filter { $0.isMatched }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.95),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if matchedWines.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "wineglass")
                            .font(.system(size: 64))
                            .foregroundColor(Theme.secondaryColor.opacity(0.5))
                        
                        Text("No matched wines in this session")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    MatchedWinesListView(
                        matchedWines: matchedWines,
                        onWineTapped: { wine in
                            selectedWine = wine
                        }
                    )
                    .sheet(item: $selectedWine) { wine in
                        WineDetailSheet(recognizedWine: wine)
                    }
                }
            }
            .navigationTitle(session.location ?? "Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.secondaryColor)
                }
            }
        }
    }
}

// MARK: - Empty History View

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(Theme.secondaryColor.opacity(0.5))
            
            Text("No past sessions")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Your scan sessions will appear here")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

#Preview {
    SessionHistoryView()
}

