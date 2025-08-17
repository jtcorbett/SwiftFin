import Foundation

public struct AnyCodable: Codable {
	public let value: Any
	
	public init<T>(_ value: T?) {
		self.value = value ?? ()
	}
}

extension AnyCodable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		if container.decodeNil() {
			self.init(())
		} else if let bool = try? container.decode(Bool.self) {
			self.init(bool)
		} else if let int = try? container.decode(Int.self) {
			self.init(int)
		} else if let double = try? container.decode(Double.self) {
			self.init(double)
		} else if let string = try? container.decode(String.self) {
			self.init(string)
		} else if let array = try? container.decode([AnyCodable].self) {
			self.init(array.map { $0.value })
		} else if let dictionary = try? container.decode([String: AnyCodable].self) {
			self.init(dictionary.mapValues { $0.value })
		} else {
			throw DecodingError.dataCorrupted(
				DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type")
			)
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		
		switch value {
		case is Void:
			try container.encodeNil()
		case let bool as Bool:
			try container.encode(bool)
		case let int as Int:
			try container.encode(int)
		case let double as Double:
			try container.encode(double)
		case let string as String:
			try container.encode(string)
		case let array as [Any]:
			try container.encode(array.map { AnyCodable($0) })
		case let dictionary as [String: Any]:
			try container.encode(dictionary.mapValues { AnyCodable($0) })
		default:
			throw EncodingError.invalidValue(
				value,
				EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type")
			)
		}
	}
}

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
	
	public var transactedDate: Date? {
		guard let transactedAt = transactedAt else { return nil }
		return Date(timeIntervalSince1970: TimeInterval(transactedAt))
	}
	
	public var isDebit: Bool {
		return amountInDollars < 0
	}
	
	public var isCredit: Bool {
		return amountInDollars > 0
	}
	
	public var isPending: Bool {
		return pending ?? false
	}
	
	public func extraValue<T>(for key: String, as type: T.Type) -> T? {
		return extra?[key]?.value as? T
	}
	
	public func extraString(for key: String) -> String? {
		return extraValue(for: key, as: String.self)
	}
	
	public func extraInt(for key: String) -> Int? {
		return extraValue(for: key, as: Int.self)
	}
	
	public func extraDouble(for key: String) -> Double? {
		return extraValue(for: key, as: Double.self)
	}
	
	public func extraBool(for key: String) -> Bool? {
		return extraValue(for: key, as: Bool.self)
	}
}
