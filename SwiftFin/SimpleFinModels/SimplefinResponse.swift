import Foundation

/// Response structure returned by SimpleFin API calls (Account Set)
/// Contains an array of accounts with their associated transactions and any error messages
public struct SimplefinResponse: Codable {
	/// Array of error messages suitable for displaying to users
	public let errors: [String]

	/// Array of bank accounts and their transaction data
	public let accounts: [Account]

	enum CodingKeys: String, CodingKey {
		case errors
		case accounts
	}

	/// Initialize a SimpleFin response
	/// - Parameters:
	///   - errors: Array of error messages
	///   - accounts: Array of Account objects
	public init(errors: [String] = [], accounts: [Account]) {
		self.errors = errors
		self.accounts = accounts
	}
}
