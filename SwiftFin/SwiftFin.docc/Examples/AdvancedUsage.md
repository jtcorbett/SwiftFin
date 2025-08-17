# Advanced Usage

### Manual Setup Token Claiming

```swift
import SwiftFin

do {
// Create client manually
let client = SimpleFinClient()

// Claim setup token to get access URL
let accessURL = try await client.claimSetupToken("your-setup-token")
print("Access URL obtained: \(accessURL)")

// Now fetch accounts
let response = try await client.fetchAccounts()
print("Successfully fetched \(response.accounts.count) accounts")
} catch {
print("Setup failed: \(error)")
}
```

### Date Filtering with Unix Timestamps

```swift
import SwiftFin

do {
let client = try await SimpleFin.client(withSetupToken: "your-setup-token")

// Get transactions from last 30 days
let thirtyDaysAgo = Int(Date().addingTimeInterval(-30 * 24 * 60 * 60).timeIntervalSince1970)
let now = Int(Date().timeIntervalSince1970)

let response = try await client.fetchAccounts(startDate: thirtyDaysAgo, endDate: now)

for account in response.accounts {
print("\(account.name): \(account.transactions.count) transactions in last 30 days")
}
} catch {
print("Error filtering transactions: \(error)")
}
```

### Date Filtering with Date Objects

```swift
import SwiftFin
import Foundation

do {
let client = try await SimpleFin.client(withSetupToken: "your-setup-token")

// Get transactions from last week
let calendar = Calendar.current
let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!
let today = Date()

let response = try await client.fetchAccounts(startDate: lastWeek, endDate: today)

for account in response.accounts {
print("Account: \(account.name)")
for transaction in account.transactions {
let date = Date(timeIntervalSince1970: TimeInterval(transaction.posted))
print("  \(transaction.description): \(transaction.amount) on \(date)")
}
}
} catch {
print("Error: \(error)")
}
```
