/// Represents a financial transaction with all associated metadata
/// Conforms to Codable for JSON parsing and Identifiable for SwiftUI compatibility
public struct Transaction: Codable, Identifiable {
	/// Unique identifier for the transaction
	public let id: String
	
	/// Unix timestamp when the transaction was posted to the account
	public let posted: Int
	
	/// Transaction amount as a string (negative for debits, positive for credits)
	public let amount: String
	
	/// Description of the transaction
	public let description: String
	
	/// Additional memo information (optional)
	public let memo: String?
	
	/// Payee name (optional)
	public let payee: String?
	
	/// Unix timestamp when the transaction actually occurred (may differ from posted date)
	public let transactedAt: Int?
	
	/// Whether the transaction is still pending
	public let pending: Bool?
	
	/// Additional arbitrary data associated with the transaction
	public let extra: [String: AnyCodable]?
	
	enum CodingKeys: String, CodingKey {
		case id, posted, amount, description, memo, payee
		case transactedAt = "transacted_at"
		case pending, extra
	}
	
	/// Custom decoder to handle flexible timestamp formats (string or int)
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		id = try container.decode(String.self, forKey: .id)
		description = try container.decode(String.self, forKey: .description)
		memo = try? container.decode(String.self, forKey: .memo)
		payee = try? container.decode(String.self, forKey: .payee)
		
		// Handle posted date as either string or int
		if let postedString = try? container.decode(String.self, forKey: .posted) {
			posted = Int(postedString) ?? 0
		} else {
			posted = try container.decode(Int.self, forKey: .posted)
		}
		
		amount = try container.decode(String.self, forKey: .amount)
		
		// Handle transacted_at as either string or int
		if let transactedString = try? container.decode(String.self, forKey: .transactedAt) {
			transactedAt = Int(transactedString)
		} else {
			transactedAt = try? container.decode(Int.self, forKey: .transactedAt)
		}
		
		pending = try? container.decode(Bool.self, forKey: .pending)
		extra = try? container.decode([String: AnyCodable].self, forKey: .extra)
	}
}
