# SwiftUI Integration

### Simple Account List View

```swift
import SwiftUI
import SwiftFin

struct AccountListView: View {
@State private var accounts: [Account] = []
@State private var isLoading = false
@State private var errorMessage: String?

let setupToken: String

var body: some View {
NavigationView {
Group {
if isLoading {
ProgressView("Loading accounts...")
} else if accounts.isEmpty {
Text("No accounts found")
.foregroundColor(.secondary)
} else {
List(accounts) { account in
VStack(alignment: .leading, spacing: 4) {
Text(account.name)
.font(.headline)
Text("\(account.currency) \(account.balance)")
.font(.subheadline)
.foregroundColor(.secondary)
Text("\(account.transactions.count) transactions")
.font(.caption)
.foregroundColor(.secondary)
}
.padding(.vertical, 2)
}
}
}
.navigationTitle("Accounts")
.refreshable {
await loadAccounts()
}
}
.task {
await loadAccounts()
}
.alert("Error", isPresented: .constant(errorMessage != nil)) {
Button("OK") {
errorMessage = nil
}
} message: {
if let errorMessage = errorMessage {
Text(errorMessage)
}
}
}

private func loadAccounts() async {
isLoading = true
errorMessage = nil

do {
let client = try await SimpleFin.client(withSetupToken: setupToken)
let response = try await client.fetchAccounts()
await MainActor.run {
self.accounts = response.accounts
self.isLoading = false
}
} catch {
await MainActor.run {
self.errorMessage = error.localizedDescription
self.isLoading = false
}
}
}
}
```
