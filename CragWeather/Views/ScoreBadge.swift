//
//  ScoreBadge.swift
//  CragWeather
//

import SwiftUI

struct ScoreBadge: View {
    let score: Double?

    var body: some View {
        Text(displayText)
            .font(.headline.monospacedDigit())
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(levelColor, in: Circle())
    }

    private var displayText: String {
        guard let score else { return "—" }
        return String(format: "%.0f", score)
    }

    private var levelColor: Color {
        guard let score else { return .gray }
        switch ScoreLevel.from(score: score) {
        case .excellent: return .green
        case .good: return .mint
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

struct ScoreLevelLabel: View {
    let score: Double

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        switch ScoreLevel.from(score: score) {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }

    private var color: Color {
        switch ScoreLevel.from(score: score) {
        case .excellent: return .green
        case .good: return .mint
        case .fair: return .orange
        case .poor: return .red
        }
    }
}
