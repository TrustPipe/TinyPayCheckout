import SwiftUI

struct Transaction: Identifiable {
    let id = UUID()
    let qrCodeContent: String
    let timestamp: Date
    let amount: String
    let currency: String
    var status: TransactionStatus
    var transactionHash: String?
    var receivedAmount: String?
    var receivedCurrency: String?
    
    enum TransactionStatus: String, CaseIterable {
        case pending = "Pending"
        case success = "Success"
        case failed = "Failed"
    }
}

struct TransactionsTabView: View {
    @EnvironmentObject var transactionsData: TransactionsData
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Total revenue display area
                VStack(spacing: 12) {
                    Text("Total Revenue")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Display each currency on its own line
                    VStack(spacing: 6) {
                        if transactionsData.revenueBreakdown.isEmpty {
                            Text("0.00 \(NetworkConfig.currentDefaultCurrency)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        } else {
                            // Sort currencies to show USDT and USDC first, then others
                            let sortedCurrencies = transactionsData.revenueBreakdown.keys.sorted { currency1, currency2 in
                                let priority1 = currencyPriority(currency1)
                                let priority2 = currencyPriority(currency2)
                                if priority1 != priority2 {
                                    return priority1 < priority2
                                }
                                return currency1 < currency2
                            }
                            
                            ForEach(sortedCurrencies, id: \.self) { currency in
                                if let amount = transactionsData.revenueBreakdown[currency] {
                                    Text(formatAmount(amount, currency: currency))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    
                    let successfulCount = transactionsData.transactions.filter { $0.status == .success }.count
                    let totalCount = transactionsData.transactions.count
                    
                    if totalCount > 0 {
                        Text("\(successfulCount) successful of \(totalCount) total transactions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                
                // Transaction list
                if transactionsData.transactions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Transactions Yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Transactions will appear here after QR code scans")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(transactionsData.transactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await refreshPendingTransactions()
                    }
                }
            }
            .navigationTitle("Transactions")
        }
    }
    
    private func refreshPendingTransactions() async {
        await transactionsData.refreshPendingTransactions()
    }
    
    private func currencyPriority(_ currency: String) -> Int {
        switch currency {
        case "USDT": return 0
        case "USDC": return 1
        case NetworkConfig.currentDefaultCurrency: return 2  // Current network's default currency
        default: return 3
        }
    }
    
    private func formatAmount(_ amount: Double, currency: String) -> String {
        // Choose appropriate decimal places based on currency and amount size
        let decimalPlaces: Int
        if amount < 0.01 {
            decimalPlaces = 8  // Small amounts show more decimal places
        } else if amount < 1.0 {
            decimalPlaces = 6
        } else if amount < 100.0 {
            decimalPlaces = 4
        } else {
            decimalPlaces = 2  // Large amounts show 2 decimal places
        }
        
        return String(format: "%.\(decimalPlaces)f %@", amount, currency)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Transaction Hash")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if transaction.status == .pending && transaction.transactionHash != nil {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(transaction.transactionHash ?? "Generating...")
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Show received amount if available, otherwise show requested amount
                    if let receivedAmount = transaction.receivedAmount,
                       let receivedCurrency = transaction.receivedCurrency {
                        let displayAmount = NetworkConfig.convertFromSmallestUnit(receivedAmount, currency: receivedCurrency)
                        Text(formatAmount(displayAmount, currency: receivedCurrency))
                            .font(.headline)
                            .foregroundColor(.green)
                    } else {
                        let displayAmount = NetworkConfig.convertFromSmallestUnit(transaction.amount, currency: transaction.currency)
                        Text(formatAmount(displayAmount, currency: transaction.currency))
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text(transaction.status.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor(transaction.status))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            HStack {
                Text(formatDate(transaction.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Show requested amount as subtitle when received amount is different
                if let receivedAmount = transaction.receivedAmount,
                   let receivedCurrency = transaction.receivedCurrency,
                   receivedAmount != transaction.amount || receivedCurrency != transaction.currency {
                    Text("Requested: \(transaction.amount) \(transaction.currency)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(_ status: Transaction.TransactionStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .success:
            return .green
        case .failed:
            return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatAmount(_ amount: Double, currency: String) -> String {
        // Choose appropriate decimal places based on currency and amount size
        let decimalPlaces: Int
        if amount < 0.01 {
            decimalPlaces = 8  // Small amounts show more decimal places
        } else if amount < 1.0 {
            decimalPlaces = 6
        } else if amount < 100.0 {
            decimalPlaces = 4
        } else {
            decimalPlaces = 2  // Large amounts show 2 decimal places
        }
        
        return String(format: "%.\(decimalPlaces)f %@", amount, currency)
    }
}
