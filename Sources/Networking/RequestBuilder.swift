import Foundation
import UIKit

enum RequestBuilderError: Error {
    case invalidUrl
}

protocol RequestBuilderType {
    func buildRequest(from: ApiRequest) throws -> URLRequest
}

class RequestBuilder: RequestBuilderType {

    init(keychainAccess: KeychainAccessType) {
        self.keychainAccess = keychainAccess
    }

    func buildRequest(from apiRequest: ApiRequest) throws -> URLRequest {
        guard let url = constructUrl(fromString: apiRequest.resourcePath) else { throw RequestBuilderError.invalidUrl }

        var urlRequest: URLRequest

        switch apiRequest.method {
        case .delete, .get:
            urlRequest = createDefaultRequest(url: url,
                                              method: apiRequest.method,
                                              params: apiRequest.params)
        case .put, .post, .update:
            urlRequest = createMultipartRequest(url: url,
                                                method: apiRequest.method,
                                                params: apiRequest.params)
        }

        urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        urlRequest.httpMethod = apiRequest.method.rawValue.uppercased()

        if apiRequest.options.contains(.json) {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

            if !apiRequest.params.isEmpty {
                let data = try? JSONSerialization.data(withJSONObject: apiRequest.params, options: [])
                urlRequest.httpBody = data
            }
        }

        return urlRequest
    }

    // MARK: - Privates

    private let keychainAccess: KeychainAccessType

    private var baseUrl: URL? {
        guard let data = keychainAccess.load(key: KeychainAccess.phoneDataKey) else { return nil }
        guard let baseUrlString = try? data.to(type: PhoneUserInfo.self).baseUrl else { return nil }
        return URL(string: baseUrlString)
    }

    private func constructUrl(fromString urlString: String) -> URL? {
        guard let escapedString = self.escapedString(urlString) else { return nil }
        guard let baseUrl = baseUrl else { return nil }

        let urlStringComponents = [baseUrl.absoluteString, escapedString]
        return URL(string: urlStringComponents.joined(separator: "/"))
    }

    private func escapedString(_ urlString: String) -> String? {
        let allowedCharacters = CharacterSet(charactersIn: "!*'();:@+$,%# ").inverted
        return urlString.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }

    private func createDefaultRequest(url: URL, method _: ApiRequestMethod, params: [String: Any]) -> URLRequest {
        var urlComponents: URLComponents! = URLComponents(url: url, resolvingAgainstBaseURL: true)
        urlComponents.queryItems = []

        var urlRequest = URLRequest(url: url)

        if !params.isEmpty {
            for key in params.keys {
                let value = params[key]

                if let value = value as? String {
                    urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
                } else if let values = value as? [Any] {
                    for v in values {
                        urlComponents.queryItems?.append(URLQueryItem(name: key, value: "\(v)"))
                    }
                } else if let value = value {
                    urlComponents.queryItems?.append(URLQueryItem(name: key, value: "\(value)"))
                }
            }

            if let url = urlComponents.url {
                urlRequest.url = url
            }
        }

        return urlRequest
    }

    private func createMultipartRequest(url: URL, method _: ApiRequestMethod, params: [String: Any]) -> URLRequest {
        var request = URLRequest(url: url)

        let boundary: String = UUID().uuidString
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        var body = Data()

        for key in params.keys {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)

            let value = params[key]

            if let data = value as? Data {
                body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"file.bin\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
                body.append(data)
                body.append("\r\n".data(using: .utf8)!)
            } else if var image = value as? UIImage {
                body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8) ?? Data())

                if image.size.width > 1000.0 || image.size.height > 1000.0 {
                    if image.size.width > image.size.height {
                        image = image.scaledImage(to: CGSize(width: 1000, height: 1000 * image.size.height / image.size.width))
                    } else {
                        image = image.scaledImage(to: CGSize(width: 1000 * image.size.width / image.size.height, height: 1000))
                    }
                }

                body.append(image.jpegData(compressionQuality: 0.9)!)
                body.append("\r\n".data(using: .utf8)!)
            } else if let values = value as? [Any] {
                for (index, v) in values.enumerated() {
                    body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)

                    let valueString = "\(v)\r\n"

                    body.append(valueString.data(using: .utf8)!)

                    if index != values.count - 1 {
                        body.append("--\(boundary)\r\n".data(using: .utf8)!)
                    }
                }
            } else {
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)

                let valueString = "\(value!)\r\n"

                body.append(valueString.data(using: .utf8)!)
            }
        }

        body.append("--\(boundary)--".data(using: .utf8)!)

        request.httpBody = body
        return request
    }

}
