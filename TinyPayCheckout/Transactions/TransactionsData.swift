import SwiftUI

class TransactionsData: ObservableObject, PaymentServiceDelegate {
    @Published var transactions: [Transaction] = [] {
        didSet {
            // Recalculate total revenue when transactions change
            calculateTotalRevenue()
        }
    }
    @Published var totalRevenue: String = "0.00 \(NetworkConfig.currentDefaultCurrency)"
    @Published var revenueBreakdown: [String: Double] = [:]
    
    // Store pending transaction data until we get a hash
    private var pendingTransactionData: (qrContent: String, amount: String, currency: String)?
    
    init() {
        // Set self as delegate for payment service
        PaymentService.shared.delegate = self
        
        // Listen for network changes to update currency display
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(networkChanged), 
            name: .networkChanged, 
            object: nil
        )
        
        // Initial calculation
        calculateTotalRevenue()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func networkChanged() {
        // Recalculate revenue with new network's default currency
        calculateTotalRevenue()
    }
    
    func addTransaction(qrContent: String, amount: String, currency: String) -> UUID {
        let newTransaction = Transaction(
            qrCodeContent: qrContent,
            timestamp: Date(),
            amount: amount,
            currency: currency,
            status: .pending,
            transactionHash: nil,
            receivedAmount: nil,
            receivedCurrency: nil
        )
        transactions.insert(newTransaction, at: 0) // Latest at the top
        return newTransaction.id
    }
    
    func updateTransactionHash(transactionId: UUID, hash: String) {
        if let index = transactions.firstIndex(where: { $0.id == transactionId }) {
            transactions[index].transactionHash = hash
            print("🔗 Updated transaction \(transactionId) with hash: \(hash)")
        }
    }
    
    func updateTransactionStatus(transactionHash: String, status: Transaction.TransactionStatus) {
        if let index = transactions.firstIndex(where: { $0.transactionHash == transactionHash }) {
            transactions[index].status = status
            print("📊 Updated transaction \(transactionHash) status to: \(status.rawValue)")
        } else {
            print("⚠️ Could not find transaction with hash: \(transactionHash)")
        }
    }
    
    func updateReceivedAmount(transactionHash: String, receivedAmount: String?, receivedCurrency: String?) {
        if let index = transactions.firstIndex(where: { $0.transactionHash == transactionHash }) {
            transactions[index].receivedAmount = receivedAmount
            transactions[index].receivedCurrency = receivedCurrency
            print("💰 Updated transaction \(transactionHash) received amount: \(receivedAmount ?? "nil") \(receivedCurrency ?? "")")
        }
    }
    
    func updateTransactionStatus(transactionId: UUID, status: Transaction.TransactionStatus) {
        if let index = transactions.firstIndex(where: { $0.id == transactionId }) {
            transactions[index].status = status
            print("📊 Updated transaction \(transactionId) status to: \(status.rawValue)")
        }
    }
    
    func setPendingTransaction(qrContent: String, amount: String, currency: String) {
        pendingTransactionData = (qrContent: qrContent, amount: amount, currency: currency)
        print("📝 Stored pending transaction data")
    }
    
    // MARK: - PaymentServiceDelegate
    func paymentCreated(transactionHash: String) {
        DispatchQueue.main.async {
            // Only create transaction record when we have a valid hash
            if let pendingData = self.pendingTransactionData {
                let newTransaction = Transaction(
                    qrCodeContent: pendingData.qrContent,
                    timestamp: Date(),
                    amount: pendingData.amount,
                    currency: pendingData.currency,
                    status: .pending,
                    transactionHash: transactionHash,
                    receivedAmount: nil,
                    receivedCurrency: nil
                )
                self.transactions.insert(newTransaction, at: 0) // Latest at the top
                print("✅ Created transaction record with hash: \(transactionHash)")
                
                // Clear pending data
                self.pendingTransactionData = nil
            } else {
                print("⚠️ No pending transaction data found for hash: \(transactionHash)")
            }
        }
    }
    
    func paymentStatusUpdated(transactionHash: String, isSuccess: Bool, receivedAmount: String?, receivedCurrency: String?) {
        DispatchQueue.main.async {
            let newStatus: Transaction.TransactionStatus = isSuccess ? .success : .failed
            self.updateTransactionStatus(transactionHash: transactionHash, status: newStatus)
            
            // Update received amount if success and amount is provided
            if isSuccess && receivedAmount != nil {
                self.updateReceivedAmount(
                    transactionHash: transactionHash, 
                    receivedAmount: receivedAmount, 
                    receivedCurrency: receivedCurrency
                )
            }
        }
    }
    
    func clearPendingTransaction() {
        DispatchQueue.main.async {
            if self.pendingTransactionData != nil {
                print("🗑️ Cleared pending transaction data due to payment failure")
                self.pendingTransactionData = nil
            }
        }
    }
    
    // MARK: - Refresh Functionality
    @MainActor
    func refreshPendingTransactions() async {
        print("🔄 Starting refresh of pending transactions...")
        
        // Find all pending transactions with transaction hashes
        let pendingTransactions = transactions.filter { 
            $0.status == .pending && $0.transactionHash != nil 
        }
        
        guard !pendingTransactions.isEmpty else {
            print("ℹ️ No pending transactions with hashes to refresh")
            return
        }
        
        print("🔍 Found \(pendingTransactions.count) pending transactions to refresh")
        
        // Query status for each pending transaction
        for transaction in pendingTransactions {
            guard let hash = transaction.transactionHash else { continue }
            
            do {
                print("📊 Checking status for transaction: \(hash)")
                let statusResponse = try await PaymentService.shared.queryTransactionStatus(transactionHash: hash, network: NetworkConfig.currentNetwork.rawValue)
                
                // Update status based on business code
                switch statusResponse.code {
                case 1003:
                    // Transaction confirmed successfully
                    updateTransactionStatus(transactionHash: hash, status: .success)
                    if let receivedAmount = statusResponse.data?.received_amount {
                        updateReceivedAmount(
                            transactionHash: hash,
                            receivedAmount: String(receivedAmount),
                            receivedCurrency: statusResponse.data?.currency
                        )
                    }
                    print("✅ Updated transaction \(hash) to success")
                    
                case 1002:
                    // Transaction still pending
                    print("⏳ Transaction \(hash) still pending")
                    
                case 2005:
                    // Transaction not found - consider it failed
                    updateTransactionStatus(transactionHash: hash, status: .failed)
                    print("❌ Updated transaction \(hash) to failed (not found)")
                    
                default:
                    print("⚠️ Unexpected status code \(statusResponse.code) for transaction \(hash)")
                }
                
            } catch {
                print("❌ Failed to refresh transaction \(hash): \(error)")
            }
        }
        
        print("🔄 Refresh completed")
    }
    
    // MARK: - Revenue Calculation
    private func calculateTotalRevenue() {
        var currencyAmounts: [String: Double] = [:]
        
        // Calculate totals for each currency from successful transactions
        for transaction in transactions {
            guard transaction.status == .success else { continue }
            
            // Use received amount if available, otherwise use requested amount
            let amountString: String
            let currency: String
            
            if let receivedAmount = transaction.receivedAmount,
               let receivedCurrency = transaction.receivedCurrency {
                amountString = receivedAmount
                currency = receivedCurrency
            } else {
                amountString = transaction.amount
                currency = transaction.currency
            }
            
            // Convert from smallest unit to display format
            let displayAmount = NetworkConfig.convertFromSmallestUnit(amountString, currency: currency)
            currencyAmounts[currency, default: 0.0] += displayAmount
        }
        
        // Update the breakdown
        revenueBreakdown = currencyAmounts
        
        // Format total revenue display - show main currency or "Multiple Currencies"
        if currencyAmounts.isEmpty {
            totalRevenue = "0.00 \(NetworkConfig.currentDefaultCurrency)"
        } else if currencyAmounts.count == 1, let (currency, amount) = currencyAmounts.first {
            // Single currency
            totalRevenue = String(format: "%.2f %@", amount, currency)
        } else {
            // Multiple currencies - show total count
            let totalCurrencies = currencyAmounts.keys.count
            totalRevenue = "\(totalCurrencies) Currencies"
        }
        
        print("💰 Total revenue updated: \(totalRevenue)")
        print("💰 Revenue breakdown: \(revenueBreakdown)")
    }
}
