import Foundation

protocol ApiClientType {
    func fetchRequest<T: Decodable>(_ request: ApiRequest, completion: @escaping (T) -> Void)
}

class ApiClient: ApiClientType {

    init(requestBuilder: RequestBuilderType,
         requestInterceptor: RequestInterceptorType,
         session: URLSession = URLSession.shared,
         responseDecoder: ResponseDecoderType = ResponseDecoder()) {
        self.requestBuilder = requestBuilder
        self.requestInterceptor = requestInterceptor
        self.session = session
        self.responseDecoder = responseDecoder
    }

    // MARK: - ApiClientType

    func fetchRequest<T: Decodable>(_ request: ApiRequest, completion: @escaping (T) -> Void) {
        guard let urlRequest = try? createUrlRequest(from: request) else { return }

        let task = session.dataTask(with: urlRequest) { data, response, error in
            guard let response = response as? HTTPURLResponse else { return }
            switch response.statusCode {
            case 200:
                do {
                    completion(try self.responseDecoder.decode(data!) as T)
                } catch {
                    print(ApiError.parseError(error: error, modelName: "\(T.self)"))
                }
            case 401:
                print(ApiError.invalidAuthorization)
            case 400..<500:
                print(ApiError.responseError)
            default:
                print(ApiError.requestFailure(statusCode: response.statusCode))
            }
        }
        task.resume()
    }

    // MARK: - Privates

    private let requestBuilder: RequestBuilderType
    private let requestInterceptor: RequestInterceptorType
    private let session: URLSession
    private let responseDecoder: ResponseDecoderType

    private func createUrlRequest(from apiRequest: ApiRequest) throws -> URLRequest {
        let urlRequest = try requestBuilder.buildRequest(from: apiRequest)
        return requestInterceptor.addHeaders(to: urlRequest)
    }

}
