public struct Transaction: Codable, Identifiable {
	public let id: String
	public let posted: Int
	public let amount: String
	public let description: String
	public let memo: String?
	public let payee: String?
	public let transactedAt: Int?
	public let pending: Bool?
	public let extra: [String: AnyCodable]?
	
	enum CodingKeys: String, CodingKey {
		case id, posted, amount, description, memo, payee
		case transactedAt = "transacted_at"
		case pending, extra
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		id = try container.decode(String.self, forKey: .id)
		description = try container.decode(String.self, forKey: .description)
		memo = try? container.decode(String.self, forKey: .memo)
		payee = try? container.decode(String.self, forKey: .payee)
		
		if let postedString = try? container.decode(String.self, forKey: .posted) {
			posted = Int(postedString) ?? 0
		} else {
			posted = try container.decode(Int.self, forKey: .posted)
		}
		
		amount = try container.decode(String.self, forKey: .amount)
		
		if let transactedString = try? container.decode(String.self, forKey: .transactedAt) {
			transactedAt = Int(transactedString)
		} else {
			transactedAt = try? container.decode(Int.self, forKey: .transactedAt)
		}
		
		pending = try? container.decode(Bool.self, forKey: .pending)
		extra = try? container.decode([String: AnyCodable].self, forKey: .extra)
	}
}
