import SwiftUI
import SwiftFin

/// SwiftFin Demo View
///
/// This view demonstrates the key features of SwiftFin:
/// - Organization/bank information display (org.name, org.domain, org.url)
/// - API error/warning handling (response.errors array)
/// - New query parameters:
///   - pending: Include pending transactions
///   - balancesOnly: Fetch only account balances without transaction history
///   - accountIds: Filter by specific account IDs (not shown in this demo)
/// - Transaction details including pending status and extra fields
struct SwiftFinExampleView: View {
    @State private var accounts: [Account] = []
    @State private var apiErrors: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var includePending = false
    @State private var balancesOnly = false

    // Setup token from environment variable
    private let setupToken = ProcessInfo.processInfo.environment["SWIFTFIN_SETUP_TOKEN"] ?? ""

    // UserDefaults key for storing access URL - You can use whatever string you want just make sure to save it
	// Failure to save the key means that a new setupToken will need to be generated!
    private let accessURLKey = "SwiftFin_AccessURL"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Show API errors/warnings if present
                if !apiErrors.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("API Warnings")
                                    .font(.headline)
                            }
                            ForEach(apiErrors, id: \.self) { error in
                                Text("• \(error)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .frame(maxHeight: 100)
                }

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
                    Menu {
                        Toggle("Include Pending", isOn: $includePending)
                        Toggle("Balances Only", isOn: $balancesOnly)
                        Divider()
                        Button("Refresh") {
                            fetchData()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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
        apiErrors = []

        // Check if setup token is available
        guard !setupToken.isEmpty else {
            errorMessage = "Setup token not found. Please set SWIFTFIN_SETUP_TOKEN environment variable."
            isLoading = false
            return
        }

        do {
            // Get or create the client
            let client: SimpleFinClient
            if let savedURL = UserDefaults.standard.string(forKey: accessURLKey) {
                client = SimpleFin.client(withAccessURL: savedURL)
            } else {
                client = try await SimpleFin.client(withSetupToken: setupToken)
                if let accessURL = client.accessURL {
                    UserDefaults.standard.set(accessURL, forKey: accessURLKey)
                }
            }

            // Fetch accounts with new query parameters
            let response = try await client.fetchAccounts(
                pending: includePending ? true : nil,
                balancesOnly: balancesOnly ? true : nil
            )

            // Store API errors/warnings
            self.apiErrors = response.errors

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
                    // Display organization name
                    if let orgName = account.org.name {
                        Text(orgName)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
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
                    // Organization details
                    if let orgDomain = account.org.domain {
                        HStack {
                            Text("Bank Domain:")
                                .fontWeight(.medium)
                            Text(orgDomain)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let orgUrl = account.org.url {
                        HStack {
                            Text("Bank URL:")
                                .fontWeight(.medium)
                            Link(orgUrl, destination: URL(string: orgUrl)!)
                                .font(.caption)
                        }
                    }

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
    
	// MARK: Formatting
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

// MARK: - Helper Views

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

struct SwiftFinExampleView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftFinExampleView()
        // WeeklyTransactionsView()
    }
}
