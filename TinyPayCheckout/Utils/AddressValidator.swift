import Foundation

class AddressValidator {
    // Cache for compiled regex patterns
    private static var regexCache: [String: NSRegularExpression] = [:]
    
    // Get or create regex for a network
    private static func getRegex(for network: NetworkConfig.NetworkType) -> NSRegularExpression? {
        let pattern = network.addressRegexPattern
        
        if let cachedRegex = regexCache[pattern] {
            return cachedRegex
        }
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        regexCache[pattern] = regex
        return regex
    }
    
    static func isValidWalletAddress(_ address: String) -> Bool {
        return isValidWalletAddress(address, for: NetworkConfig.currentNetwork)
    }
    
    static func isValidWalletAddress(_ address: String, for network: NetworkConfig.NetworkType) -> Bool {
        guard let regex = getRegex(for: network) else { return false }
        let range = NSRange(location: 0, length: address.count)
        return regex.firstMatch(in: address, options: [], range: range) != nil
    }
    
    static func getAddressFormatError() -> String {
        return getAddressFormatError(for: NetworkConfig.currentNetwork)
    }
    
    static func getAddressFormatError(for network: NetworkConfig.NetworkType) -> String {
        return network.addressFormatError
    }
    
    static func getAddressExample() -> String {
        return getAddressExample(for: NetworkConfig.currentNetwork)
    }
    
    static func getAddressExample(for network: NetworkConfig.NetworkType) -> String {
        return network.addressExample
    }
}
