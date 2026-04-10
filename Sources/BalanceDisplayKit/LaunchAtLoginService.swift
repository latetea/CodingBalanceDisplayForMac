import Foundation
import ServiceManagement

public protocol LaunchAtLoginControlling {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

public enum LaunchAtLoginError: LocalizedError {
    case unavailable(String)

    public var errorDescription: String? {
        switch self {
        case let .unavailable(message):
            return message
        }
    }
}

public struct LaunchAtLoginService: LaunchAtLoginControlling {
    public init() {}

    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public func setEnabled(_ enabled: Bool) throws {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            throw LaunchAtLoginError.unavailable("无法更新开机启动状态：\(error.localizedDescription)")
        }
    }
}
