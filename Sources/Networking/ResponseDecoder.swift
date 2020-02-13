import Foundation

protocol ResponseDecoderType {
    func decode<T>(_ data: Data) throws -> T where T: Decodable
}

class ResponseDecoder: ResponseDecoderType {

    func decode<T>(_ data: Data) throws -> T where T: Decodable {
        return try JSONDecoder().decode(T.self, from: data)
    }

}
