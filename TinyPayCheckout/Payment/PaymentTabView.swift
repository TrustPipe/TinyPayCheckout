import SwiftUI

struct PaymentTabView: View {
    @Binding var amount: String
    @Binding var selectedCurrency: String
    @Binding var presentAmountSetter: Bool
    @Binding var presentScanner: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Checkout title and billing amount display area - unified color block
                VStack(spacing: 12) {
                    Text("The total biil is")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if !amount.isEmpty {
                        Text("\(amount) \(selectedCurrency)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    } else {
                        Text("No Amount Set")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    
                    Text("Tap buttons below to modify or proceed with payment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                
                // Action button list
                Form {
                    Section(header: Text("Bill Settings")) {
                        Button("Modify Bill Amount") {
                            presentAmountSetter = true
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    Section(header: Text("Payment Processing")) {
                        Button("Scan QR Code") {
                            presentScanner = true
                        }
                        .foregroundColor(.green)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Checkout")
        }
    }
}
