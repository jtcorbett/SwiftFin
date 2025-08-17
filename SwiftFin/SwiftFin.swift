//
//  SwiftFin.swift
//  SwiftFin
//
//  Created by Effy on 2025-08-17.
//

import Foundation

/// Main entry point for the SwiftFin library
/// 
/// SwiftFin provides a Swift interface for accessing SimpleFin bank data.
/// Use this class to create clients and access banking information.
///
/// Example usage:
/// ```swift
/// // Using a setup token
/// let client = try await SimpleFin.client(withSetupToken: "your_setup_token")
/// let accounts = try await client.fetchAccounts()
///
/// // Using an access URL directly
/// let client = SimpleFin.client(withAccessURL: "your_access_url")
/// let accounts = try await client.fetchAccounts()
/// ```
public struct SimpleFin {
	/// Current version of the SimpleFin library
	public static let version = "1.0.0"
	
	/// Create a SimpleFin client using a setup token
	/// 
	/// This method claims the setup token and returns a configured client ready to fetch data.
	/// The setup token is typically provided by your bank and needs to be claimed only once.
	///
	/// - Important: **SAVE THE ACCESS URL!** Setup tokens can only be claimed once. After claiming,
	///   you should save the access URL (available via the client) for future use. If you lose the
	///   access URL, you will need to obtain a new setup token from your bank.
	///
	/// - Parameter setupToken: Base64 encoded setup token from your bank
	/// - Returns: Configured SimpleFinClient ready to fetch account data
	/// - Throws: SimpleFinError if the setup token is invalid or network errors occur
	public static func client(withSetupToken setupToken: String) async throws -> SimpleFinClient {
		return try await SimpleFinClient.withSetupToken(setupToken)
	}
	
	/// Create a SimpleFin client using an access URL directly
	/// 
	/// Use this method if you already have a valid access URL (from a previous setup token claim).
	/// This method does not perform any network requests.
	///
	/// - Parameter accessURL: Valid SimpleFin access URL
	/// - Returns: SimpleFinClient configured with the access URL
	public static func client(withAccessURL accessURL: String) -> SimpleFinClient {
		let client = SimpleFinClient()
		client.setAccessURL(accessURL)
		return client
	}
	
	/// Fetch financial data with automatic access URL management
	/// 
	/// This method handles the complete flow of fetching financial data:
	/// - Checks for existing access URL in UserDefaults
	/// - Claims setup token if needed and saves access URL
	/// - Fetches accounts and transactions data
	/// - Handles access revocation by clearing stored URLs
	///
	/// - Parameters:
	///   - setupToken: Base64 encoded setup token (required if no access URL is stored)
	///   - userDefaultsKey: Key to use for storing/retrieving access URL from UserDefaults
	///   - startDate: Optional start date for transaction filtering
	///   - endDate: Optional end date for transaction filtering
	/// - Returns: SimplefinResponse containing accounts and transactions
	/// - Throws: SimpleFinError for various error conditions
	@MainActor
	public static func fetchData(
		setupToken: String,
		userDefaultsKey: String,
		startDate: Date? = nil,
		endDate: Date? = nil
	) async throws -> SimplefinResponse {
		// Check for existing access URL
		if let storedAccessURL = UserDefaults.standard.string(forKey: userDefaultsKey) {
			do {
				let client = SimpleFin.client(withAccessURL: storedAccessURL)
				return try await client.fetchAccounts(startDate: startDate, endDate: endDate)
			} catch let error as SimpleFinError {
				if error == .accessRevoked {
					// Clear stored access URL and continue to claim new one
					UserDefaults.standard.removeObject(forKey: userDefaultsKey)
				} else {
					throw error
				}
			}
		}
		
		// No stored access URL or it was revoked - claim setup token
		guard !setupToken.isEmpty else {
			throw SimpleFinError.invalidSetupToken
		}
		
		let client = SimpleFinClient()
		let accessURL = try await client.claimSetupToken(setupToken)
		
		// Save the access URL for future use
		UserDefaults.standard.set(accessURL, forKey: userDefaultsKey)
		
		// Fetch data with the new access URL
		return try await client.fetchAccounts(startDate: startDate, endDate: endDate)
	}
	
	/// Fetch financial data using an existing access URL
	/// 
	/// This method is useful when you already have a valid access URL and want to fetch data
	/// without going through the setup token flow.
	///
	/// - Parameters:
	///   - accessURL: Valid SimpleFin access URL
	///   - startDate: Optional start date for transaction filtering
	///   - endDate: Optional end date for transaction filtering
	/// - Returns: SimplefinResponse containing accounts and transactions
	/// - Throws: SimpleFinError for various error conditions
	public static func fetchData(
		accessURL: String,
		startDate: Date? = nil,
		endDate: Date? = nil
	) async throws -> SimplefinResponse {
		let client = SimpleFin.client(withAccessURL: accessURL)
		return try await client.fetchAccounts(startDate: startDate, endDate: endDate)
	}
	
	/// Fetch a specific account and its transactions by name or ID
	/// 
	/// This method fetches all accounts and then filters to return only the account
	/// that matches the specified name or ID. The search supports partial matching and is case-insensitive.
	///
	/// - Parameters:
	///   - setupToken: Base64 encoded setup token (required if no access URL is stored)
	///   - userDefaultsKey: Key to use for storing/retrieving access URL from UserDefaults
	///   - accountIdentifier: Account name or ID to search for (supports partial matching)
	///   - startDate: Optional start date for transaction filtering
	///   - endDate: Optional end date for transaction filtering
	/// - Returns: Single Account with its transactions
	/// - Throws: SimpleFinError including .accountNotFound if no matching account is found
	@MainActor
	public static func fetchAccount(
		setupToken: String,
		userDefaultsKey: String,
		accountIdentifier: String,
		startDate: Date? = nil,
		endDate: Date? = nil
	) async throws -> Account {
		// First fetch all accounts
		let response = try await fetchData(
			setupToken: setupToken,
			userDefaultsKey: userDefaultsKey,
			startDate: startDate,
			endDate: endDate
		)
		
		// Search for account by ID (partial match) or name (case-insensitive partial match)
		let matchingAccount = response.accounts.first { account in
			account.id.lowercased().contains(accountIdentifier.lowercased()) ||
			account.name.lowercased().contains(accountIdentifier.lowercased())
		}
		
		guard let account = matchingAccount else {
			throw SimpleFinError.accountNotFound
		}
		
		return account
	}
	
	/// Fetch a specific account and its transactions using an existing access URL
	/// 
	/// This method is useful when you already have a valid access URL and want to fetch
	/// a specific account without going through the setup token flow. The search supports partial matching and is case-insensitive.
	///
	/// - Parameters:
	///   - accessURL: Valid SimpleFin access URL
	///   - accountIdentifier: Account name or ID to search for (supports partial matching)
	///   - startDate: Optional start date for transaction filtering
	///   - endDate: Optional end date for transaction filtering
	/// - Returns: Single Account with its transactions
	/// - Throws: SimpleFinError including .accountNotFound if no matching account is found
	public static func fetchAccount(
		accessURL: String,
		accountIdentifier: String,
		startDate: Date? = nil,
		endDate: Date? = nil
	) async throws -> Account {
		// First fetch all accounts
		let response = try await fetchData(
			accessURL: accessURL,
			startDate: startDate,
			endDate: endDate
		)
		
		// Search for account by ID (partial match) or name (case-insensitive partial match)
		let matchingAccount = response.accounts.first { account in
			account.id.lowercased().contains(accountIdentifier.lowercased()) ||
			account.name.lowercased().contains(accountIdentifier.lowercased())
		}
		
		guard let account = matchingAccount else {
			throw SimpleFinError.accountNotFound
		}
		
		return account
	}
	
	/// Clear stored access URL from UserDefaults
	/// 
	/// Use this method when you detect that access has been revoked and need to clear
	/// the stored access URL to force re-authentication on the next fetch.
	///
	/// - Parameter userDefaultsKey: Key used for storing the access URL in UserDefaults
	public static func clearStoredAccessURL(forKey userDefaultsKey: String) {
		UserDefaults.standard.removeObject(forKey: userDefaultsKey)
	}
	
	/// Check if an error indicates that access has been revoked
	/// 
	/// Use this helper method to determine if you need to clear stored access URLs
	/// and prompt the user to obtain a new setup token.
	///
	/// - Parameter error: The error to check
	/// - Returns: true if the error indicates access revocation
	public static func isAccessRevoked(error: Error) -> Bool {
		if let simpleFinError = error as? SimpleFinError {
			return simpleFinError == .accessRevoked
		}
		return false
	}
}
