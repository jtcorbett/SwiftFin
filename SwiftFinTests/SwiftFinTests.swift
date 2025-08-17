
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
			"accounts": [
				{
					"id": "checking-account",
					"name": "Checking Account",
					"currency": "USD",
					"balance": "1000.00",
					"available-balance": "950.00",
					"balance-date": 1628614046,
					"transactions": []
				},
				{
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
		
		#expect(response.accounts.count == 2)
		
		let checkingAccount = response.accounts[0]
		#expect(checkingAccount.name == "Checking Account")
		#expect(checkingAccount.availableBalanceInDollars == 950.00)
		#expect(checkingAccount.transactions.isEmpty == true)
		
		let savingsAccount = response.accounts[1]
		#expect(savingsAccount.name == "Savings Account")
		#expect(savingsAccount.transactions.count == 1)
		#expect(savingsAccount.transactions[0].description == "Interest Payment")
		#expect(savingsAccount.transactions[0].memo == "Monthly interest")
	}
	
	@Test("Date formatting for accounts and transactions")
	func dateFormatting() async throws {
		let timestamp: Int = 1628614046 // This is August 10, 2021 6:20:46 PM UTC
		
		let accountJson = """
		{
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
}

// MARK: - Test Tags

extension Tag {
	@Tag static var errorHandling: Self
	@Tag static var parsing: Self
	@Tag static var networking: Self
}
