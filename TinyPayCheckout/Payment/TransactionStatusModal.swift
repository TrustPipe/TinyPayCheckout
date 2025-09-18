import SwiftUI

struct TransactionStatusModal: View {
    @Binding var isPresented: Bool
    @State private var transactionStatus: TransactionModalStatus = .processing
    @State private var transactionHash: String?
    @State private var errorMessage: String?
    @State private var errorDetails: String?
    
    enum TransactionModalStatus {
        case processing
        case hashReceived(String)
        case success
        case failed(String, String?)
        case pending
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    if canDismiss {
                        isPresented = false
                    }
                }
            
            // Modal content
            VStack(spacing: 20) {
                statusIcon
                statusText
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .frame(maxWidth: 280)
        }
        .onReceive(NotificationCenter.default.publisher(for: .transactionStatusChanged)) { notification in
            print("📱 Modal received notification: \(notification.userInfo ?? [:])")
            if let userInfo = notification.userInfo,
               let status = userInfo["status"] as? String {
                let hash = userInfo["hash"] as? String
                let errorMessage = userInfo["error_message"] as? String
                let errorDetails = userInfo["error_details"] as? String
                updateStatus(status: status, hash: hash, errorMessage: errorMessage, errorDetails: errorDetails)
            } else {
                print("📱 Modal failed to parse notification userInfo")
            }
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch transactionStatus {
        case .processing:
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle())
        case .hashReceived:
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle())
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
        case .pending:
            Image(systemName: "clock.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
        }
    }
    
    @ViewBuilder
    private var statusText: some View {
        switch transactionStatus {
        case .processing:
            VStack(spacing: 8) {
                Text("Processing Transaction")
                    .font(.headline)
                Text("Connecting to server...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        case .hashReceived(let hash):
            VStack(spacing: 8) {
                Text("Transaction Submitted")
                    .font(.headline)
                Text("Hash: \(hash.prefix(10))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Checking status...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        case .success:
            VStack(spacing: 8) {
                Text("Transaction Successful")
                    .font(.headline)
                    .foregroundColor(.green)
                Text("Transaction confirmed on blockchain")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        case .failed(let message, let details):
            VStack(spacing: 8) {
                Text("Transaction Failed")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                
                if let details = details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Text("Tap anywhere to dismiss")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        case .pending:
            VStack(spacing: 8) {
                Text("Transaction Pending")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text("Still processing on blockchain")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Tap anywhere to dismiss")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var canDismiss: Bool {
        switch transactionStatus {
        case .processing, .hashReceived:
            return false
        case .success, .failed, .pending:
            return true
        }
    }
    
    private func updateStatus(status: String, hash: String?, errorMessage: String? = nil, errorDetails: String? = nil) {
        print("📱 Modal received status update: \(status), hash: \(hash ?? "nil")")
        switch status {
        case "hash_received":
            if let hash = hash {
                transactionStatus = .hashReceived(hash)
            }
        case "success":
            transactionStatus = .success
            // Auto dismiss after 2 seconds for success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isPresented = false
            }
        case "failed":
            print("📱 Modal updating to failed state")
            let message = errorMessage ?? "Unknown error"
            transactionStatus = .failed(message, errorDetails)
        case "pending":
            transactionStatus = .pending
        default:
            print("📱 Modal received unknown status: \(status)")
            break
        }
    }
}

extension Notification.Name {
    static let transactionStatusChanged = Notification.Name("transactionStatusChanged")
}

#Preview {
    TransactionStatusModal(isPresented: .constant(true))
}
