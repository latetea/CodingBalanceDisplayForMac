import Foundation

public enum UsagePresentationBuilder {
    public static func menuBarDisplay(
        snapshot: AccountSnapshot?,
        now: Date = Date()
    ) -> MenuBarDisplay {
        guard let snapshot else {
            return MenuBarDisplay(topLine: "今--", bottomLine: "余--")
        }

        if let response = snapshot.response {
            return MenuBarDisplay(
                topLine: "今\(todayCostDisplay(from: response))",
                bottomLine: "余\(balanceAmountDisplay(from: response))"
            )
        }

        if snapshot.errorMessage != nil {
            return MenuBarDisplay(topLine: "今--", bottomLine: "余--")
        }

        return MenuBarDisplay(topLine: "今--", bottomLine: "余--")
    }

    public static func title(
        accountName: String,
        snapshot: AccountSnapshot?,
        now: Date = Date()
    ) -> String {
        let compactName = truncatedAccountName(accountName)

        guard let snapshot else {
            return "\(compactName) 未刷新"
        }

        if let response = snapshot.response {
            return "\(compactName) \(primaryDisplay(from: response, now: now))"
        }

        if snapshot.errorMessage != nil {
            return "\(compactName) 错误"
        }

        return "\(compactName) 未刷新"
    }

    public static func primaryDisplay(
        from response: UsageResponse,
        now: Date = Date()
    ) -> String {
        if response.status?.lowercased() == "quota_exhausted" {
            return "已用满"
        }

        if let remaining = response.effectiveRemaining,
           response.mode?.lowercased() == "quota_limited",
           remaining.isLessThanOrEqualToZero {
            return "已用满"
        }

        if let expiresAt = response.expiresAt, expiresAt <= now {
            return "已到期"
        }

        if response.daysUntilExpiry == 0 {
            return "今日到期"
        }

        if let remaining = response.effectiveRemaining {
            return formattedCurrency(remaining, unit: response.unit ?? response.quota?.unit)
        }

        if let localizedStatus = localizedStatus(response.status) {
            return localizedStatus
        }

        return "暂无数据"
    }

    public static func makePresentation(
        response: UsageResponse,
        snapshot: AccountSnapshot? = nil,
        now: Date = Date()
    ) -> UsagePresentation {
        let subtitle = [response.planName?.trimmed, localizedMode(response.mode)]
            .compactMap { $0 }
            .joined(separator: " · ")

        let statusLine = localizedStatus(response.status).map { "状态：\($0)" }

        let balanceValue = response.effectiveRemaining.map {
            formattedCurrency($0, unit: response.unit ?? response.quota?.unit)
        }
        let balanceLine = balanceValue.map { "可用余额：\($0)" }

        let quotaLine = makeQuotaLine(response: response)
        let expiryLine = makeExpiryLine(response: response, now: now)
        let todayLine = makeUsageLine(label: "今日", stats: response.usage?.today, unit: response.unit)
        let totalLine = makeUsageLine(label: "累计", stats: response.usage?.total, unit: response.unit)
        let updatedAtLine = snapshot?.lastUpdated.map { "最近刷新：\(DateFormatting.menuString(from: $0))" }
        let errorLine = snapshot?.errorMessage.map { "最近一次刷新失败：\($0)" }

        return UsagePresentation(
            primaryDisplay: primaryDisplay(from: response, now: now),
            subtitle: subtitle.isEmpty ? "余额概览" : subtitle,
            statusLine: statusLine,
            balanceLine: balanceLine,
            quotaLine: quotaLine,
            expiryLine: expiryLine,
            todayLine: todayLine,
            totalLine: totalLine,
            updatedAtLine: updatedAtLine,
            errorLine: errorLine
        )
    }

    public static func formattedCurrency(_ value: Decimal, unit: String?) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let normalizedUnit = unit?.uppercased()
        if normalizedUnit == nil || normalizedUnit == "USD" {
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.currencySymbol = "$"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            let formatted = formatter.string(from: number) ?? "$\(number.stringValue)"
            return normalizedCurrencySpacing(formatted)
        }

        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: number) ?? number.stringValue
        return "\(formatted) \(normalizedUnit!)"
    }

    private static func normalizedCurrencySpacing(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: "\u{202F}", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    static func localizedMode(_ mode: String?) -> String? {
        switch mode?.lowercased() {
        case "unrestricted":
            return "不限额"
        case "quota_limited":
            return "配额模式"
        case let value?:
            return value
        case nil:
            return nil
        }
    }

    static func localizedStatus(_ status: String?) -> String? {
        switch status?.lowercased() {
        case "quota_exhausted":
            return "已用满"
        case "active":
            return "可用"
        case "expired":
            return "已到期"
        case let value?:
            return value.replacingOccurrences(of: "_", with: " ")
        case nil:
            return nil
        }
    }

    private static func truncatedAccountName(_ value: String) -> String {
        let trimmedValue = value.trimmed
        guard trimmedValue.count > 12 else {
            return trimmedValue
        }

        let prefix = trimmedValue.prefix(12)
        return "\(prefix)…"
    }

    private static func makeQuotaLine(response: UsageResponse) -> String? {
        let unit = response.unit ?? response.quota?.unit

        if let quota = response.quota {
            let parts = [
                quota.limit.map { "上限 \(formattedCurrency($0, unit: unit))" },
                quota.used.map { "已用 \(formattedCurrency($0, unit: unit))" },
                quota.remaining.map { "剩余 \(formattedCurrency($0, unit: unit))" }
            ]
            .compactMap { $0 }

            if !parts.isEmpty {
                return "配额：\(parts.joined(separator: " · "))"
            }
        }

        return nil
    }

    private static func makeExpiryLine(response: UsageResponse, now: Date) -> String? {
        if let expiresAt = response.expiresAt {
            let prefix = expiresAt <= now ? "已到期：" : "到期时间："
            return "\(prefix)\(DateFormatting.menuString(from: expiresAt))"
        }

        if let days = response.daysUntilExpiry {
            return days == 0 ? "到期：今日" : "剩余有效期：\(days) 天"
        }

        return nil
    }

    private static func makeUsageLine(
        label: String,
        stats: UsageResponse.TokenStats?,
        unit: String?
    ) -> String? {
        guard let stats else {
            return nil
        }

        let cost = stats.actualCost ?? stats.cost
        let costText = cost.map { formattedCurrency($0, unit: unit) } ?? "--"
        let requestText = stats.requests.map(String.init) ?? "--"
        return "\(label)：\(costText) / \(requestText) 请求"
    }

    private static func todayCostDisplay(from response: UsageResponse) -> String {
        let cost = response.usage?.today?.actualCost ?? response.usage?.today?.cost
        return cost.map { formattedCurrency($0, unit: response.unit) } ?? "--"
    }

    private static func balanceAmountDisplay(from response: UsageResponse) -> String {
        let amount = response.effectiveRemaining
        return amount.map { formattedCurrency($0, unit: response.unit ?? response.quota?.unit) } ?? "--"
    }
}
