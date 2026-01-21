import Foundation

/// Represents a bank account with its balance information and transaction history
/// Conforms to Codable for JSON parsing and Identifiable for SwiftUI compatibility
public struct Account: Codable, Identifiable {
	/// Organization from which this account originates
	public let org: Organization

	/// Unique identifier for the account
	public let id: String
	
	/// Display name of the account (e.g., "Checking Account")
	public let name: String
	
	/// Currency code for the account (e.g., "USD")
	public let currency: String
	
	/// Current balance as a string representation
	public let balance: String
	
	/// Available balance (may differ from current balance for credit accounts)
	public let availableBalance: String?
	
	/// Unix timestamp of when the balance was last updated
	public let balanceDate: Int
	
	/// Array of transactions associated with this account
	public let transactions: [Transaction]
	
	enum CodingKeys: String, CodingKey {
		case org
		case id, name, currency, balance
		case availableBalance = "available-balance"
		case balanceDate = "balance-date"
		case transactions
	}
	
	/// Custom decoder to handle flexible balance date format (string or int)
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		org = try container.decode(Organization.self, forKey: .org)
		id = try container.decode(String.self, forKey: .id)
		name = try container.decode(String.self, forKey: .name)
		currency = try container.decode(String.self, forKey: .currency)
		transactions = try container.decode([Transaction].self, forKey: .transactions)
		balance = try container.decode(String.self, forKey: .balance)
		availableBalance = try? container.decode(String.self, forKey: .availableBalance)
		
		// Handle balance date as either string or int
		if let balanceDateString = try? container.decode(String.self, forKey: .balanceDate) {
			balanceDate = Int(balanceDateString) ?? 0
		} else {
			balanceDate = try container.decode(Int.self, forKey: .balanceDate)
		}
	}
}
