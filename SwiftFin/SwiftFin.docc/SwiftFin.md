# ``SwiftFin``

A Swift library for interacting with the SimpleFin Bridge to fetch financial data from bank accounts.

## Overview

SwiftFin provides a simple, modern Swift interface for accessing financial data through the SimpleFin protocol. The library handles authentication, API communication, and data parsing, making it easy to integrate bank account data into your iOS 18+ or MacOS 15+ applications.

### Requirements

- iOS 18.0+
- Swift 5.9+

### Key Features

- **Easy Setup**: Initialize with setup tokens or access URLs
- **Async/Await Support**: Modern Swift concurrency for seamless integration
- **Date Filtering**: Fetch transactions within specific date ranges
- **Type Safety**: Strongly typed models for accounts and transactions
- **Error Handling**: Comprehensive error types for robust error handling

### Why SimpleFin?

- **No Developer Costs**: Unlike other financial data aggregators, you don't pay monthly fees for bank connectivity - users manage their own connections
- **User-Controlled Privacy**: Users maintain direct relationships with their banks through SimpleFin Bridge, giving them full control over their data
- **Open Protocol**: SimpleFin is an open standard, reducing vendor lock-in compared to proprietary solutions
- **Real-time Access**: Data is fetched directly from banks without third-party delays or caching
- **Simplified Integration**: No complex API keys, webhooks, or recurring billing to manage as a developer
- **Bank-Grade Security**: Users authenticate directly with their banks, eliminating the need to store sensitive credentials

### Setup

To get started with SimpleFin, you'll need to obtain a setup token or access URL from SimpleFin Bridge. Visit the [SimpleFin Developer Documentation](https://beta-bridge.simplefin.org/info/developers) for setup instructions and to create your developer account.

### Quick Start

```swift
import SwiftFin

// Using a setup token
let client = try await SimpleFin.client(withSetupToken: "your-setup-token")
let accounts = try await client.fetchAccounts()

// Using an access URL directly
let client = SimpleFin.client(withAccessURL: "your-access-url")
let accounts = try await client.fetchAccounts()
```

## Topics

### Examples
- <doc:Examples>

### Client

- ``SimpleFin``
- ``SimpleFinClient``

### Data Models

- ``Account``
- ``Transaction``
- ``SimplefinResponse``

### Error Handling

- ``SimpleFinError``

### Supporting Types

- ``ParsedURLComponents``
