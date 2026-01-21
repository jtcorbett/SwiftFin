# SwiftFin

A Swift library for interacting with the SimpleFin Bridge to fetch financial data from bank accounts.

## Overview

SwiftFin provides a simple, modern Swift interface for accessing financial data through the SimpleFin protocol. The library handles authentication, API communication, and data parsing, making it easy to integrate bank account data into your iOS, macOS applications.

## Requirements

- iOS 18.0+
- macOS 15.0+

## Installation

### Swift Package Manager

Add SwiftFin to your project using Swift Package Manager:

1. In Xcode, go to File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/Effywolf/SwiftFin` 
3. Select the version you want to use

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Effywolf/SwiftFin", from: "1.0.0")
]
```

## Key Features

- **Easy Setup**: Initialize with setup tokens or access URLs
- **Async/Await Support**: Modern Swift concurrency for seamless integration
- **Advanced Filtering**:
  - Date range filtering with Unix timestamps or Date objects
  - Filter by specific account IDs
  - Include/exclude pending transactions
  - Fetch balances only (without transaction history)
- **Complete SimpleFIN Protocol Support**:
  - Organization/institution data for each account
  - Pending transaction support
  - Error message handling from API
  - All query parameters supported
- **Type Safety**: Strongly typed models for accounts, transactions, and organizations
- **Error Handling**: Comprehensive error types for robust error handling

## Why SimpleFin?

- **No Developer Costs**: Unlike other financial data aggregators, you don't pay monthly fees for bank connectivity - users manage their own connections
- **User-Controlled Privacy**: Users maintain direct relationships with their banks through SimpleFin Bridge, giving them full control over their data
- **Open Protocol**: SimpleFin is an open standard, reducing vendor lock-in compared to proprietary solutions
- **Real-time Access**: Data is fetched directly from banks without third-party delays or caching
- **Simplified Integration**: No complex API keys, webhooks, or recurring billing to manage as a developer
- **Bank-Grade Security**: Users authenticate directly with their banks, eliminating the need to store sensitive credentials

## Getting Started

To get started with SimpleFin, you'll need to obtain a setup token or access URL from SimpleFin Bridge. Visit the [SimpleFin Developer Documentation](https://beta-bridge.simplefin.org/info/developers) for setup instructions and to create your developer account.

## Quick Start

### Using a Setup Token

```swift
import SwiftFin

do {
    // Create client with setup token (automatically claims the token)
    let client = try await SimpleFin.client(withSetupToken: "your-base64-setup-token")

    // Fetch all accounts and transactions
    let response = try await client.fetchAccounts()

    // Check for API errors
    if !response.errors.isEmpty {
        print("API warnings: \(response.errors)")
    }

    print("Found \(response.accounts.count) accounts")
    for account in response.accounts {
        print("Account: \(account.name) - Balance: \(account.balance)")
    }
} catch {
    print("Error: \(error)")
}
```

### Using an Access URL

```swift
import SwiftFin

do {
    // Create client with existing access URL
    let client = SimpleFin.client(withAccessURL: "https://username:password@bridge.simplefin.org/simplefin/accounts")

    // Fetch accounts
    let response = try await client.fetchAccounts()

    // Process accounts
    for account in response.accounts {
        print("\(account.name): \(account.currency) \(account.balance)")
        print("  \(account.transactions.count) transactions")
    }
} catch {
    print("Failed to fetch accounts: \(error)")
}
```

### Advanced Filtering

```swift
// Fetch pending transactions from the last 30 days
let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
let response = try await client.fetchAccounts(
    startDate: thirtyDaysAgo,
    pending: true
)

// Fetch balances only (no transaction history)
let balances = try await client.fetchAccounts(balancesOnly: true)

// Fetch specific accounts
let accountIds = ["ACT-123", "ACT-456"]
let specificAccounts = try await client.fetchAccounts(accountIds: accountIds)

// Combine filters
let filtered = try await client.fetchAccounts(
    startDate: thirtyDaysAgo,
    endDate: Date(),
    pending: true,
    accountIds: ["ACT-123"]
)
```

## API Reference

### Core Types

- **`SimpleFin`**: Main entry point for creating clients
- **`SimpleFinClient`**: Client for making API requests
- **`SimplefinResponse`**: Response container with error messages and account data
- **`Account`**: Represents a bank account with balance and transaction data
- **`Organization`**: Financial institution/bank information
- **`Transaction`**: Individual transaction data with optional pending flag
- **`SimpleFinError`**: Error types for comprehensive error handling

### Query Parameters

All parameters are optional and use `nil` defaults:

- `accessURL: String?` - Override the stored access URL
- `startDate: Int?` or `Date?` - Include transactions on or after this date
- `endDate: Int?` or `Date?` - Include transactions before (but not on) this date
- `pending: Bool?` - Set to `true` to include pending transactions
- `balancesOnly: Bool?` - Set to `true` to fetch only balances (no transactions)
- `accountIds: [String]?` - Array of account IDs to filter results

## Documentation

For comprehensive documentation with examples, see the included documentation catalog:

- Basic usage examples
- Advanced features
- Working with account data
- SwiftUI integration examples

All Docs are made in DocC and best viewed in Xcode.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:

- Check the documentation in `SwiftFin.docc/`
- Open an issue on GitHub
- Visit [SimpleFin Developer Documentation](https://beta-bridge.simplefin.org/info/developers)
