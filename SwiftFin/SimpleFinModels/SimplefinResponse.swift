import Foundation

public struct SimplefinResponse: Codable {
	public let accounts: [Account]
	
	enum CodingKeys: String, CodingKey {
		case accounts
	}
	
	public init(accounts: [Account]) {
		self.accounts = accounts
	}
}
