import Foundation

extension String {
	public func fromBase64() -> String? {
		guard let data = Data(base64Encoded: self) else {
			return nil
		}
		return String(data: data, encoding: .utf8)
	}
	
	public func toBase64() -> String {
		return Data(self.utf8).base64EncodedString()
	}
}

extension Account {
	public var balanceInDollars: Double {
		return Double(balance) ?? 0.0
	}
	
	public var availableBalanceInDollars: Double? {
		guard let available = availableBalance else { return nil }
		return Double(available)
	}
	
	public var balanceDateFormatted: Date {
		return Date(timeIntervalSince1970: TimeInterval(balanceDate))
	}
}

extension Transaction {
	public var amountInDollars: Double {
		return Double(amount) ?? 0.0
	}
	
	public var postedDate: Date {
		return Date(timeIntervalSince1970: TimeInterval(posted))
	}
	
	public var isDebit: Bool {
		return amountInDollars < 0
	}
	
	public var isCredit: Bool {
		return amountInDollars > 0
	}
}
