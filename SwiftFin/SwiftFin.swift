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
}
