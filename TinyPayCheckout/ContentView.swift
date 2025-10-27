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
            let convertedAmount = NetworkConfig.convertToSmallestUnit(amount.isEmpty ? "0" : amount, currency: selectedCurrency)
            PaymentService.shared.createPaymentRequest(
                payerAddress: parsed.addr,
                otp: parsed.otp,
                payeeAddress: payeeAddress,
                amount: String(convertedAmount),
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

#Preview {
    ContentView()
}
