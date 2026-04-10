import Foundation

enum UsageDecoding {
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)

            if let date = DateFormatting.internetDateFormatter.date(from: rawValue) {
                return date
            }

            if let date = DateFormatting.internetDateWithFractionalSecondsFormatter.date(from: rawValue) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported date format: \(rawValue)"
            )
        }
        return decoder
    }
}

enum DateFormatting {
    static let internetDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let internetDateWithFractionalSecondsFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let menuDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static func menuString(from date: Date) -> String {
        menuDateFormatter.string(from: date)
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfTrimmedEmpty: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }
}

extension Decimal {
    static let zeroValue = Decimal(string: "0") ?? .zero

    var isLessThanOrEqualToZero: Bool {
        NSDecimalNumber(decimal: self).compare(NSDecimalNumber(decimal: .zeroValue)) != .orderedDescending
    }
}
