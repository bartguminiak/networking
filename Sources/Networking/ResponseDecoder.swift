import Foundation

public protocol ResponseDecoderType {
    func decode<T>(_ data: Data) throws -> T where T: Decodable
}

public class ResponseDecoder: ResponseDecoderType {

    public init() {}

    public func decode<T>(_ data: Data) throws -> T where T: Decodable {
        return try JSONDecoder().decode(T.self, from: data)
    }

}
