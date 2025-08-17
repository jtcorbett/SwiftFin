import SwiftUI
import SwiftFin

struct FetchSingleAccountView: View {
    @State private var accountIdentifier: String = ""
    @State private var account: Account?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Setup token from environment variable
    private let setupToken = ProcessInfo.processInfo.environment["SWIFTFIN_SETUP_TOKEN"] ?? ""
    
    // UserDefaults key for storing access URL
    private let accessURLKey = "SwiftFin_AccessURL"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Input section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Account Search")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter account name or ID (partial match supported):")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g., 'Checking', 'Account', or '123'", text: $accountIdentifier)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }
                    
                    Button("Fetch Account") {
                        fetchAccount()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || accountIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Content section
                if isLoading {
                    ProgressView("Searching for account...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.largeTitle)
                        Text("Error")
                            .font(.headline)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Try Again") {
                            fetchAccount()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let account = account {
                    SingleAccountView(account: account)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                            .font(.largeTitle)
                        Text("Search for Account")
                            .font(.headline)
                        Text("Enter an account name or ID above to fetch specific account details and transactions. Partial matches are supported - try searching for just part of an account name!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
            .navigationTitle("Fetch Single Account")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Clear") {
                        clearResults()
                    }
                    .disabled(account == nil && errorMessage == nil)
                }
            }
        }
    }
    
    private func fetchAccount() {
        Task {
            await fetchAccountAsync()
        }
    }
    
    @MainActor
    private func fetchAccountAsync() async {
        isLoading = true
        errorMessage = nil
        account = nil
        
        let trimmedIdentifier = accountIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedIdentifier.isEmpty else {
            errorMessage = "Please enter an account name or ID"
            isLoading = false
            return
        }
        
        guard !setupToken.isEmpty else {
            errorMessage = "Setup token not found. Please set SWIFTFIN_SETUP_TOKEN environment variable."
            isLoading = false
            return
        }
        
        do {
            let fetchedAccount = try await SimpleFin.fetchAccount(
                setupToken: setupToken,
                userDefaultsKey: accessURLKey,
                accountIdentifier: trimmedIdentifier
            )
            self.account = fetchedAccount
            
        } catch let error as SimpleFinError {
            switch error {
            case .accountNotFound:
                errorMessage = "No account found with name or ID: '\(trimmedIdentifier)'"
            case .invalidSetupToken:
                errorMessage = "Invalid setup token. Please check your token."
            case .invalidAccessURL:
                errorMessage = "Invalid access URL received."
            case .httpError(let statusCode):
                errorMessage = "HTTP Error: \(statusCode)"
            case .networkError(let underlyingError):
                errorMessage = "Network error: \(underlyingError.localizedDescription)"
            case .decodingError(let decodingError):
                errorMessage = "Data parsing error: \(decodingError.localizedDescription)"
            case .authenticationError:
                errorMessage = "Authentication failed."
            case .accessRevoked:
                errorMessage = "Access has been revoked. Please set up a new connection with a fresh setup token."
            @unknown default:
                errorMessage = "An unknown error occurred: \(error.localizedDescription)"
            }
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func clearResults() {
        account = nil
        errorMessage = nil
        accountIdentifier = ""
    }
}

struct SingleAccountView: View {
    let account: Account
    @State private var isExpanded = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Account header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(account.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("ID: \(account.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(account.currency)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(formatCurrency(account.balanceInDollars))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(account.balanceInDollars >= 0 ? .green : .red)
                            
                            if let availableBalance = account.availableBalanceInDollars {
                                Text("Available: \(formatCurrency(availableBalance))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Balance Date:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(account.balanceDateFormatted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Transactions section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Transactions (\(account.transactions.count))")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if isExpanded {
                        if account.transactions.isEmpty {
                            Text("No transactions available")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding()
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(account.transactions.sorted { $0.postedDate > $1.postedDate }, id: \.id) { transaction in
                                    SingleTransactionRowView(transaction: transaction)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = account.currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct SingleTransactionRowView: View {
    let transaction: SwiftFin.Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack {
                    Text(formatDate(transaction.postedDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if transaction.isPending {
                        Text("• PENDING")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }
                
                if let memo = transaction.memo, !memo.isEmpty {
                    Text(memo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(formatCurrency(transaction.amountInDollars))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(transaction.isCredit ? .green : .red)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct FetchSingleAccountView_Previews: PreviewProvider {
    static var previews: some View {
        FetchSingleAccountView()
    }
}
