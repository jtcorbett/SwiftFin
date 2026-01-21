import Foundation

/// SimpleFin API client for fetching bank account and transaction data
/// 
/// This client handles authentication, network requests, and data parsing for the SimpleFin API.
/// It supports both setup token claiming and direct access URL usage for data fetching.
///
/// Key features:
/// - Setup token claiming to obtain access URLs
/// - Account and transaction data fetching with date filtering
/// - Flexible date handling (Unix timestamps or Date objects)
/// - Automatic JSON parsing to Swift structs
/// - Comprehensive error handling
///
/// - Important: **SAVE ACCESS URLS!** Setup tokens can only be claimed once. Always save the access URL
///   after claiming a setup token for future use. Store it securely (e.g., in Keychain).
///
/// Example usage:
/// ```swift
/// let client = SimpleFinClient()
/// 
/// // Claim setup token to get access URL
/// let accessURL = try await client.claimSetupToken("setup_token")
/// // IMPORTANT: Save this accessURL securely for future use!
/// 
/// // Or get the access URL from the client
/// if let savedAccessURL = client.getAccessURL() {
///     // Save this URL securely
/// }
/// 
/// // Fetch all accounts and transactions
/// let response = try await client.fetchAccounts()
/// 
/// // Fetch with date filtering
/// let startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
/// let recent = try await client.fetchAccounts(startDate: startDate)
/// ```
public class SimpleFinClient {
	private let session: URLSession
	private var accessURL: String?
	
	/// Initialize a new SimpleFin client
	/// - Parameter session: URLSession to use for network requests (defaults to .shared)
	public init(session: URLSession = .shared) {
		self.session = session
	}
	
	// MARK: - Setup Token Handling
	
	/// Converts a setup token to an access URL by making a claim request
	/// 
	/// - Important: **SAVE THE RETURNED ACCESS URL!** Setup tokens can only be claimed once.
	///   Store the returned access URL securely (e.g., in Keychain) for future use. If you lose
	///   the access URL, you will need to obtain a new setup token from your bank.
	/// 
	/// - Parameter setupToken: Base64 encoded setup token
	/// - Returns: Access URL string that should be saved for future use
	/// - Throws: SimpleFinError if the setup token is invalid, already claimed, or network errors occur
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

	/// Fetches all accounts using stored access URL with no filters
	/// - Returns: SimplefinResponse containing accounts and transactions
	public func fetchAccounts() async throws -> SimplefinResponse {
		return try await fetchAccounts(
			accessURL: nil,
			startDate: nil as Int?,
			endDate: nil as Int?,
			pending: nil,
			balancesOnly: nil,
			accountIds: nil
		)
	}

	/// Fetches accounts with full control over all parameters
	/// - Parameters:
	///   - accessURL: The SimpleFin access URL (uses stored URL if nil)
	///   - startDate: Unix timestamp for transaction start date (optional) - includes transactions on or after this date
	///   - endDate: Unix timestamp for transaction end date (optional) - includes transactions before (but not on) this date
	///   - pending: If true, include pending transactions (appends ?pending=1)
	///   - balancesOnly: If true, return only balance data without transactions (appends ?balances-only=1)
	///   - accountIds: Optional array of account IDs to filter results
	/// - Returns: SimplefinResponse containing accounts and transactions
	public func fetchAccounts(
		accessURL: String? = nil,
		startDate: Int? = nil,
		endDate: Int? = nil,
		pending: Bool? = nil,
		balancesOnly: Bool? = nil,
		accountIds: [String]? = nil
	) async throws -> SimplefinResponse {
		let url = accessURL ?? self.accessURL
		guard let url = url else {
			throw SimpleFinError.invalidAccessURL
		}

		guard let components = parseAccessURL(url) else {
			throw SimpleFinError.invalidAccessURL
		}

		do {
			let (data, response) = try await makeAuthenticatedRequest(
				to: components.accountsURL,
				username: components.username,
				password: components.password,
				startDate: startDate,
				endDate: endDate,
				pending: pending,
				balancesOnly: balancesOnly,
				accountIds: accountIds
			)

			if let httpResponse = response as? HTTPURLResponse {
				guard httpResponse.statusCode == 200 else {
					// Check for specific revocation scenarios
					if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
						throw SimpleFinError.accessRevoked
					}
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

	/// Fetches accounts with Date objects (convenience method)
	/// - Parameters:
	///   - accessURL: The SimpleFin access URL (uses stored URL if nil)
	///   - startDate: Start date for transactions (automatically converted to Unix timestamp)
	///   - endDate: End date for transactions (automatically converted to Unix timestamp)
	///   - pending: If true, include pending transactions (appends ?pending=1)
	///   - balancesOnly: If true, return only balance data without transactions (appends ?balances-only=1)
	///   - accountIds: Optional array of account IDs to filter results
	/// - Returns: SimplefinResponse containing accounts and transactions
	public func fetchAccounts(
		accessURL: String? = nil,
		startDate: Date? = nil,
		endDate: Date? = nil,
		pending: Bool? = nil,
		balancesOnly: Bool? = nil,
		accountIds: [String]? = nil
	) async throws -> SimplefinResponse {
		let startEpoch = startDate.map { Int($0.timeIntervalSince1970) }
		let endEpoch = endDate.map { Int($0.timeIntervalSince1970) }
		return try await fetchAccounts(
			accessURL: accessURL,
			startDate: startEpoch,
			endDate: endEpoch,
			pending: pending,
			balancesOnly: balancesOnly,
			accountIds: accountIds
		)
	}
	
	// MARK: - Convenience Methods
	
	/// Initialize client with setup token and immediately claim it
	/// 
	/// - Important: **SAVE THE ACCESS URL!** The setup token can only be claimed once.
	///   After initialization, retrieve the access URL from the client and save it securely
	///   for future use. If you lose the access URL, you will need a new setup token.
	/// 
	/// - Parameter setupToken: Base64 encoded setup token
	/// - Returns: Configured SimpleFinClient ready to fetch data
	/// - Throws: SimpleFinError if the setup token is invalid, already claimed, or network errors occur
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
	
	/// Get the current access URL stored in this client
	/// 
	/// Use this method to retrieve the access URL after claiming a setup token
	/// so you can save it securely for future use.
	/// 
	/// - Returns: The access URL if available, nil if not set
	public func getAccessURL() -> String? {
		return accessURL
	}
	
	/// Clear the stored access URL
	/// 
	/// Use this method when you detect that the access URL has been revoked
	/// and needs to be removed from storage to force re-authentication.
	public func clearAccessURL() {
		self.accessURL = nil
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
		endDate: Int? = nil,
		pending: Bool? = nil,
		balancesOnly: Bool? = nil,
		accountIds: [String]? = nil
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

		// Add pending parameter if explicitly set to true
		if let pending = pending {
			queryItems.append(URLQueryItem(name: "pending", value: pending ? "1" : "0"))
		}

		// Add balances-only parameter if explicitly set to true
		if let balancesOnly = balancesOnly {
			queryItems.append(URLQueryItem(name: "balances-only", value: balancesOnly ? "1" : "0"))
		}

		// Add account parameter(s) - can be specified multiple times
		if let accountIds = accountIds {
			for accountId in accountIds {
				queryItems.append(URLQueryItem(name: "account", value: accountId))
			}
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
