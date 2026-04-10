import Foundation

public struct AccountConfig: Codable, Identifiable, Equatable {
    public var id: UUID
    public var displayName: String
    public var baseURL: String
    public var apiKey: String

    public init(
        id: UUID = UUID(),
        displayName: String,
        baseURL: String,
        apiKey: String
    ) {
        self.id = id
        self.displayName = displayName.trimmed
        self.baseURL = baseURL.trimmed
        self.apiKey = apiKey.trimmed
    }
}

public struct SettingsState: Codable, Equatable {
    public var refreshIntervalSeconds: TimeInterval
    public var launchAtLogin: Bool

    public init(
        refreshIntervalSeconds: TimeInterval = 60,
        launchAtLogin: Bool = false
    ) {
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.launchAtLogin = launchAtLogin
    }
}

public struct AppConfiguration: Codable, Equatable {
    public var accounts: [AccountConfig]
    public var activeAccountID: UUID?
    public var settings: SettingsState

    public init(
        accounts: [AccountConfig] = [],
        activeAccountID: UUID? = nil,
        settings: SettingsState = SettingsState()
    ) {
        self.accounts = accounts
        self.activeAccountID = activeAccountID
        self.settings = settings
        normalizeActiveAccount()
    }

    public var activeAccount: AccountConfig? {
        if let activeAccountID {
            return accounts.first(where: { $0.id == activeAccountID }) ?? accounts.first
        }

        return accounts.first
    }

    public mutating func normalizeActiveAccount() {
        guard !accounts.isEmpty else {
            activeAccountID = nil
            return
        }

        if let activeAccountID, accounts.contains(where: { $0.id == activeAccountID }) {
            return
        }

        activeAccountID = accounts.first?.id
    }
}

public struct UsageResponse: Decodable, Equatable {
    public struct Quota: Decodable, Equatable {
        public var limit: Decimal?
        public var remaining: Decimal?
        public var unit: String?
        public var used: Decimal?

        public init(
            limit: Decimal? = nil,
            remaining: Decimal? = nil,
            unit: String? = nil,
            used: Decimal? = nil
        ) {
            self.limit = limit
            self.remaining = remaining
            self.unit = unit
            self.used = used
        }
    }

    public struct UsageStats: Decodable, Equatable {
        public var averageDurationMs: Double?
        public var rpm: Int?
        public var today: TokenStats?
        public var total: TokenStats?
        public var tpm: Int?

        public init(
            averageDurationMs: Double? = nil,
            rpm: Int? = nil,
            today: TokenStats? = nil,
            total: TokenStats? = nil,
            tpm: Int? = nil
        ) {
            self.averageDurationMs = averageDurationMs
            self.rpm = rpm
            self.today = today
            self.total = total
            self.tpm = tpm
        }
    }

    public struct TokenStats: Decodable, Equatable {
        public var actualCost: Decimal?
        public var cacheCreationTokens: Int?
        public var cacheReadTokens: Int?
        public var cost: Decimal?
        public var inputTokens: Int?
        public var outputTokens: Int?
        public var requests: Int?
        public var totalTokens: Int?

        public init(
            actualCost: Decimal? = nil,
            cacheCreationTokens: Int? = nil,
            cacheReadTokens: Int? = nil,
            cost: Decimal? = nil,
            inputTokens: Int? = nil,
            outputTokens: Int? = nil,
            requests: Int? = nil,
            totalTokens: Int? = nil
        ) {
            self.actualCost = actualCost
            self.cacheCreationTokens = cacheCreationTokens
            self.cacheReadTokens = cacheReadTokens
            self.cost = cost
            self.inputTokens = inputTokens
            self.outputTokens = outputTokens
            self.requests = requests
            self.totalTokens = totalTokens
        }
    }

    public struct ModelStat: Decodable, Equatable, Identifiable {
        public var model: String
        public var requests: Int?
        public var inputTokens: Int?
        public var outputTokens: Int?
        public var cacheCreationTokens: Int?
        public var cacheReadTokens: Int?
        public var totalTokens: Int?
        public var cost: Decimal?
        public var actualCost: Decimal?

        public var id: String { model }

        public init(
            model: String,
            requests: Int? = nil,
            inputTokens: Int? = nil,
            outputTokens: Int? = nil,
            cacheCreationTokens: Int? = nil,
            cacheReadTokens: Int? = nil,
            totalTokens: Int? = nil,
            cost: Decimal? = nil,
            actualCost: Decimal? = nil
        ) {
            self.model = model
            self.requests = requests
            self.inputTokens = inputTokens
            self.outputTokens = outputTokens
            self.cacheCreationTokens = cacheCreationTokens
            self.cacheReadTokens = cacheReadTokens
            self.totalTokens = totalTokens
            self.cost = cost
            self.actualCost = actualCost
        }
    }

    public var balance: Decimal?
    public var daysUntilExpiry: Int?
    public var expiresAt: Date?
    public var isValid: Bool?
    public var mode: String?
    public var modelStats: [ModelStat]
    public var planName: String?
    public var quota: Quota?
    public var remaining: Decimal?
    public var status: String?
    public var unit: String?
    public var usage: UsageStats?

    public var effectiveRemaining: Decimal? {
        remaining ?? balance ?? quota?.remaining
    }

    public init(
        balance: Decimal? = nil,
        daysUntilExpiry: Int? = nil,
        expiresAt: Date? = nil,
        isValid: Bool? = nil,
        mode: String? = nil,
        modelStats: [ModelStat] = [],
        planName: String? = nil,
        quota: Quota? = nil,
        remaining: Decimal? = nil,
        status: String? = nil,
        unit: String? = nil,
        usage: UsageStats? = nil
    ) {
        self.balance = balance
        self.daysUntilExpiry = daysUntilExpiry
        self.expiresAt = expiresAt
        self.isValid = isValid
        self.mode = mode
        self.modelStats = modelStats
        self.planName = planName
        self.quota = quota
        self.remaining = remaining
        self.status = status
        self.unit = unit
        self.usage = usage
    }
}

public struct AccountSnapshot: Equatable {
    public var response: UsageResponse?
    public var lastUpdated: Date?
    public var errorMessage: String?

    public init(
        response: UsageResponse? = nil,
        lastUpdated: Date? = nil,
        errorMessage: String? = nil
    ) {
        self.response = response
        self.lastUpdated = lastUpdated
        self.errorMessage = errorMessage
    }
}

public struct UsagePresentation: Equatable {
    public let primaryDisplay: String
    public let subtitle: String
    public let statusLine: String?
    public let balanceLine: String?
    public let quotaLine: String?
    public let expiryLine: String?
    public let todayLine: String?
    public let totalLine: String?
    public let updatedAtLine: String?
    public let errorLine: String?

    public init(
        primaryDisplay: String,
        subtitle: String,
        statusLine: String?,
        balanceLine: String?,
        quotaLine: String?,
        expiryLine: String?,
        todayLine: String?,
        totalLine: String?,
        updatedAtLine: String?,
        errorLine: String?
    ) {
        self.primaryDisplay = primaryDisplay
        self.subtitle = subtitle
        self.statusLine = statusLine
        self.balanceLine = balanceLine
        self.quotaLine = quotaLine
        self.expiryLine = expiryLine
        self.todayLine = todayLine
        self.totalLine = totalLine
        self.updatedAtLine = updatedAtLine
        self.errorLine = errorLine
    }
}

public struct MenuBarDisplay: Equatable {
    public let topLine: String
    public let bottomLine: String

    public init(
        topLine: String,
        bottomLine: String
    ) {
        self.topLine = topLine
        self.bottomLine = bottomLine
    }
}
