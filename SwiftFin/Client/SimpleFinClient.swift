import Foundation

public class SimpleFinClient {
	private let session: URLSession
	private var accessURL: String?
	
	public init(session: URLSession = .shared) {
		self.session = session
	}
	
	// MARK: - Setup Token Handling
	
	/// Converts a setup token to an access URL by making a claim request
	/// - Parameter setupToken: Base64 encoded setup token
	/// - Returns: Access URL string
	public func claimSetupToken(_ setupToken: String) async throws -> String {
		guard let claimURL = setupToken.fromBase64() else {
			throw SimpleFinError.invalidSetupToken
		}
		
		guard let url = URL(string: claimURL) else {
			throw SimpleFinError.invalidSetupToken
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		
		do {
			let (data, response) = try await session.data(for: request)
			
			if let httpResponse = response as? HTTPURLResponse {
				guard httpResponse.statusCode == 200 else {
					throw SimpleFinError.httpError(httpResponse.statusCode)
				}
			}
			
			guard let accessURL = String(data: data, encoding: .utf8) else {
				throw SimpleFinError.decodingError(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid response data")))
			}
			
			self.accessURL = accessURL.trimmingCharacters(in: .whitespacesAndNewlines)
			return self.accessURL!
			
		} catch {
			throw SimpleFinError.networkError(error)
		}
	}
	
	// MARK: - Account Data Fetching
	
	/// Fetches accounts using the stored access URL
	/// - Parameters:
	///   - startDate: Unix timestamp for transaction start date (optional) - includes transactions on or after this date
	///   - endDate: Unix timestamp for transaction end date (optional) - includes transactions before (but not on) this date
	/// - Returns: SimplefinResponse containing accounts and transactions
	public func fetchAccounts(startDate: Int? = nil, endDate: Int? = nil) async throws -> SimplefinResponse {
		guard let accessURL = accessURL else {
			throw SimpleFinError.invalidAccessURL
		}
		
		return try await fetchAccounts(accessURL: accessURL, startDate: startDate, endDate: endDate)
	}
	
	/// Fetches accounts using a provided access URL
	/// - Parameters:
	///   - accessURL: The SimpleFin access URL
	///   - startDate: Unix timestamp for transaction start date (optional) - includes transactions on or after this date
	///   - endDate: Unix timestamp for transaction end date (optional) - includes transactions before (but not on) this date
	/// - Returns: SimplefinResponse containing accounts and transactions
	public func fetchAccounts(accessURL: String, startDate: Int? = nil, endDate: Int? = nil) async throws -> SimplefinResponse {
		guard let components = parseAccessURL(accessURL) else {
			throw SimpleFinError.invalidAccessURL
		}
		
		do {
			let (data, response) = try await makeAuthenticatedRequest(
				to: components.accountsURL,
				username: components.username,
				password: components.password,
				startDate: startDate,
				endDate: endDate
			)
			
			if let httpResponse = response as? HTTPURLResponse {
				guard httpResponse.statusCode == 200 else {
					throw SimpleFinError.httpError(httpResponse.statusCode)
				}
			}
			
			let decoder = JSONDecoder()
			return try decoder.decode(SimplefinResponse.self, from: data)
			
		} catch let error as SimpleFinError {
			throw error
		} catch {
			throw SimpleFinError.decodingError(error)
		}
	}
	
	// MARK: - Convenience Methods
	
	/// Initialize client with setup token and immediately claim it
	/// - Parameter setupToken: Base64 encoded setup token
	/// - Returns: Configured SimpleFinClient ready to fetch data
	public static func withSetupToken(_ setupToken: String) async throws -> SimpleFinClient {
		let client = SimpleFinClient()
		_ = try await client.claimSetupToken(setupToken)
		return client
	}
	
	/// Set access URL directly (if you already have it)
	/// - Parameter accessURL: The SimpleFin access URL
	public func setAccessURL(_ accessURL: String) {
		self.accessURL = accessURL
	}
	
	// MARK: - Private Methods
	
	private func parseAccessURL(_ accessUrl: String) -> ParsedURLComponents? {
		let schemeParts = accessUrl.components(separatedBy: "://")
		guard schemeParts.count == 2 else { return nil }
		let scheme = schemeParts[0] + "://"
		let rest = schemeParts[1]
		
		let authParts = rest.components(separatedBy: "@")
		guard authParts.count == 2 else { return nil }
		let auth = authParts[0]
		let hostAndPath = authParts[1]
		
		let baseURL = scheme + hostAndPath
		let accountsURL = baseURL + "/accounts"
		
		let credentialParts = auth.components(separatedBy: ":")
		guard credentialParts.count >= 2 else { return nil }
		let username = credentialParts[0]
		let password = credentialParts.dropFirst().joined(separator: ":")
		
		return ParsedURLComponents(
			scheme: scheme,
			username: username,
			password: password,
			baseURL: baseURL,
			accountsURL: accountsURL
		)
	}
	
	private func makeAuthenticatedRequest(
		to urlString: String,
		username: String,
		password: String,
		startDate: Int?,
		endDate: Int? = nil
	) async throws -> (Data, URLResponse) {
		guard let url = URL(string: urlString) else {
			throw SimpleFinError.invalidAccessURL
		}
		
		var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
		
		var queryItems: [URLQueryItem] = []
		
		if let startDate = startDate {
			queryItems.append(URLQueryItem(name: "start-date", value: String(startDate)))
		}
		
		if let endDate = endDate {
			queryItems.append(URLQueryItem(name: "end-date", value: String(endDate)))
		}
		
		if !queryItems.isEmpty {
			components?.queryItems = queryItems
		}
		
		guard let finalURL = components?.url else {
			throw SimpleFinError.invalidAccessURL
		}
		
		var request = URLRequest(url: finalURL)
		request.httpMethod = "GET"
		
		let credentials = "\(username):\(password)"
		guard let credentialsData = credentials.data(using: .utf8) else {
			throw SimpleFinError.authenticationError
		}
		
		let base64Credentials = credentialsData.base64EncodedString()
		request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
		
		do {
			return try await session.data(for: request)
		} catch {
			throw SimpleFinError.networkError(error)
		}
	}
}
