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
}
