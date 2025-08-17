import Foundation

/// Internal structure for storing parsed components from a SimpleFin access URL
public struct ParsedURLComponents {
	/// The URL scheme (e.g., "https://")
	let scheme: String
	
	/// Username for authentication
	let username: String
	
	/// Password for authentication
	let password: String
	
	/// Base URL without authentication credentials
	let baseURL: String
	
	/// Full URL for the accounts endpoint
	let accountsURL: String
}
