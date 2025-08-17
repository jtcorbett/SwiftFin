//
//  SwiftFin.swift
//  SwiftFin
//
//  Created by Effy on 2025-08-17.
//

import Foundation

public struct SimpleFin {
	/// Current version of the SimpleFin library
	public static let version = "1.0.0"
	
	/// Quick access to create a client with setup token
	public static func client(withSetupToken setupToken: String) async throws -> SimpleFinClient {
		return try await SimpleFinClient.withSetupToken(setupToken)
	}
	
	/// Quick access to create a client with access URL
	public static func client(withAccessURL accessURL: String) -> SimpleFinClient {
		let client = SimpleFinClient()
		client.setAccessURL(accessURL)
		return client
	}
}
