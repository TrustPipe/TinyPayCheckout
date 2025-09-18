import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingCompleted: Bool
    @State private var receivingAddress: String = ""
    @State private var showError: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showAddressFormatAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo 或 App 名称
            VStack(spacing: 16) {
                Image(systemName: "creditcard.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("TinyPay")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Start your business with \n world wide Crypto fervor")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 输入区域
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Receiving Address")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Enter your wallet address to receive payments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField(AddressValidator.getAddressExample(), text: $receivingAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.asciiCapable)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: receivingAddress) { _ in
                            // 输入时清除错误状态，避免阻塞UI
                            if showError {
                                showError = false
                            }
                        }
                        .onTapGesture {
                            // 点击时清除错误状态
                            if showError {
                                showError = false
                            }
                        }
                }
                
                if showError {
                    Text("Please enter a valid receiving address")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Button("Get Started") {
                    // 防止重复点击
                    guard !isProcessing else { return }
                    
                    isProcessing = true
                    
                    // 在后台线程处理验证，UI更新在主线程
                    Task {
                        let isValid = AddressValidator.isValidWalletAddress(receivingAddress)
                        
                        await MainActor.run {
                            defer { isProcessing = false }
                            
                            if isValid {
                                // 保存地址到本地存储
                                UserDefaults.standard.set(receivingAddress, forKey: "receivingAddress")
                                UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
                                
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isOnboardingCompleted = true
                                }
                            } else {
                                showAddressFormatAlert = true
                            }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(receivingAddress.isEmpty || isProcessing)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // 底部说明
            Text("You can change this address later in Settings")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .alert("Invalid Address Format", isPresented: $showAddressFormatAlert) {
            Button("OK") {
                // 清空输入框，让用户重新输入
                receivingAddress = ""
            }
        } message: {
            Text(AddressValidator.getAddressFormatError())
        }
    }
}
