import Foundation

class AddressValidator {
    // 以太坊地址正则表达式
    private static let ethAddressRegex: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "^0x[0-9a-fA-F]{40}$")
    }()
    
    // Aptos地址正则表达式
    private static let aptosAddressRegex: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "^0x[0-9a-fA-F]{64}$")
    }()
    
    static func isValidWalletAddress(_ address: String) -> Bool {
        return isValidWalletAddress(address, for: NetworkConfig.currentNetwork)
    }
    
    static func isValidWalletAddress(_ address: String, for network: NetworkConfig.NetworkType) -> Bool {
        let regex: NSRegularExpression?
        
        switch network {
        case .ethSepolia:
            regex = ethAddressRegex
        case .aptosTestnet:
            regex = aptosAddressRegex
        }
        
        guard let validRegex = regex else { return false }
        let range = NSRange(location: 0, length: address.count)
        return validRegex.firstMatch(in: address, options: [], range: range) != nil
    }
    
    static func getAddressFormatError() -> String {
        return getAddressFormatError(for: NetworkConfig.currentNetwork)
    }
    
    static func getAddressFormatError(for network: NetworkConfig.NetworkType) -> String {
        switch network {
        case .ethSepolia:
            return "Address must start with '0x' followed by exactly 40 hexadecimal characters."
        case .aptosTestnet:
            return "Address must start with '0x' followed by exactly 64 hexadecimal characters."
        }
    }
    
    static func getAddressExample() -> String {
        return getAddressExample(for: NetworkConfig.currentNetwork)
    }
    
    static func getAddressExample(for network: NetworkConfig.NetworkType) -> String {
        switch network {
        case .ethSepolia:
            return "0x1234567890abcdef1234567890abcdef12345678"
        case .aptosTestnet:
            return "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        }
    }
}
