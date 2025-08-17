import Foundation

public enum SimpleFinError: Error {
	case invalidSetupToken
	case invalidAccessURL
	case networkError(Error)
	case authenticationError
	case decodingError(Error)
	case httpError(Int)
}
