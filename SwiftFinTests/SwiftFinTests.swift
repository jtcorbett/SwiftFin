
import Testing
@testable import SwiftFin
import Foundation

struct SwiftFinTests {
	
	@Test("String Base64 encoding and decoding")
	func stringBase64Extensions() async throws {
		let original = "Hello, World!"
		let base64 = original.toBase64()
		let decoded = base64.fromBase64()
		
		#expect(decoded == original)
	}
	
	@Test("Account balance conversion to dollars")
	func accountBalanceInDollars() async throws {
		let json = """
		{
			"org": {
				"domain": "testbank.com",
				"sfin-url": "https://beta-bridge.simplefin.org/simplefin"
			},
			"id": "test-account",
			"name": "Test Account",
			"currency": "USD",
			"balance": "1234.56",
			"balance-date": 1628614046,
			"transactions": []
		}
		"""

		let data = json.data(using: .utf8)!
		let account = try JSONDecoder().decode(Account.self, from: data)

		#expect(account.balanceInDollars == 1234.56)
		#expect(account.name == "Test Account")
		#expect(account.currency == "USD")
		#expect(account.org.domain == "testbank.com")
	}
	
	@Test("Transaction debit/credit detection")
	func transactionProperties() async throws {
		let debitJson = """
		{
			"id": "test-transaction-debit",
			"posted": 1628614046,
			"amount": "-50.25",
			"description": "Test Debit Transaction"
		}
		"""
		
		let creditJson = """
		{
			"id": "test-transaction-credit",
			"posted": 1628614046,
			"amount": "100.75",
			"description": "Test Credit Transaction"
		}
		"""
		
		let debitData = debitJson.data(using: .utf8)!
		let creditData = creditJson.data(using: .utf8)!
		
		let debitTransaction = try JSONDecoder().decode(Transaction.self, from: debitData)
		let creditTransaction = try JSONDecoder().decode(Transaction.self, from: creditData)
		
		// Test debit transaction
		#expect(debitTransaction.amountInDollars == -50.25)
		#expect(debitTransaction.isDebit == true)
		#expect(debitTransaction.isCredit == false)
		
		// Test credit transaction
		#expect(creditTransaction.amountInDollars == 100.75)
		#expect(creditTransaction.isCredit == true)
		#expect(creditTransaction.isDebit == false)
	}
	
	@Test("SimpleFin response decoding with multiple accounts")
	func simpleFinResponseDecoding() async throws {
		let json = """
		{
			"errors": [],
			"accounts": [
				{
					"org": {
						"domain": "mybank.com",
						"sfin-url": "https://beta-bridge.simplefin.org/simplefin",
						"name": "My Bank"
					},
					"id": "checking-account",
					"name": "Checking Account",
					"currency": "USD",
					"balance": "1000.00",
					"available-balance": "950.00",
					"balance-date": 1628614046,
					"transactions": []
				},
				{
					"org": {
						"domain": "mybank.com",
						"sfin-url": "https://beta-bridge.simplefin.org/simplefin",
						"name": "My Bank"
					},
					"id": "savings-account",
					"name": "Savings Account",
					"currency": "USD",
					"balance": "5000.00",
					"balance-date": "1628614046",
					"transactions": [
						{
							"id": "txn-1",
							"posted": 1628614046,
							"amount": "25.00",
							"description": "Interest Payment",
							"memo": "Monthly interest"
						}
					]
				}
			]
		}
		"""

		let data = json.data(using: .utf8)!
		let response = try JSONDecoder().decode(SimplefinResponse.self, from: data)

		#expect(response.errors.isEmpty == true)
		#expect(response.accounts.count == 2)

		let checkingAccount = response.accounts[0]
		#expect(checkingAccount.name == "Checking Account")
		#expect(checkingAccount.availableBalanceInDollars == 950.00)
		#expect(checkingAccount.transactions.isEmpty == true)
		#expect(checkingAccount.org.domain == "mybank.com")
		#expect(checkingAccount.org.name == "My Bank")
		#expect(checkingAccount.org.sfinUrl == "https://beta-bridge.simplefin.org/simplefin")

		let savingsAccount = response.accounts[1]
		#expect(savingsAccount.name == "Savings Account")
		#expect(savingsAccount.transactions.count == 1)
		#expect(savingsAccount.transactions[0].description == "Interest Payment")
		#expect(savingsAccount.transactions[0].memo == "Monthly interest")
		#expect(savingsAccount.org.domain == "mybank.com")
	}
	
	@Test("Date formatting for accounts and transactions")
	func dateFormatting() async throws {
		let timestamp: Int = 1628614046 // This is August 10, 2021 6:20:46 PM UTC

		let accountJson = """
		{
			"org": {
				"sfin-url": "https://beta-bridge.simplefin.org/simplefin"
			},
			"id": "test-account",
			"name": "Test Account",
			"currency": "USD",
			"balance": "100.00",
			"balance-date": \(timestamp),
			"transactions": []
		}
		"""

		let transactionJson = """
		{
			"id": "test-transaction",
			"posted": \(timestamp),
			"amount": "25.00",
			"description": "Test Transaction"
		}
		"""

		let accountData = accountJson.data(using: .utf8)!
		let transactionData = transactionJson.data(using: .utf8)!

		let account = try JSONDecoder().decode(Account.self, from: accountData)
		let transaction = try JSONDecoder().decode(Transaction.self, from: transactionData)

		let expectedDate = Date(timeIntervalSince1970: TimeInterval(timestamp))

		#expect(account.balanceDateFormatted == expectedDate)
		#expect(transaction.postedDate == expectedDate)
	}

	@Test("Organization model decoding with all fields")
	func organizationDecoding() async throws {
		let json = """
		{
			"org": {
				"domain": "www.chase.com",
				"sfin-url": "https://beta-bridge.simplefin.org/simplefin",
				"name": "Chase Bank",
				"url": "https://www.chase.com",
				"id": "www.chase.com"
			},
			"id": "test-account",
			"name": "Test Account",
			"currency": "USD",
			"balance": "100.00",
			"balance-date": 1628614046,
			"transactions": []
		}
		"""

		let data = json.data(using: .utf8)!
		let account = try JSONDecoder().decode(Account.self, from: data)

		#expect(account.org.domain == "www.chase.com")
		#expect(account.org.sfinUrl == "https://beta-bridge.simplefin.org/simplefin")
		#expect(account.org.name == "Chase Bank")
		#expect(account.org.url == "https://www.chase.com")
		#expect(account.org.id == "www.chase.com")
	}

	@Test("Organization model with minimal fields")
	func organizationMinimalFields() async throws {
		let json = """
		{
			"org": {
				"sfin-url": "https://beta-bridge.simplefin.org/simplefin"
			},
			"id": "test-account",
			"name": "Test Account",
			"currency": "USD",
			"balance": "100.00",
			"balance-date": 1628614046,
			"transactions": []
		}
		"""

		let data = json.data(using: .utf8)!
		let account = try JSONDecoder().decode(Account.self, from: data)

		#expect(account.org.sfinUrl == "https://beta-bridge.simplefin.org/simplefin")
		#expect(account.org.domain == nil)
		#expect(account.org.name == nil)
		#expect(account.org.url == nil)
		#expect(account.org.id == nil)
	}

	@Test("Response with errors field")
	func responseWithErrors() async throws {
		let json = """
		{
			"errors": ["Connection timeout", "Retry recommended"],
			"accounts": []
		}
		"""

		let data = json.data(using: .utf8)!
		let response = try JSONDecoder().decode(SimplefinResponse.self, from: data)

		#expect(response.errors.count == 2)
		#expect(response.errors[0] == "Connection timeout")
		#expect(response.errors[1] == "Retry recommended")
		#expect(response.accounts.isEmpty == true)
	}

	@Test("Response with empty errors array")
	func responseWithEmptyErrors() async throws {
		let json = """
		{
			"errors": [],
			"accounts": [
				{
					"org": {
						"sfin-url": "https://test.com"
					},
					"id": "test",
					"name": "Test",
					"currency": "USD",
					"balance": "0",
					"balance-date": 1628614046,
					"transactions": []
				}
			]
		}
		"""

		let data = json.data(using: .utf8)!
		let response = try JSONDecoder().decode(SimplefinResponse.self, from: data)

		#expect(response.errors.isEmpty == true)
		#expect(response.accounts.count == 1)
	}

	@Test("New query parameters compilation test", .tags(.networking))
	func newQueryParameters() async throws {
		let client = SimpleFinClient()

		// Test that all new parameter combinations compile
		// Use explicit Int? type to avoid ambiguity between Int and Date overloads
		do {
			_ = try await client.fetchAccounts(startDate: nil as Int?, pending: true)
		} catch SimpleFinError.invalidAccessURL {
			#expect(Bool(true))
		}

		do {
			_ = try await client.fetchAccounts(startDate: nil as Int?, balancesOnly: true)
		} catch SimpleFinError.invalidAccessURL {
			#expect(Bool(true))
		}

		do {
			_ = try await client.fetchAccounts(startDate: nil as Int?, accountIds: ["ACT-123", "ACT-456"])
		} catch SimpleFinError.invalidAccessURL {
			#expect(Bool(true))
		}

		do {
			_ = try await client.fetchAccounts(
				startDate: 1628614046,
				pending: true,
				balancesOnly: false,
				accountIds: ["ACT-123"]
			)
		} catch SimpleFinError.invalidAccessURL {
			#expect(Bool(true))
		}

		// Test Date-based version
		do {
			let date = Date()
			_ = try await client.fetchAccounts(startDate: date, pending: true)
		} catch SimpleFinError.invalidAccessURL {
			#expect(Bool(true))
		}
	}
	
	@Test("SimpleFinClient initialization")
	func clientInitialization() async throws {
		let client = SimpleFinClient()
		#expect(client != nil)
		
		// Test that we can create a client with custom session
		let customSession = URLSession(configuration: .ephemeral)
		let clientWithCustomSession = SimpleFinClient(session: customSession)
		#expect(clientWithCustomSession != nil)
	}
	
	@Test("Error types exist", .tags(.errorHandling))
	func errorTypes() async throws {
		// Test that our error types can be created
		let invalidTokenError = SimpleFinError.invalidSetupToken
		let networkError = SimpleFinError.networkError(URLError(.badURL))
		let httpError = SimpleFinError.httpError(404)
		
		#expect(invalidTokenError != nil)
		#expect(networkError != nil)
		#expect(httpError != nil)
	}
	
	@Test("Handle string and integer balance dates", .tags(.parsing))
	func balanceDateParsing() async throws {
		// Test with string balance-date
		let jsonWithStringDate = """
		{
			"org": {"sfin-url": "https://test.com"},
			"id": "test-account",
			"name": "Test Account",
			"currency": "USD",
			"balance": "100.00",
			"balance-date": "1628614046",
			"transactions": []
		}
		"""

		// Test with integer balance-date
		let jsonWithIntDate = """
		{
			"org": {"sfin-url": "https://test.com"},
			"id": "test-account",
			"name": "Test Account",
			"currency": "USD",
			"balance": "100.00",
			"balance-date": 1628614046,
			"transactions": []
		}
		"""

		let stringDateData = jsonWithStringDate.data(using: .utf8)!
		let intDateData = jsonWithIntDate.data(using: .utf8)!

		let accountFromString = try JSONDecoder().decode(Account.self, from: stringDateData)
		let accountFromInt = try JSONDecoder().decode(Account.self, from: intDateData)

		#expect(accountFromString.balanceDate == 1628614046)
		#expect(accountFromInt.balanceDate == 1628614046)
		#expect(accountFromString.balanceDateFormatted == accountFromInt.balanceDateFormatted)
	}
	
	@Test("Date parameter support", .tags(.networking))
	func dateParameterSupport() async throws {
		let client = SimpleFinClient()
		
		let startTimestamp = 1628614046  // August 10, 2021
		let endTimestamp = 1629614046    // August 22, 2021
		
		// Test that the method signatures accept both date parameters without compilation error
		do {
			// This will fail with invalid access URL, but confirms method signature works
			_ = try await client.fetchAccounts(startDate: startTimestamp, endDate: endTimestamp)
		} catch SimpleFinError.invalidAccessURL {
			// Expected - we don't have a valid access URL set
			#expect(true)
		} catch {
			// Any other error means something unexpected happened
			#expect(false, "Unexpected error: \(error)")
		}
		
		// Test individual parameters
		do {
			_ = try await client.fetchAccounts(startDate: startTimestamp)
		} catch SimpleFinError.invalidAccessURL {
			#expect(true)
		}
		
		do {
			_ = try await client.fetchAccounts(endDate: endTimestamp)
		} catch SimpleFinError.invalidAccessURL {
			#expect(true)
		}
		
		// Test static method with access URL
		do {
			_ = try await client.fetchAccounts(accessURL: "invalid-url", startDate: startTimestamp, endDate: endTimestamp)
		} catch SimpleFinError.invalidAccessURL {
			#expect(true)
		}
	}
	
	@Test("SimpleFin namespace functions")
	func simpleFinNamespace() async throws {
		#expect(SimpleFin.version == "1.0.0")
		
		// Test that convenience functions exist (we can't test the actual network calls without mocking)
		let client = SimpleFin.client(withAccessURL: "https://example.com")
		#expect(client != nil)
	}
	
	@Test("Extended transaction fields support", .tags(.parsing))
	func extendedTransactionFields() async throws {
		// Test transaction with all fields including new ones
		let jsonWithAllFields = """
		{
			"id": "extended-transaction",
			"posted": 1628614046,
			"amount": "-75.50",
			"description": "Extended Transaction Test",
			"memo": "Transaction memo",
			"payee": "Test Payee",
			"transacted_at": 1628614000,
			"pending": true,
			"extra": {
				"category": "food",
				"reference_number": "REF123",
				"merchant_id": 456,
				"tax_amount": 7.55,
				"is_recurring": false
			}
		}
		"""
		
		let data = jsonWithAllFields.data(using: .utf8)!
		let transaction = try JSONDecoder().decode(Transaction.self, from: data)
		
		// Test basic fields
		#expect(transaction.id == "extended-transaction")
		#expect(transaction.description == "Extended Transaction Test")
		#expect(transaction.memo == "Transaction memo")
		#expect(transaction.payee == "Test Payee")
		#expect(transaction.amountInDollars == -75.50)
		
		// Test new fields
		#expect(transaction.transactedAt == 1628614000)
		#expect(transaction.pending == true)
		#expect(transaction.isPending == true)
		
		// Test transacted date convenience method
		let expectedTransactedDate = Date(timeIntervalSince1970: TimeInterval(1628614000))
		#expect(transaction.transactedDate == expectedTransactedDate)
		
		// Test extra field access methods
		#expect(transaction.extraString(for: "category") == "food")
		#expect(transaction.extraString(for: "reference_number") == "REF123")
		#expect(transaction.extraInt(for: "merchant_id") == 456)
		#expect(transaction.extraDouble(for: "tax_amount") == 7.55)
		#expect(transaction.extraBool(for: "is_recurring") == false)
		
		// Test missing extra field
		#expect(transaction.extraString(for: "nonexistent") == nil)
	}
	
	@Test("Transaction with minimal fields", .tags(.parsing))
	func transactionMinimalFields() async throws {
		// Test transaction with only required fields
		let jsonMinimal = """
		{
			"id": "minimal-transaction",
			"posted": 1628614046,
			"amount": "100.00",
			"description": "Minimal Transaction"
		}
		"""
		
		let data = jsonMinimal.data(using: .utf8)!
		let transaction = try JSONDecoder().decode(Transaction.self, from: data)
		
		// Test required fields
		#expect(transaction.id == "minimal-transaction")
		#expect(transaction.posted == 1628614046)
		#expect(transaction.amount == "100.00")
		#expect(transaction.description == "Minimal Transaction")
		
		// Test optional fields are nil
		#expect(transaction.memo == nil)
		#expect(transaction.payee == nil)
		#expect(transaction.transactedAt == nil)
		#expect(transaction.pending == nil)
		#expect(transaction.extra == nil)
		
		// Test convenience methods with nil values
		#expect(transaction.transactedDate == nil)
		#expect(transaction.isPending == false) // Default when pending is nil
	}
	
	@Test("Transaction with string timestamps", .tags(.parsing))
	func transactionStringTimestamps() async throws {
		// Test transaction with string-based timestamps (some APIs return strings)
		let jsonWithStringTimestamps = """
		{
			"id": "string-timestamp-transaction",
			"posted": "1628614046",
			"amount": "50.25",
			"description": "String Timestamp Test",
			"transacted_at": "1628614000"
		}
		"""
		
		let data = jsonWithStringTimestamps.data(using: .utf8)!
		let transaction = try JSONDecoder().decode(Transaction.self, from: data)
		
		// Test that string timestamps are properly converted
		#expect(transaction.posted == 1628614046)
		#expect(transaction.transactedAt == 1628614000)
		
		// Test date conversion works with string-based timestamps
		let expectedPostedDate = Date(timeIntervalSince1970: TimeInterval(1628614046))
		let expectedTransactedDate = Date(timeIntervalSince1970: TimeInterval(1628614000))
		#expect(transaction.postedDate == expectedPostedDate)
		#expect(transaction.transactedDate == expectedTransactedDate)
	}
}

// MARK: - Test Tags

extension Tag {
	@Tag static var errorHandling: Self
	@Tag static var parsing: Self
	@Tag static var networking: Self
}
