import Foundation



public struct Account: Codable, Identifiable {
	public let id: String
	public let name: String
	public let currency: String
	public let balance: String
	public let availableBalance: String?
	public let balanceDate: Int
	public let transactions: [Transaction]
	
	enum CodingKeys: String, CodingKey {
		case id, name, currency, balance
		case availableBalance = "available-balance"
		case balanceDate = "balance-date"
		case transactions
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		id = try container.decode(String.self, forKey: .id)
		name = try container.decode(String.self, forKey: .name)
		currency = try container.decode(String.self, forKey: .currency)
		transactions = try container.decode([Transaction].self, forKey: .transactions)
		balance = try container.decode(String.self, forKey: .balance)
		availableBalance = try? container.decode(String.self, forKey: .availableBalance)
		
		if let balanceDateString = try? container.decode(String.self, forKey: .balanceDate) {
			balanceDate = Int(balanceDateString) ?? 0
		} else {
			balanceDate = try container.decode(Int.self, forKey: .balanceDate)
		}
	}
}
