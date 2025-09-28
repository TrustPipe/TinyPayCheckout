import Foundation

struct QRCodeParser {
    // QR code format: addr:0x<64hex> newline or whitespace separated otp:0x<64hex>
    // Allows any whitespace characters in between (space/\n/\r/\t)
    private static let qrCodePattern = #"^addr:(0x[0-9a-fA-F]{64})[\s\r\n]+otp:(0x[0-9a-fA-F]{64})$"#
    
    static func getQRCodeFormatDescription() -> String {
        return "Expected QR code format:\naddr:0x[64-digit hex]\n[whitespace or newline]\notp:0x[64-digit hex]"
    }
    
    static func parseQRCode(_ text: String) -> (addr: String, otp: String)? {
        print("🔍 QRCode raw content: \(text)")
        
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let regex = try? NSRegularExpression(pattern: qrCodePattern, options: []) else {
            print("❌ Failed to create regex pattern")
            return nil
        }
        
        let range = NSRange(location: 0, length: (normalized as NSString).length)
        guard let match = regex.firstMatch(in: normalized, options: [], range: range), match.numberOfRanges == 3 else {
            print("❌ QRCode content doesn't match expected format: addr:0x<64hex> + whitespace + otp:0x<64hex>")
            print("   Actual content: \(normalized)")
            print("   Expected format: addr:0x[64-digit hex] [whitespace or newline] otp:0x[64-digit hex]")
            return nil
        }
        
        let ns = normalized as NSString
        let addrString = ns.substring(with: match.range(at: 1)).lowercased()
        let otpString = ns.substring(with: match.range(at: 2)).lowercased()
        
        // 使用AddressValidator验证两个地址格式
        guard AddressValidator.isValidWalletAddress(addrString) else {
            print("❌ Invalid addr format: \(addrString)")
            print("   \(AddressValidator.getAddressFormatError())")
            return nil
        }
        
        guard AddressValidator.isValidWalletAddress(otpString) else {
            print("❌ Invalid otp format: \(otpString)")
            print("   \(AddressValidator.getAddressFormatError())")
            return nil
        }
        
        let result = (addrString, otpString)
        print("✅ QRCode parsing successful: addr=\(result.0) otp=\(result.1)")
        return result
    }
}
