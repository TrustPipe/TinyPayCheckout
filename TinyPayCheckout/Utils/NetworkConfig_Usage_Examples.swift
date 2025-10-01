// NetworkConfig Usage Examples
// This file demonstrates how to use NetworkConfig in various components

/*
=== Usage in AmountSetterView ===

import SwiftUI

struct AmountSetterView: View {
    @Binding var amount: String
    @Binding var selectedCurrency: String
    @Binding var isPresented: Bool
    
    @State private var currentNetwork = NetworkConfig.currentNetwork
    
    private var currencies: [String] {
        return NetworkConfig.currentSupportedCurrencies
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Set Charge Amount")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Display current network
                HStack {
                    Image(systemName: currentNetwork.iconName)
                        .foregroundColor(Color(currentNetwork.accentColor))
                    Text(currentNetwork.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    TextField("Enter amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title)
                        .multilineTextAlignment(.center)
                    
                    Picker("Select currency", selection: $selectedCurrency) {
                        ForEach(currencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
                
                if !amount.isEmpty {
                    Text("The total bill is \(amount) \(selectedCurrency)")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                updateCurrencySelection()
            }
            .onReceive(NotificationCenter.default.publisher(for: .networkChanged)) { _ in
                currentNetwork = NetworkConfig.currentNetwork
                updateCurrencySelection()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .disabled(amount.isEmpty)
                }
            }
        }
    }
    
    private func updateCurrencySelection() {
        selectedCurrency = NetworkConfig.getValidCurrency(selectedCurrency)
    }
}

=== Usage in SettingsTabView ===

import SwiftUI

struct SettingsTabView: View {
    @State private var receivingAddress: String = UserDefaults.standard.string(forKey: "receivingAddress") ?? ""
    @State private var newAddress: String = ""
    @State private var selectedNetwork = NetworkConfig.currentNetwork
    @State private var usePaymaster: Bool = true
    @State private var privateKey: String = ""
    @State private var kycText: String = "Enable KYC"
    @State private var showAddressFormatAlert: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Current receiving address display area
                VStack(spacing: 12) {
                    Text("Current Receiving Address")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if receivingAddress.isEmpty {
                        Text("No Address Set")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    } else {
                        Text(receivingAddress)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .padding(.horizontal, 16)
                    }
                    
                    Text("This address will receive all payments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                
                // Settings options list
                Form {
                    Section(header: Text("Change Address")) {
                        TextField(AddressValidator.getAddressExample(), text: $newAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.asciiCapable)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.vertical, 4)
                        
                        Button("Save") {
                            if !newAddress.isEmpty {
                                // Validate address format
                                if AddressValidator.isValidWalletAddress(newAddress) {
                                    receivingAddress = newAddress
                                    UserDefaults.standard.set(newAddress, forKey: "receivingAddress")
                                    newAddress = "" // Clear input field
                                } else {
                                    showAddressFormatAlert = true
                                }
                            }
                        }
                        .disabled(newAddress.isEmpty)
                        .foregroundColor(newAddress.isEmpty ? .secondary : .blue)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    Section(header: Text("Network")) {
                        Picker("Network", selection: $selectedNetwork) {
                            ForEach(NetworkConfig.allNetworks, id: \.self) { network in
                                HStack {
                                    Image(systemName: network.iconName)
                                        .foregroundColor(Color(network.accentColor))
                                    Text(network.displayName)
                                }
                                .tag(network)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedNetwork) { _, newValue in
                            NetworkConfig.setCurrentNetwork(newValue)
                            NetworkConfig.notifyNetworkChanged()
                        }
                    }
                    
                    Section(header: Text("Payment Settings")) {
                        Toggle("Use Paymaster", isOn: $usePaymaster)
                            .padding(.vertical, 4)
                        
                        if !usePaymaster {
                            TextField("Private Key", text: $privateKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.asciiCapable)
                                .padding(.vertical, 4)
                        }
                    }
                    
                    Section(header: Text("Verification")) {
                        Button(kycText) {
                            kycText = "Coming Soon"
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Settings")
        }
        .alert("Invalid Address Format", isPresented: $showAddressFormatAlert) {
            Button("OK") {
                // Clear input field, let user re-enter
                newAddress = ""
            }
        } message: {
            Text(AddressValidator.getAddressFormatError())
        }
    }
}

=== Usage in ContentView ===

import SwiftUI

struct ContentView: View {
    @State private var scannedCode: String?
    @State private var presentScanner = false
    @State private var amount: String = ""
    @State private var selectedCurrency: String = ""
    @State private var presentAmountSetter = false
    @State private var showTransactionModal = false
    @State private var showQRFormatError = false
    @StateObject private var transactionsData = TransactionsData()

    var body: some View {
        TabView {
            // Payment Tab
            PaymentTabView(
                amount: $amount,
                selectedCurrency: $selectedCurrency,
                presentAmountSetter: $presentAmountSetter,
                presentScanner: $presentScanner
            )
            .tabItem {
                Image(systemName: "cart")
                Text("Checkout")
            }
            
            // Transactions Tab
            TransactionsTabView()
                .environmentObject(transactionsData)
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("Transactions")
                }
            
            // Settings Tab
            SettingsTabView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .fullScreenCover(isPresented: $presentScanner) {
            QRCodeScannerView(scannedCode: $scannedCode, isPresented: $presentScanner)
        }
        .sheet(isPresented: $presentAmountSetter) {
            AmountSetterView(amount: $amount, selectedCurrency: $selectedCurrency, isPresented: $presentAmountSetter)
        }
        .overlay {
            if showTransactionModal {
                TransactionStatusModal(isPresented: $showTransactionModal)
            }
        }
        .onChange(of: scannedCode) { oldValue, newValue in
            guard let raw = newValue else { return }

            guard let parsed = QRCodeParser.parseQRCode(raw) else {
                // QR code format is incorrect, show error dialog
                showQRFormatError = true
                return
            }

            // Show transaction modal
            showTransactionModal = true
            
            // Store pending transaction data for when we get a hash
            transactionsData.setPendingTransaction(
                qrContent: raw,
                amount: amount.isEmpty ? "0" : amount,
                currency: selectedCurrency
            )
            
            let payeeAddress = UserDefaults.standard.string(forKey: "receivingAddress") ?? ""
            PaymentService.shared.createPaymentRequest(
                payerAddress: parsed.addr,
                otp: parsed.otp,
                payeeAddress: payeeAddress,
                amount: amount.isEmpty ? "0" : amount,
                currency: selectedCurrency,
                network: NetworkConfig.currentNetwork.rawValue
            )
        }
        .alert("Invalid QR Code Format", isPresented: $showQRFormatError) {
            Button("OK") {
                // Clear scan result, user can scan again
                scannedCode = nil
            }
        } message: {
            Text("The QR code format is incorrect.\n\n\(QRCodeParser.getQRCodeFormatDescription())")
        }
        .onAppear {
            initializeCurrency()
        }
        .onReceive(NotificationCenter.default.publisher(for: .networkChanged)) { _ in
            updateCurrencyForNetwork()
        }
    }
    
    private func initializeCurrency() {
        if selectedCurrency.isEmpty || !NetworkConfig.isCurrencySupported(selectedCurrency) {
            selectedCurrency = NetworkConfig.currentDefaultCurrency
        }
    }
    
    private func updateCurrencyForNetwork() {
        selectedCurrency = NetworkConfig.getValidCurrency(selectedCurrency)
    }
}

=== Usage in OnboardingView ===

import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingCompleted: Bool
    @State private var receivingAddress: String = ""
    @State private var selectedNetwork = NetworkConfig.NetworkType.ethSepolia
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
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    Text("TinyPay")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Start your business with \nWorld wide Crypto fervor")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 80)
                
                // Input area
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Network")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("Network", selection: $selectedNetwork) {
                            ForEach(NetworkConfig.allNetworks, id: \.self) { network in
                                HStack {
                                    Image(systemName: network.iconName)
                                        .foregroundColor(Color(network.accentColor))
                                    Text(network.displayName)
                                }
                                .tag(network)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Receiving Address")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Enter your wallet address to receive payments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        AddressInputField(text: $receivingAddress, showError: $showError)
                    }
                    
                    if showError {
                        Text("Please enter a valid wallet address")
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
            Text(AddressValidator.getAddressFormatError())
        }
    }
    
    private func processStartButton() {
        // Prevent duplicate clicks
        guard !isProcessing else { return }
        
        isProcessing = true
        
        // Handle validation in background thread, UI updates on main thread
        Task {
            let isValid = AddressValidator.isValidWalletAddress(receivingAddress)
            
            await MainActor.run {
                defer { isProcessing = false }
                
                if isValid {
                    // Save address and network to local storage
                    UserDefaults.standard.set(receivingAddress, forKey: "receivingAddress")
                    NetworkConfig.setCurrentNetwork(selectedNetwork)
                    UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
                    
                    isOnboardingCompleted = true
                } else {
                    showAddressFormatAlert = true
                }
            }
        }
    }
}

*/