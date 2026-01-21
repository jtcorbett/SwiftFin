import SwiftUI
import SwiftFin

/// Weekly Transactions View
///
/// Demonstrates the new `pending` query parameter to include pending transactions
/// from the past week. Also shows how to handle API errors from response.errors.
struct WeeklyTransactionsView: View {
    @State private var accountTransactions: [(account: Account, transactions: [SwiftFin.Transaction])] = []
    @State private var selectedTransaction: SwiftFin.Transaction?
    @State private var apiErrors: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Setup token from environment variable
    private let setupToken = ProcessInfo.processInfo.environment["SWIFTFIN_SETUP_TOKEN"] ?? ""
    
    // UserDefaults key for storing access URL
    private let accessURLKey = "SwiftFin_AccessURL"
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - Accounts and transactions list
            if isLoading {
                ProgressView("Loading weekly transactions...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        fetchWeeklyTransactions()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if accountTransactions.isEmpty {
                VStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .font(.largeTitle)
                    Text("Weekly Transactions")
                        .font(.headline)
                    Text("Tap 'Load Weekly Data' to fetch transactions from the past week including pending")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Load Weekly Data") {
                        fetchWeeklyTransactions()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
				Button("Test Date Conversion") {
					testDateConversion()
				}
                weeklyTransactionsList
            }
        } detail: {
            // Detail pane - Transaction details
            transactionDetailPane
        }
        .navigationTitle("Weekly Transactions")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Refresh") {
                    fetchWeeklyTransactions()
                }
                .disabled(isLoading)
            }
        }
    }
    
    private var weeklyTransactionsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Past Week Transactions")
                        .font(.headline)
                    Spacer()
                    let totalTransactions = accountTransactions.reduce(0) { $0 + $1.transactions.count }
                    Text("\(totalTransactions) total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !accountTransactions.isEmpty {
                    let allTransactions = accountTransactions.flatMap { $0.transactions }
                    let pendingCount = allTransactions.filter { $0.isPending }.count
                    if pendingCount > 0 {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                            Text("\(pendingCount) pending transactions")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Accounts and transactions list
            List {
                ForEach(accountTransactions, id: \.account.id) { accountData in
                    Section(header: AccountHeaderView(account: accountData.account, transactionCount: accountData.transactions.count)) {
                        ForEach(accountData.transactions, id: \.id) { transaction in
                            TransactionListRowView(transaction: transaction, isSelected: selectedTransaction?.id == transaction.id)
                                .onTapGesture {
                                    selectedTransaction = transaction
                                }
                        }
                    }
                }
            }
            .refreshable {
                await fetchWeeklyTransactionsAsync()
            }
        }
    }
    
    private var transactionDetailPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let transaction = selectedTransaction {
                TransactionDetailView(transaction: transaction)
            } else {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Select a transaction")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Choose a transaction from the list to view details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func fetchWeeklyTransactions() {
        Task {
            await fetchWeeklyTransactionsAsync()
        }
    }
    
    @MainActor
    private func fetchWeeklyTransactionsAsync() async {
        isLoading = true
        errorMessage = nil
        
        guard !setupToken.isEmpty else {
            errorMessage = "Setup token not found. Please set SWIFTFIN_SETUP_TOKEN environment variable."
            isLoading = false
            return
        }
        
        do {
            // Calculate start date for one week ago
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

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

            // Fetch weekly transactions with pending=true to include pending transactions
            let response = try await client.fetchAccounts(
                startDate: oneWeekAgo,
                pending: true  // NEW: Include pending transactions
            )

            // Store API errors/warnings
            self.apiErrors = response.errors
            
            // Group transactions by account
            var accountTransactionsData: [(account: Account, transactions: [SwiftFin.Transaction])] = []
            
            for account in response.accounts {
                if !account.transactions.isEmpty {
                    // Sort transactions by posted date (most recent first)
                    let sortedTransactions = account.transactions.sorted { $0.postedDate > $1.postedDate }
                    accountTransactionsData.append((account: account, transactions: sortedTransactions))
                }
            }
            
            self.accountTransactions = accountTransactionsData
            
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
    
    
    private func testDateConversion() {
        print("Testing flexible date functionality...")
        
        Task {
            do {
                guard !setupToken.isEmpty else {
                    print("Setup token not found. Please set SWIFTFIN_SETUP_TOKEN environment variable.")
                    return
                }
                
                print("Test 1: No date parameters (fetch all)")
                _ = try await SimpleFin.fetchData(setupToken: setupToken, userDefaultsKey: accessURLKey)
                
                print("Test 2: Just start date with Date object")
                let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                _ = try await SimpleFin.fetchData(setupToken: setupToken, userDefaultsKey: accessURLKey, startDate: oneWeekAgo)
                
                print("Test 3: Both dates with Date objects")
                let today = Date()
                _ = try await SimpleFin.fetchData(setupToken: setupToken, userDefaultsKey: accessURLKey, startDate: oneWeekAgo, endDate: today)
                
                print("All tests completed successfully!")
                
            } catch {
                print("Error during testing: \(error)")
            }
        }
    }
}

struct DetailedTransactionRowView: View {
    let transaction: SwiftFin.Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.description)
                        .font(.headline)
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
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    if let transactedDate = transaction.transactedDate,
                       transactedDate != transaction.postedDate {
                        Text("Transacted: \(formatDate(transactedDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(formatCurrency(transaction.amountInDollars))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.isCredit ? .green : .red)
            }
            
            if let memo = transaction.memo, !memo.isEmpty {
                Text(memo)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            if let payee = transaction.payee, !payee.isEmpty {
                Text("Payee: \(payee)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let extra = transaction.extra, !extra.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(extra.keys), id: \.self) { key in
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
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views for Weekly Transactions

struct AccountHeaderView: View {
    let account: Account
    let transactionCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                // Show organization name
                if let orgName = account.org.name {
                    Text(orgName)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                Text(account.currency)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(account.balanceInDollars))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(account.balanceInDollars >= 0 ? .green : .red)
                Text("\(transactionCount) transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = account.currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

struct TransactionListRowView: View {
    let transaction: SwiftFin.Transaction
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .medium : .regular)
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
                }
            }
            
            Spacer()
            
            Text(formatCurrency(transaction.amountInDollars))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(transaction.isCredit ? .green : .red)
        }
        .padding(.vertical, 2)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(4)
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

struct TransactionDetailView: View {
    let transaction: SwiftFin.Transaction
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Transaction Details")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        if transaction.isPending {
                            Text("PENDING")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(formatCurrency(transaction.amountInDollars))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(transaction.isCredit ? .green : .red)
                }
                
                Divider()
                
                // Basic Information
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Description", value: transaction.description)
                    DetailRow(label: "Posted Date", value: formatDate(transaction.postedDate))
                    
                    if let transactedDate = transaction.transactedDate,
                       transactedDate != transaction.postedDate {
                        DetailRow(label: "Transacted Date", value: formatDate(transactedDate))
                    }
                    
                    DetailRow(label: "Type", value: transaction.isCredit ? "Credit" : "Debit")
                    DetailRow(label: "ID", value: transaction.id)
                }
                
                if let memo = transaction.memo, !memo.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Memo")
                            .font(.headline)
                        Text(memo)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let payee = transaction.payee, !payee.isEmpty {
                    Divider()
                    DetailRow(label: "Payee", value: payee)
                }
                
                // Extra fields
                if let extra = transaction.extra, !extra.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Information")
                            .font(.headline)
                        
                        ForEach(Array(extra.keys).sorted(), id: \.self) { key in
                            if let value = transaction.extraString(for: key) {
                                DetailRow(label: key, value: value)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}
