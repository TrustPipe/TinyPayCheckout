import Foundation

class AddressValidator {
    static func isValidWalletAddress(_ address: String) -> Bool {
        // 检查地址格式：0x开头 + 64位十六进制字符
        let pattern = "^0x[0-9a-fA-F]{64}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: address.count)
        return regex?.firstMatch(in: address, options: [], range: range) != nil
    }
    
    static func getAddressFormatError() -> String {
        return "Address must start with '0x' followed by exactly 64 hexadecimal characters."
    }
    
    static func getAddressExample() -> String {
        return "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    }
}
