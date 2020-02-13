import Foundation

public protocol ApiRequest {
    var resourcePath: String { get }
    var method: ApiRequestMethod { get }
    var params: [String: Any] { get }
    var options: [ApiRequestOption] { get }
}

public extension ApiRequest {
    var params: [String: Any] {
        return [:]
    }

    var options: [ApiRequestOption] {
        return []
    }
}

public enum ApiRequestMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
    case update = "UPDATE"
    case put = "PUT"
}

public enum ApiRequestOption {
    case cache
    case json
}
