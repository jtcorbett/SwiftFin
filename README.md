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
2. Enter the repository URL: `https://github.com/Effywolf/SwiftFin` (replace with actual URL)
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
- **Date Filtering**: Fetch transactions within specific date ranges
- **Type Safety**: Strongly typed models for accounts and transactions
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

## API Reference

### Core Types

- **`SimpleFin`**: Main entry point for creating clients
- **`SimpleFinClient`**: Client for making API requests
- **`Account`**: Represents a bank account with balance and transaction data
- **`Transaction`**: Individual transaction data
- **`SimplefinResponse`**: Response container for account data
- **`SimpleFinError`**: Error types for comprehensive error handling

## Documentation

For comprehensive documentation with examples, see the included documentation catalog:

- Basic usage examples
- Advanced features
- Working with account data
- SwiftUI integration examples

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
