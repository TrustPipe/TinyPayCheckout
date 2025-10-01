import Foundation

// Network configuration manager
struct NetworkConfig {
    
    // Supported network types
    enum NetworkType: String, CaseIterable {
        case ethSepolia = "eth-sepolia"
        case aptosTestnet = "aptos-testnet"
        
        // Network display name
        var displayName: String {
            switch self {
            case .ethSepolia:
                return "Ethereum Sepolia"
            case .aptosTestnet:
                return "Aptos Testnet"
            }
        }
        
        // Supported currencies
        var supportedCurrencies: [String] {
            switch self {
            case .ethSepolia:
                return ["ETH", "USDT", "USDC"]
            case .aptosTestnet:
                return ["APT", "USDT", "USDC"]
            }
        }
        
        // Default currency
        var defaultCurrency: String {
            switch self {
            case .ethSepolia:
                return "ETH"
            case .aptosTestnet:
                return "APT"
            }
        }
        
        // Network icon
        var iconName: String {
            switch self {
            case .ethSepolia:
                return "hexagon"
            case .aptosTestnet:
                return "diamond"
            }
        }
        
        // Network color
        var accentColor: String {
            switch self {
            case .ethSepolia:
                return "blue"
            case .aptosTestnet:
                return "green"
            }
        }
        
        // Blockchain explorer URL prefix
        var explorerURL: String {
            switch self {
            case .ethSepolia:
                return "https://sepolia.etherscan.io/tx/"
            case .aptosTestnet:
                return "https://explorer.aptoslabs.com/txn/"
            }
        }
    }
    
    // Get currently selected network
    static var currentNetwork: NetworkType {
        let networkString = UserDefaults.standard.string(forKey: "selectedNetwork") ?? NetworkType.ethSepolia.rawValue
        return NetworkType(rawValue: networkString) ?? .ethSepolia
    }
    
    // Set current network
    static func setCurrentNetwork(_ network: NetworkType) {
        UserDefaults.standard.set(network.rawValue, forKey: "selectedNetwork")
    }
    
    // Get current network supported currencies
    static var currentSupportedCurrencies: [String] {
        return currentNetwork.supportedCurrencies
    }
    
    // Get current network default currency
    static var currentDefaultCurrency: String {
        return currentNetwork.defaultCurrency
    }
    
    // Validate if currency is supported in current network
    static func isCurrencySupported(_ currency: String) -> Bool {
        return currentSupportedCurrencies.contains(currency)
    }
    
    // Get valid currency selection (return default currency if current currency is not supported)
    static func getValidCurrency(_ currency: String) -> String {
        return isCurrencySupported(currency) ? currency : currentDefaultCurrency
    }
    
    // Get all available networks list
    static var allNetworks: [NetworkType] {
        return NetworkType.allCases
    }
    
    // Get network display names list
    static var networkDisplayNames: [String] {
        return allNetworks.map { $0.displayName }
    }
    
    // Get network raw values list (for API calls)
    static var networkRawValues: [String] {
        return allNetworks.map { $0.rawValue }
    }
    
    // Get network type through display name
    static func networkType(from displayName: String) -> NetworkType? {
        return allNetworks.first { $0.displayName == displayName }
    }
    
    // Get blockchain explorer complete URL
    static func getExplorerURL(for transactionHash: String) -> String {
        return currentNetwork.explorerURL + transactionHash
    }
    
    // Get decimal places for currency
    static func getDecimalPlaces(for currency: String) -> Int {
        switch currency {
        case "ETH":
            return 18  // 1 ETH = 10^18 wei
        case "APT":
            return 8   // 1 APT = 10^8 octas
        case "USDT", "USDC":
            return 6   // Assume all are 8 decimal places
        default:
            return 8
        }
    }
    
    // Convert user input to smallest unit
    static func convertToSmallestUnit(_ amount: String, currency: String) -> Int {
        guard let value = Double(amount) else { return 0 }
        let decimals = getDecimalPlaces(for: currency)
        return Int(value * pow(10.0, Double(decimals)))
    }
    
    // Convert smallest unit to user-friendly display
    static func convertFromSmallestUnit(_ amount: String, currency: String) -> Double {
        guard let value = Double(amount) else { return 0.0 }
        let decimals = getDecimalPlaces(for: currency)
        return value / pow(10.0, Double(decimals))
    }
    
    // Callback notification when network switches
    static func notifyNetworkChanged() {
        NotificationCenter.default.post(name: .networkChanged, object: nil)
    }
}

// Custom notification name
extension Notification.Name {
    static let networkChanged = Notification.Name("NetworkChanged")
}