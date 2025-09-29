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

                Form {
                    Section(header: Text("Change Address")) {
                        TextField(AddressValidator.getAddressExample(for: selectedNetwork), text: $newAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.asciiCapable)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.vertical, 4)

                        Button("Save") {
                            if !newAddress.isEmpty {
                                // Check Address format for selected network
                                if AddressValidator.isValidWalletAddress(newAddress, for: selectedNetwork) {
                                    receivingAddress = newAddress
                                    UserDefaults.standard.set(newAddress, forKey: "receivingAddress")
                                    newAddress = ""
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
                                Text(network.displayName).tag(network)
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
                newAddress = ""
            }
        } message: {
            Text(AddressValidator.getAddressFormatError(for: selectedNetwork))
        }
    }
}
