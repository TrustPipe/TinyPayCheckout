import Foundation

class AddressValidator {
    // 缓存正则表达式，避免重复创建
    private static let addressRegex: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "^0x[0-9a-fA-F]{64}$")
    }()
    
    // 缓存示例地址，避免重复创建字符串
    private static let cachedAddressExample = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    
    static func isValidWalletAddress(_ address: String) -> Bool {
        // 使用缓存的正则表达式
        guard let regex = addressRegex else { return false }
        let range = NSRange(location: 0, length: address.count)
        return regex.firstMatch(in: address, options: [], range: range) != nil
    }
    
    static func getAddressFormatError() -> String {
        return "Address must start with '0x' followed by exactly 64 hexadecimal characters."
    }
    
    static func getAddressExample() -> String {
        return cachedAddressExample
    }
}
