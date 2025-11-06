//
//  DateFormatters.swift
//  DiamondNotesVault
//
//  Created by Claude on 11/6/25 at 10:39.
//

import Foundation

enum DateFormatters {
    /// Filename date format: 2025 NOV 06
    static let filename: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM dd"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    /// Display date format: November 6, 2025
    static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Relative date format: "2 hours ago"
    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}
