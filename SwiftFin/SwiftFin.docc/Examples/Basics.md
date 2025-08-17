# Basic Usage

### Creating a Client with Setup Token

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

### Creating a Client with Access URL

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
