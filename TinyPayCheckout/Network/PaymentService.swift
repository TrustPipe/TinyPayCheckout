import Foundation

// Protocol for receiving payment status updates
protocol PaymentServiceDelegate: AnyObject {
    func paymentCreated(transactionHash: String)
    func paymentStatusUpdated(transactionHash: String, isSuccess: Bool, receivedAmount: String?, receivedCurrency: String?)
    func clearPendingTransaction()
}

struct PaymentRequest: Codable {
    let payer_addr: String
    let opt: String
    let payee_addr: String
    let amount: Int
    let currency: String
}

// 统一的API响应格式
struct APIResponse<T: Codable>: Codable {
    let code: Int
    let data: T?
}

// 创建支付的数据结构
struct PaymentData: Codable {
    let status: String?
    let transaction_hash: String?
    let missing_fields: [String]?
}

// 查询交易状态的数据结构
struct TransactionStatusData: Codable {
    let status: String?
    let received_amount: Int?
    let currency: String?
}

typealias PaymentResponse = APIResponse<PaymentData>
typealias TransactionStatusResponse = APIResponse<TransactionStatusData>

class PaymentService {
    static let shared = PaymentService()
    
    // Base URL for the payment API - can be configured
    private let baseURL = "https://xxxxx.xyz" // Replace with actual API URL
    
    weak var delegate: PaymentServiceDelegate?
    
    private init() {}
    
    // Get error message based on business code
    private func getErrorMessage(for code: Int) -> String {
        switch code {
        case 2000:
            return "金额必须大于0"
        case 2001:
            return "金额超出限制"
        case 2002:
            return "余额不足"
        case 2003:
            return "OPT 不正确"
        case 2004:
            return "缺少必需字段"
        case 2005:
            return "交易不存在"
        default:
            return "未知错误"
        }
    }
    
    // Get error details from response
    private func getErrorDetails(_ response: PaymentResponse) -> String? {
        if let missingFields = response.data?.missing_fields, !missingFields.isEmpty {
            return "缺失字段: \(missingFields.joined(separator: ", "))"
        }
        return nil
    }
    
    // Async function to create payment transaction
    func createPayment(
        payerAddress: String,
        opt: String,
        payeeAddress: String,
        amount: String,
        currency: String
    ) async throws -> PaymentResponse {
        
        let paymentRequest = PaymentRequest(
            payer_addr: payerAddress,
            opt: opt,
            payee_addr: payeeAddress,
            amount: Int(amount) ?? 0,
            currency: currency
        )
        
        guard let url = URL(string: "\(baseURL)/api/payments") else {
            throw PaymentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(paymentRequest)
            request.httpBody = jsonData
            
            print("📤 Sending payment request to: \(url)")
            print("📦 Request body: \(String(data: jsonData, encoding: .utf8) ?? "Invalid JSON")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PaymentError.invalidResponse
            }
            
            print("📥 Response status: \(httpResponse.statusCode)")
            print("📄 Response data: \(String(data: data, encoding: .utf8) ?? "No data")")
            
            let paymentResponse = try JSONDecoder().decode(PaymentResponse.self, from: data)
            
            // Check for HTTP error status codes or business error codes
            if httpResponse.statusCode >= 400 || paymentResponse.code >= 2000 {
                let errorMessage = getErrorMessage(for: paymentResponse.code)
                let errorDetails = getErrorDetails(paymentResponse)
                print("❌ Server returned error code: \(paymentResponse.code)")
                print("❌ Error message: \(errorMessage)")
                print("❌ Error details: \(errorDetails ?? "No details")")
                throw PaymentError.serverError(errorMessage, errorDetails)
            }
            
            return paymentResponse
            
        } catch let decodingError as DecodingError {
            print("❌ JSON decoding error: \(decodingError)")
            throw PaymentError.decodingError(decodingError)
        } catch let paymentError as PaymentError {
            // Re-throw PaymentError directly (including serverError)
            print("❌ Payment error: \(paymentError)")
            throw paymentError
        } catch let networkError {
            print("❌ Network error: \(networkError)")
            throw PaymentError.networkError(networkError)
        }
    }
    
    // Async function to query transaction status
    func queryTransactionStatus(transactionHash: String) async throws -> TransactionStatusResponse {
        guard let url = URL(string: "\(baseURL)/api/payments/\(transactionHash)") else {
            throw PaymentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            print("� Querying transaction status: \(url)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PaymentError.invalidResponse
            }
            
            print("📥 Response status: \(httpResponse.statusCode)")
            print("📄 Response data: \(String(data: data, encoding: .utf8) ?? "No data")")
            
            let statusResponse = try JSONDecoder().decode(TransactionStatusResponse.self, from: data)
            
            // Check for HTTP error status codes
            if httpResponse.statusCode >= 400 || statusResponse.code >= 2000 {
                let errorMessage = getErrorMessage(for: statusResponse.code)
                print("❌ Transaction query error code: \(statusResponse.code)")
                print("❌ Error message: \(errorMessage)")
                throw PaymentError.serverError(errorMessage, nil)
            }
            
            return statusResponse
            
        } catch let decodingError as DecodingError {
            print("❌ JSON decoding error: \(decodingError)")
            throw PaymentError.decodingError(decodingError)
        } catch let networkError {
            print("❌ Network error: \(networkError)")
            throw PaymentError.networkError(networkError)
        }
    }
    
    // Legacy function for backward compatibility - creates payment and queries status with polling
    func createPaymentRequest(
        payerAddress: String,
        opt: String,
        payeeAddress: String,
        amount: String,
        currency: String
    ) {
        Task {
            do {
                let response = try await createPayment(
                    payerAddress: payerAddress,
                    opt: opt,
                    payeeAddress: payeeAddress,
                    amount: amount,
                    currency: currency
                )
                print("✅ Payment created successfully: \(response)")
                
                // Check if we got a transaction hash (code 1001 means success with hash)
                if response.code == 1001, let transactionHash = response.data?.transaction_hash, !transactionHash.isEmpty {
                    // Notify modal about hash received on main thread
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .transactionStatusChanged,
                            object: nil,
                            userInfo: ["status": "hash_received", "hash": transactionHash]
                        )
                    }
                    delegate?.paymentCreated(transactionHash: transactionHash)
                    await pollTransactionStatus(transactionHash: transactionHash)
                } else {
                    // No transaction hash or empty hash means failure
                    print("❌ No transaction hash received from server")
                    delegate?.clearPendingTransaction()
                    let errorMessage = getErrorMessage(for: response.code)
                    let errorDetails = getErrorDetails(response)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .transactionStatusChanged,
                            object: nil,
                            userInfo: [
                                "status": "failed", 
                                "hash": nil,
                                "error_message": errorMessage,
                                "error_details": errorDetails
                            ]
                        )
                    }
                }
            } catch {
                print("❌ Payment creation failed: \(error)")
                // Clear pending transaction data
                delegate?.clearPendingTransaction()
                
                // Extract error details if it's a server error
                var errorMessage = "Unknown error"
                var errorDetails: String? = nil
                
                if case PaymentError.serverError(let message, let details) = error {
                    errorMessage = message
                    errorDetails = details
                } else {
                    errorMessage = error.localizedDescription
                }
                
                // Notify modal about failure on main thread
                DispatchQueue.main.async {
                    print("📢 Sending failure notification to modal")
                    NotificationCenter.default.post(
                        name: .transactionStatusChanged,
                        object: nil,
                        userInfo: [
                            "status": "failed", 
                            "hash": nil,
                            "error_message": errorMessage,
                            "error_details": errorDetails
                        ]
                    )
                }
            }
        }
    }
    
    // Poll transaction status up to 5 times with 1-second intervals
    private func pollTransactionStatus(transactionHash: String) async {
        print("🔍 Starting transaction status polling for: \(transactionHash)")
        
        let maxAttempts = 5
        let pollInterval: UInt64 = 1_000_000_000 // 1 second in nanoseconds
        
        for attempt in 1...maxAttempts {
            print("📊 Polling attempt \(attempt)/\(maxAttempts)")
            
            do {
                let statusResponse = try await queryTransactionStatus(transactionHash: transactionHash)
                print("📋 Transaction status response: \(statusResponse)")
                
                // Check business status code
                switch statusResponse.code {
                case 1003:
                    // Transaction confirmed successfully
                    print("✅ Transaction confirmed successfully!")
                    print("💰 Received amount: \(statusResponse.data?.received_amount?.description ?? "Unknown")")
                    print("💱 Currency: \(statusResponse.data?.currency ?? "Unknown")")
                    delegate?.paymentStatusUpdated(
                        transactionHash: transactionHash, 
                        isSuccess: true,
                        receivedAmount: statusResponse.data?.received_amount?.description,
                        receivedCurrency: statusResponse.data?.currency
                    )
                    // Notify modal about success on main thread
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .transactionStatusChanged,
                            object: nil,
                            userInfo: ["status": "success", "hash": transactionHash]
                        )
                    }
                    return // Exit polling as transaction is complete
                    
                case 1002:
                    // Transaction still pending
                    print("⏱️ Transaction still pending (code 1002)")
                    // Continue polling
                    
                default:
                    // Unexpected status code
                    print("⚠️ Unexpected status code: \(statusResponse.code)")
                    // Continue polling for now
                }
                
                // If not the last attempt, wait before next poll
                if attempt < maxAttempts {
                    print("⏱️ Waiting 1 second before next attempt...")
                    do {
                        try await Task.sleep(nanoseconds: pollInterval)
                    } catch {
                        print("⚠️ Sleep interrupted: \(error)")
                    }
                }
                
            } catch {
                print("❌ Failed to query transaction status (attempt \(attempt)): \(error)")
                
                // If not the last attempt, wait before retry
                if attempt < maxAttempts {
                    print("⏱️ Waiting 1 second before retry...")
                    do {
                        try await Task.sleep(nanoseconds: pollInterval)
                    } catch {
                        print("⚠️ Sleep interrupted: \(error)")
                    }
                }
            }
        }
        
        // If we reach here, all 5 attempts were made without definitive result
        print("⏳ Transaction status still pending after \(maxAttempts) attempts")
        print("📄 Final status: PENDING - Transaction may still be processing")
        
        // Notify modal about pending status on main thread
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .transactionStatusChanged,
                object: nil,
                userInfo: ["status": "pending", "hash": transactionHash]
            )
        }
    }
}

// Custom error types for payment operations
enum PaymentError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(DecodingError)
    case serverError(String, String?)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid server response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "JSON decoding error: \(error.localizedDescription)"
        case .serverError(let message, let details):
            return "Server error: \(message). \(details ?? "")"
        }
    }
}
