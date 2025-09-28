//
//  ContentView.swift
//  TinyPayCheckout
//
//  Created by Harold on 2025/9/18.
//

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
                // QR码格式不正确，显示错误弹窗
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
            let selectedNetwork = UserDefaults.standard.string(forKey: "selectedNetwork") ?? "eth-sepolia"
            PaymentService.shared.createPaymentRequest(
                payerAddress: parsed.addr,
                otp: parsed.otp,
                payeeAddress: payeeAddress,
                amount: amount.isEmpty ? "0" : amount,
                currency: selectedCurrency,
                network: selectedNetwork
            )
        }
        .alert("Invalid QR Code Format", isPresented: $showQRFormatError) {
            Button("OK") {
                // 清空扫描结果，用户可以重新扫描
                scannedCode = nil
            }
        } message: {
            Text("The QR code format is incorrect.\n\n\(QRCodeParser.getQRCodeFormatDescription())")
        }
        .onAppear {
            initializeCurrency()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            updateCurrencyForNetwork()
        }
    }
    
    private func initializeCurrency() {
        if selectedCurrency.isEmpty {
            let network = UserDefaults.standard.string(forKey: "selectedNetwork") ?? "eth-sepolia"
            selectedCurrency = network == "aptos-testnet" ? "APT" : "ETH"
        }
    }
    
    private func updateCurrencyForNetwork() {
        let network = UserDefaults.standard.string(forKey: "selectedNetwork") ?? "eth-sepolia"
        let currencies = network == "aptos-testnet" ? ["APT", "USDT", "USDC"] : ["ETH", "USDT", "USDC"]
        
        if !currencies.contains(selectedCurrency) {
            selectedCurrency = network == "aptos-testnet" ? "APT" : "ETH"
        }
    }
}

#Preview {
    ContentView()
}
