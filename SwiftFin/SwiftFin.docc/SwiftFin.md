# ``SwiftFin``

A Swift library for interacting with the SimpleFin Bridge API to fetch financial data from bank accounts.

## Overview

SwiftFin provides a simple, modern Swift interface for accessing financial data through the SimpleFin protocol. The library handles authentication, API communication, and data parsing, making it easy to integrate bank account data into your Swift applications.

### Key Features

- **Easy Setup**: Initialize with setup tokens or access URLs
- **Async/Await Support**: Modern Swift concurrency for seamless integration
- **Date Filtering**: Fetch transactions within specific date ranges
- **Type Safety**: Strongly typed models for accounts and transactions
- **Error Handling**: Comprehensive error types for robust error handling

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
