import Foundation

protocol RequestInterceptorType {
    func addHeaders(to request: URLRequest) -> URLRequest
}

class RequestInterceptor: RequestInterceptorType {

    init(userAccessToken: UserAccessTokenType) {
        self.userAccessToken = userAccessToken
    }

    // MARK: - RequestInterceptor

    func addHeaders(to request: URLRequest) -> URLRequest {
        var newRequest = request

        if let token = self.userAccessToken.token {
            newRequest.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        }

        return newRequest
    }

    // MARK: - Privates

    private let userAccessToken: UserAccessTokenType

}
