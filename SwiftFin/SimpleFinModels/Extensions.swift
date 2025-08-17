import Foundation

/// A type-erased codable wrapper that can encode/decode any JSON value
/// Useful for handling dynamic or unknown JSON structures
public struct AnyCodable: Codable {
	/// The wrapped value of any type
	public let value: Any
	
	/// Initialize with any optional value
	/// - Parameter value: The value to wrap (nil values become empty tuple)
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

// MARK: - String Extensions

extension String {
	/// Decode a base64 encoded string
	/// - Returns: Decoded string or nil if invalid base64
	public func fromBase64() -> String? {
		guard let data = Data(base64Encoded: self) else {
			return nil
		}
		return String(data: data, encoding: .utf8)
	}
	
	/// Encode string to base64
	/// - Returns: Base64 encoded string
	public func toBase64() -> String {
		return Data(self.utf8).base64EncodedString()
	}
}

// MARK: - Account Extensions

extension Account {
	/// Convert balance string to Double for calculations
	/// - Returns: Balance as Double, 0.0 if conversion fails
	public var balanceInDollars: Double {
		return Double(balance) ?? 0.0
	}
	
	/// Convert available balance string to Double for calculations
	/// - Returns: Available balance as Double, nil if not available or conversion fails
	public var availableBalanceInDollars: Double? {
		guard let available = availableBalance else { return nil }
		return Double(available)
	}
	
	/// Convert Unix timestamp to Date object
	/// - Returns: Date when balance was last updated
	public var balanceDateFormatted: Date {
		return Date(timeIntervalSince1970: TimeInterval(balanceDate))
	}
}

// MARK: - Transaction Extensions

extension Transaction {
	/// Convert amount string to Double for calculations
	/// - Returns: Amount as Double, 0.0 if conversion fails
	public var amountInDollars: Double {
		return Double(amount) ?? 0.0
	}
	
	/// Convert posted timestamp to Date object
	/// - Returns: Date when transaction was posted
	public var postedDate: Date {
		return Date(timeIntervalSince1970: TimeInterval(posted))
	}
	
	/// Convert transacted timestamp to Date object
	/// - Returns: Date when transaction occurred, nil if not available
	public var transactedDate: Date? {
		guard let transactedAt = transactedAt else { return nil }
		return Date(timeIntervalSince1970: TimeInterval(transactedAt))
	}
	
	/// Check if transaction is a debit (money going out)
	/// - Returns: true if amount is negative
	public var isDebit: Bool {
		return amountInDollars < 0
	}
	
	/// Check if transaction is a credit (money coming in)
	/// - Returns: true if amount is positive
	public var isCredit: Bool {
		return amountInDollars > 0
	}
	
	/// Check if transaction is still pending
	/// - Returns: true if pending, false if cleared or nil
	public var isPending: Bool {
		return pending ?? false
	}
	
	/// Extract a typed value from the extra data dictionary
	/// - Parameters:
	///   - key: The key to look up in the extra data
	///   - type: The type to cast the value to
	/// - Returns: The typed value or nil if key doesn't exist or type casting fails
	public func extraValue<T>(for key: String, as type: T.Type) -> T? {
		return extra?[key]?.value as? T
	}
	
	/// Get string value from extra data
	/// - Parameter key: The key to look up
	/// - Returns: String value or nil
	public func extraString(for key: String) -> String? {
		return extraValue(for: key, as: String.self)
	}
	
	/// Get integer value from extra data
	/// - Parameter key: The key to look up
	/// - Returns: Int value or nil
	public func extraInt(for key: String) -> Int? {
		return extraValue(for: key, as: Int.self)
	}
	
	/// Get double value from extra data
	/// - Parameter key: The key to look up
	/// - Returns: Double value or nil
	public func extraDouble(for key: String) -> Double? {
		return extraValue(for: key, as: Double.self)
	}
	
	/// Get boolean value from extra data
	/// - Parameter key: The key to look up
	/// - Returns: Bool value or nil
	public func extraBool(for key: String) -> Bool? {
		return extraValue(for: key, as: Bool.self)
	}
}
