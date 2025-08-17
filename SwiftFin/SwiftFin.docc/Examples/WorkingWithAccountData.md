# Working with Account Data

### Accessing Account Information

```swift
import SwiftFin

do {
let client = try await SimpleFin.client(withSetupToken: "your-setup-token")
let response = try await client.fetchAccounts()

for account in response.accounts {
print("Account ID: \(account.id)")
print("Name: \(account.name)")
print("Currency: \(account.currency)")
print("Balance: \(account.balance)")

if let availableBalance = account.availableBalance {
print("Available Balance: \(availableBalance)")
}

let balanceDate = Date(timeIntervalSince1970: TimeInterval(account.balanceDate))
print("Balance Date: \(balanceDate)")
print("Transactions: \(account.transactions.count)")
print("---")
}
} catch {
print("Error: \(error)")
}
```

### Processing Transaction Data

```swift
import SwiftFin

do {
let client = try await SimpleFin.client(withSetupToken: "your-setup-token")
let response = try await client.fetchAccounts()

for account in response.accounts {
print("Transactions for \(account.name):")

for transaction in account.transactions {
let postedDate = Date(timeIntervalSince1970: TimeInterval(transaction.posted))

print("  ID: \(transaction.id)")
print("  Description: \(transaction.description)")
print("  Amount: \(transaction.amount)")
print("  Posted: \(postedDate)")

if let memo = transaction.memo {
print("  Memo: \(memo)")
}

if let payee = transaction.payee {
print("  Payee: \(payee)")
}

if let transactedAt = transaction.transactedAt {
let transactionDate = Date(timeIntervalSince1970: TimeInterval(transactedAt))
print("  Transaction Date: \(transactionDate)")
}

if let pending = transaction.pending {
print("  Pending: \(pending)")
}

print("  ---")
}
}
} catch {
print("Error: \(error)")
}
```

## Error Handling

### Comprehensive Error Handling

```swift
import SwiftFin

func fetchAccountsWithErrorHandling() async {
do {
let client = try await SimpleFin.client(withSetupToken: "your-setup-token")
let response = try await client.fetchAccounts()

// Success - process accounts
print("Successfully fetched \(response.accounts.count) accounts")

} catch SimpleFinError.invalidSetupToken {
print("Invalid setup token provided")

} catch SimpleFinError.invalidAccessURL {
print("Invalid access URL")

} catch SimpleFinError.authenticationError {
print("Authentication failed - check credentials")

} catch SimpleFinError.networkError(let underlyingError) {
print("Network error: \(underlyingError.localizedDescription)")

} catch SimpleFinError.httpError(let statusCode) {
print("HTTP error with status code: \(statusCode)")

} catch SimpleFinError.decodingError(let underlyingError) {
print("Failed to decode response: \(underlyingError.localizedDescription)")

} catch {
print("Unexpected error: \(error)")
}
}
```
