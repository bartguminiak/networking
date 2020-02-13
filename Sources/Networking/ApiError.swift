public enum ApiError: Swift.Error {
    case invalidAuthorization
    case requestFailure(statusCode: Int)
    case parseError(error: Error, modelName: String)
    case responseError
}
