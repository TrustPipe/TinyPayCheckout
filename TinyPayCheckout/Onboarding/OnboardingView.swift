import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingCompleted: Bool
    @State private var receivingAddress: String = ""
    @State private var selectedNetwork: String = "eth-sepolia"
    @State private var showError: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showAddressFormatAlert: Bool = false
    
    private let networks = ["eth-sepolia", "aptos-testnet"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Logo 或 App 名称
                VStack(spacing: 16) {
                    Image("TinypayCheckout")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    Text("TinyPay")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Start your business with \nWorld wide Crypto fervor")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 80)
                
                // 输入区域
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Receiving Address")
                            .font(.headline)
                        
                        Text("Enter your wallet address to receive payments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        AddressInputField(
                            text: $receivingAddress,
                            showError: $showError
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Network")
                            .font(.headline)
                        
                        Text("Select the blockchain network")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Network", selection: $selectedNetwork) {
                            ForEach(networks, id: \.self) { network in
                                Text(network).tag(network)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if showError {
                        Text("Please enter a valid receiving address")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button("Get Started") {
                        processStartButton()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(receivingAddress.isEmpty || isProcessing)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 32)
                
                // 底部说明
                Text("You can change this address later in Settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
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
    
    private func processStartButton() {
        // 防止重复点击
        guard !isProcessing else { return }
        
        isProcessing = true
        
        // 在后台线程处理验证，UI更新在主线程
        Task {
            let isValid = AddressValidator.isValidWalletAddress(receivingAddress)
            
            await MainActor.run {
                defer { isProcessing = false }
                
                if isValid {
                    // 保存地址和网络到本地存储
                    UserDefaults.standard.set(receivingAddress, forKey: "receivingAddress")
                    UserDefaults.standard.set(selectedNetwork, forKey: "selectedNetwork")
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
}

// 分离的输入框组件，减少主视图重绘
struct AddressInputField: View {
    @Binding var text: String
    @Binding var showError: Bool
    
    var body: some View {
        TextField("0x1234...", text: $text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.asciiCapable)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .onChange(of: text) {
                if showError {
                    showError = false
                }
            }
    }
}
