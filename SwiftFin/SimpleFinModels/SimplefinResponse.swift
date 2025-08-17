import Foundation

/// Response structure returned by SimpleFin API calls
/// Contains an array of accounts with their associated transactions
public struct SimplefinResponse: Codable {
	/// Array of bank accounts and their transaction data
	public let accounts: [Account]
	
	enum CodingKeys: String, CodingKey {
		case accounts
	}
	
	/// Initialize a SimpleFin response with accounts
	/// - Parameter accounts: Array of Account objects
	public init(accounts: [Account]) {
		self.accounts = accounts
	}
}
