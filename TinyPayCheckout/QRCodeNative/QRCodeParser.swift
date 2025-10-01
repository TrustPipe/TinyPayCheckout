import Foundation

struct QRCodeParser {
    
    // Generate QR code regex pattern based on network type
    private static func getQRCodePattern(for network: NetworkConfig.NetworkType) -> String {
        let addressLength: Int
        switch network {
        case .ethSepolia:
            addressLength = 40
        case .aptosTestnet:
            addressLength = 64
        }
        
        // OTP is always 64-bit
        return #"^addr:(0x[0-9a-fA-F]{\#(addressLength)})[\s\r\n]+otp:(0x[0-9a-fA-F]{64})$"#
    }
    
    static func getQRCodeFormatDescription() -> String {
        return getQRCodeFormatDescription(for: NetworkConfig.currentNetwork)
    }
    
    static func getQRCodeFormatDescription(for network: NetworkConfig.NetworkType) -> String {
        let addressLength: Int
        switch network {
        case .ethSepolia:
            addressLength = 40
        case .aptosTestnet:
            addressLength = 64
        }
        
        return "Expected QR code format for \(network.displayName):\naddr:0x[\(addressLength)-digit hex]\n[whitespace or newline]\notp:0x[64-digit hex]"
    }
    
    static func parseQRCode(_ text: String) -> (addr: String, otp: String)? {
        return parseQRCode(text, for: NetworkConfig.currentNetwork)
    }
    
    static func parseQRCode(_ text: String, for network: NetworkConfig.NetworkType) -> (addr: String, otp: String)? {
        print("🔍 QRCode raw content: \(text)")
        print("🌐 Current network: \(network.displayName)")
        
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = getQRCodePattern(for: network)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            print("❌ Failed to create regex pattern for \(network.displayName)")
            return nil
        }
        
        let range = NSRange(location: 0, length: (normalized as NSString).length)
        guard let match = regex.firstMatch(in: normalized, options: [], range: range), match.numberOfRanges == 3 else {
            print("❌ QRCode content doesn't match expected format for \(network.displayName)")
            print("   Actual content: \(normalized)")
            print("   Expected format: \(getQRCodeFormatDescription(for: network))")
            return nil
        }
        
        let ns = normalized as NSString
        let addrString = ns.substring(with: match.range(at: 1)).lowercased()
        let otpString = ns.substring(with: match.range(at: 2)).lowercased()
        
        // Validate address format (based on network)
        guard AddressValidator.isValidWalletAddress(addrString, for: network) else {
            print("❌ Invalid addr format: \(addrString)")
            print("   \(AddressValidator.getAddressFormatError(for: network))")
            return nil
        }
        
        // OTP always uses 64-bit format validation (Aptos format)
        guard AddressValidator.isValidWalletAddress(otpString, for: .aptosTestnet) else {
            print("❌ Invalid otp format: \(otpString)")
            print("   OTP must be 64-digit hex: 0x[64-digit hex]")
            return nil
        }
        
        let result = (addrString, otpString)
        print("✅ QRCode parsing successful: addr=\(result.0) otp=\(result.1)")
        return result
    }
}
