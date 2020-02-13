import Foundation

public protocol RequestInterceptorType {
    func addHeaders(to request: URLRequest) -> URLRequest
}

public class RequestInterceptor: RequestInterceptorType {

    public init(userAccessToken: UserAccessTokenType) {
        self.userAccessToken = userAccessToken
    }

    // MARK: - RequestInterceptor

    public func addHeaders(to request: URLRequest) -> URLRequest {
        var newRequest = request

        if let token = self.userAccessToken.token {
            newRequest.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        }

        return newRequest
    }

    // MARK: - Privates

    private let userAccessToken: UserAccessTokenType

}
