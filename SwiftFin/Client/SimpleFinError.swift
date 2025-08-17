import Foundation

/// Errors that can occur when using the SimpleFin API
public enum SimpleFinError: Error {
	/// The provided setup token is invalid or malformed
	case invalidSetupToken
	
	/// The access URL is invalid or malformed
	case invalidAccessURL
	
	/// A network error occurred during the request
	/// - Parameter Error: The underlying network error
	case networkError(Error)
	
	/// Authentication failed with the provided credentials
	case authenticationError
	
	/// Failed to decode the response data
	/// - Parameter Error: The underlying decoding error
	case decodingError(Error)
	
	/// HTTP request returned an error status code
	/// - Parameter Int: The HTTP status code
	case httpError(Int)
	
	/// The access has been revoked by the user or bank
	/// This typically happens when the user revokes permission through their bank's interface
	/// Recovery requires obtaining a new setup token from the bank
	case accessRevoked
}

extension SimpleFinError: Equatable {
	public static func == (lhs: SimpleFinError, rhs: SimpleFinError) -> Bool {
		switch (lhs, rhs) {
		case (.invalidSetupToken, .invalidSetupToken),
			 (.invalidAccessURL, .invalidAccessURL),
			 (.authenticationError, .authenticationError),
			 (.accessRevoked, .accessRevoked):
			return true
		case (.httpError(let lhsCode), .httpError(let rhsCode)):
			return lhsCode == rhsCode
		case (.networkError, .networkError),
			 (.decodingError, .decodingError):
			return true
		default:
			return false
		}
	}
}
