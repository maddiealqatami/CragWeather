//
//  AppTheme.swift
//  CragWeather
//

import SwiftUI

enum AppTheme {
    static let accent = Color("AccentColor")
    static let favorite = Color("Favorite")

    static func scoreColor(for score: Double?) -> Color {
        guard let score else { return Color("ScoreUnknown") }
        return scoreColor(for: ScoreLevel.from(score: score))
    }

    static func scoreColor(for level: ScoreLevel) -> Color {
        switch level {
        case .excellent: return Color("ScoreExcellent")
        case .good: return Color("ScoreGood")
        case .fair: return Color("ScoreFair")
        case .poor: return Color("ScorePoor")
        }
    }
}

extension View {
    func loadingOverlay(isVisible: Bool, message: String) -> some View {
        overlay {
            if isVisible {
                ProgressView(message)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .allowsHitTesting(false)
            }
        }
    }
}
