import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @State private var receivingAddress: String = ""
    @State private var usePaymaster: Bool = true
    @State private var privateKey: String = ""
    @State private var kycText: String = "Enable KYC"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Settings标题和当前收款地址显示区域 - 统一色块
                VStack(spacing: 12) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
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
                    
                // 设置选项列表
                Form {
                    Section(header: Text("Change Address")) {
                        TextField("Enter wallet address", text: $receivingAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                
                    Section(header: Text("Payment Settings")) {
                        Toggle("Use Paymaster", isOn: $usePaymaster)
                        
                        if !usePaymaster {
                            TextField("Private Key", text: $privateKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.asciiCapable)
                        }
                    }
                    
                    Section(header: Text("Verification")) {
                        Button(kycText) {
                            kycText = "Coming Soon"
                        }
                        .foregroundColor(.blue)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarHidden(true)
            .overlay(
                // 顶部导航按钮
                VStack {
                    HStack {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .foregroundColor(.blue)
                        .padding(.leading)
                        
                        Spacer()
                        
                        Button("Save") {
                            // 保存设置逻辑
                            print("💾 Settings saved:")
                            print("  - Receiving Address: \(receivingAddress)")
                            print("  - Use Paymaster: \(usePaymaster)")
                            if !usePaymaster {
                                print("  - Private Key: \(privateKey.isEmpty ? "Not set" : "Set")")
                            }
                            isPresented = false
                        }
                        .foregroundColor(.blue)
                        .padding(.trailing)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
            )
        }
    }
}
