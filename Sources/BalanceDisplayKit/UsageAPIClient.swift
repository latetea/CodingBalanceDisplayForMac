import Foundation

public protocol UsageAPIClientProtocol {
    func fetchUsage(for account: AccountConfig) async throws -> UsageResponse
}

public enum UsageAPIError: LocalizedError, Equatable {
    case invalidBaseURL
    case invalidHTTPResponse
    case unauthorized
    case forbidden
    case httpStatus(Int)
    case transport(String)
    case decoding(String)

    public var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Base URL 无效。"
        case .invalidHTTPResponse:
            return "服务端返回了无法识别的响应。"
        case .unauthorized:
            return "API Key 无效或已失效。"
        case .forbidden:
            return "请求被服务端拒绝。"
        case let .httpStatus(code):
            return "服务端返回状态码 \(code)。"
        case let .transport(message):
            return "网络请求失败：\(message)"
        case let .decoding(message):
            return "接口数据解析失败：\(message)"
        }
    }
}

public struct UsageAPIClient: UsageAPIClientProtocol {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchUsage(for account: AccountConfig) async throws -> UsageResponse {
        guard let requestURL = makeRequestURL(baseURL: account.baseURL) else {
            throw UsageAPIError.invalidBaseURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("Bearer \(account.apiKey.trimmed)", forHTTPHeaderField: "Authorization")
        request.setValue("cc-switch/1.0", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw UsageAPIError.transport(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UsageAPIError.invalidHTTPResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw UsageAPIError.unauthorized
        case 403:
            throw UsageAPIError.forbidden
        default:
            throw UsageAPIError.httpStatus(httpResponse.statusCode)
        }

        do {
            return try UsageDecoding.makeDecoder().decode(UsageResponse.self, from: data)
        } catch {
            throw UsageAPIError.decoding(error.localizedDescription)
        }
    }

    private func makeRequestURL(baseURL: String) -> URL? {
        guard let url = URL(string: baseURL.trimmed) else {
            return nil
        }

        return url
            .appendingPathComponent("v1", isDirectory: true)
            .appendingPathComponent("usage", isDirectory: false)
    }
}
