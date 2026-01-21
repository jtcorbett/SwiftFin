import Foundation

/// Represents a financial organization/institution
/// Conforms to Codable for JSON parsing
public struct Organization: Codable {
	/// Domain name of the financial institution
	public let domain: String?

	/// Root URL of organization's SimpleFIN Server
	public let sfinUrl: String

	/// Human-friendly name of the financial institution
	public let name: String?

	/// Optional URL of the financial institution
	public let url: String?

	/// Optional ID for the financial institution
	public let id: String?

	enum CodingKeys: String, CodingKey {
		case domain
		case sfinUrl = "sfin-url"
		case name
		case url
		case id
	}
}
