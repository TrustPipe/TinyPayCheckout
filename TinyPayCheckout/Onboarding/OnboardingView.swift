import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingCompleted: Bool
    @State private var receivingAddress: String = ""
    @State private var selectedNetwork = NetworkConfig.NetworkType.solanaDevnet
    @State private var showError: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showAddressFormatAlert: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Logo or App name
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
                
                // Input area
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
                            ForEach(NetworkConfig.allNetworks, id: \.self) { network in
                                Text(network.displayName).tag(network)
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
                
                // Bottom description
                Text("You can change this address later in Settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
        .alert("Invalid Address Format", isPresented: $showAddressFormatAlert) {
            Button("OK") {
                // Clear input field, let user re-enter
                receivingAddress = ""
            }
        } message: {
            Text(AddressValidator.getAddressFormatError(for: selectedNetwork))
        }
    }
    
    private func processStartButton() {
        // Prevent duplicate clicks
        guard !isProcessing else { return }
        
        isProcessing = true
        
        // Handle validation in background thread, UI updates on main thread
        Task {
            let isValid = AddressValidator.isValidWalletAddress(receivingAddress, for: selectedNetwork)
            
            await MainActor.run {
                defer { isProcessing = false }
                
                if isValid {
                    // Save address and network to local storage
                    UserDefaults.standard.set(receivingAddress, forKey: "receivingAddress")
                    NetworkConfig.setCurrentNetwork(selectedNetwork)
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

// Separate input field component to reduce main view redraws
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
