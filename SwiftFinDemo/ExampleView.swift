import SwiftUI
import SwiftFin

struct SwiftFinExampleView: View {
    @State private var accounts: [Account] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var client: SimpleFinClient?
    
    // Setup token from environment variable
    private let setupToken = ProcessInfo.processInfo.environment["SWIFTFIN_SETUP_TOKEN"] ?? ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading financial data...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.largeTitle)
                        Text("Error")
                            .font(.headline)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Retry") {
                            fetchData()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if accounts.isEmpty {
                    VStack {
                        Image(systemName: "creditcard")
                            .foregroundColor(.blue)
                            .font(.largeTitle)
                        Text("Welcome to SwiftFin")
                            .font(.headline)
                        Text("Tap 'Load Data' to fetch your financial information")
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Load Data") {
                            fetchData()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    accountsList
                }
            }
            .navigationTitle("SwiftFin Demo")
            .toolbar {
				ToolbarItem(placement: .automatic) {
                    Button("Refresh") {
                        fetchData()
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
    
    private var accountsList: some View {
        List {
            ForEach(accounts) { account in
                AccountView(account: account)
            }
        }
        .refreshable {
            await fetchDataAsync()
        }
    }
    
    private func fetchData() {
        Task {
            await fetchDataAsync()
        }
    }
    
    @MainActor
    private func fetchDataAsync() async {
        isLoading = true
        errorMessage = nil
        
        // Check if setup token is available
        guard !setupToken.isEmpty else {
            errorMessage = "Setup token not found. Please set SWIFTFIN_SETUP_TOKEN environment variable."
            isLoading = false
            return
        }
        
        do {
            // Step 1: Claim the setup token to get an access URL
            let client = try await SimpleFin.client(withSetupToken: setupToken)
            self.client = client
            
            // Step 2: Fetch accounts and transactions
            let response = try await client.fetchAccounts()
            self.accounts = response.accounts
            
        } catch let error as SimpleFinError {
            switch error {
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
            }
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct AccountView: View {
    let account: Account
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Account header
            HStack {
                VStack(alignment: .leading) {
                    Text(account.name)
                        .font(.headline)
                    Text(account.currency)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
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
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }
            
            // Account details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Account ID:")
                            .fontWeight(.medium)
                        Text(account.id)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Balance Date:")
                            .fontWeight(.medium)
                        Text(formatDate(account.balanceDateFormatted))
                            .foregroundColor(.secondary)
                    }
                    
                    if !account.transactions.isEmpty {
                        TransactionsView(transactions: account.transactions)
                    } else {
                        Text("No transactions available")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
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

struct TransactionsView: View {
    let transactions: [SwiftFin.Transaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Transactions (\(transactions.count))")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(transactions.prefix(5), id: \.id) { transaction in
                TransactionRowView(transaction: transaction)
            }
            
            if transactions.count > 5 {
                Text("... and \(transactions.count - 5) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 4)
    }
}

struct TransactionRowView: View {
    let transaction: SwiftFin.Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.subheadline)
                    .lineLimit(1)
                
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
                    
                    if let transactedDate = transaction.transactedDate,
                       transactedDate != transaction.postedDate {
                        Text("• Transacted: \(formatDate(transactedDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let memo = transaction.memo {
                    Text(memo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                if let payee = transaction.payee {
                    Text("Payee: \(payee)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Show extra fields if available
                if let extra = transaction.extra, !extra.isEmpty {
                    HStack {
                        ForEach(Array(extra.keys.prefix(3)), id: \.self) { key in
                            if let value = transaction.extraString(for: key) {
                                Text("\(key): \(value)")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            Text(formatCurrency(transaction.amountInDollars))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(transaction.isCredit ? .green : .red)
        }
        .padding(.vertical, 4)
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

// MARK: - Preview

struct SwiftFinExampleView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftFinExampleView()
    }
}
