import SwiftUI

struct AmountSetterView: View {
    @Binding var amount: String
    @Binding var selectedCurrency: String
    @Binding var isPresented: Bool
    
    @State private var selectedNetwork: String = UserDefaults.standard.string(forKey: "selectedNetwork") ?? "eth-sepolia"
    
    private var currencies: [String] {
        switch selectedNetwork {
        case "aptos-testnet":
            return ["APT", "USDT", "USDC"]
        case "eth-sepolia":
            return ["ETH", "USDT", "USDC"]
        default:
            return ["ETH", "USDT", "USDC"]
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Set Charge Amount")
                    .font(.title2)
                    .fontWeight(.semibold)
                
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
                    Text("The total biil is \(amount) \(selectedCurrency)")
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
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                let newNetwork = UserDefaults.standard.string(forKey: "selectedNetwork") ?? "eth-sepolia"
                if newNetwork != selectedNetwork {
                    selectedNetwork = newNetwork
                    updateCurrencySelection()
                }
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
        let defaultCurrency = selectedNetwork == "aptos-testnet" ? "APT" : "ETH"
        if !currencies.contains(selectedCurrency) {
            selectedCurrency = defaultCurrency
        }
    }
}
