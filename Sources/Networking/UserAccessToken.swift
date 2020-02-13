protocol UserAccessTokenType {
    var token: String? { get }
}

class UserAccessToken: UserAccessTokenType {

    init(keychainAccess: KeychainAccessType = KeychainAccess()) {
        self.keychainAccess = keychainAccess
    }

    // MARK: - UserAccessTokenType

    var token: String? {
        guard let data = keychainAccess.load(key: KeychainAccess.phoneDataKey) else { return nil }
        return try? data.to(type: PhoneUserInfo.self).token
    }

    // MARK: - Privates

    private let keychainAccess: KeychainAccessType

}
