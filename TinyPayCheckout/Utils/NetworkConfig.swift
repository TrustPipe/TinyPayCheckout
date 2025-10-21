import Foundation

// Network configuration manager
struct NetworkConfig {
    
    // Supported network types
    enum NetworkType: String, CaseIterable {
        case ethSepolia = "eth-sepolia"
        case aptosTestnet = "aptos-testnet"
        case celoSepolia = "celo-sepolia"
        case u2uMainnet = "u2u-mainnet"
        case solanaDevnet = "solana-devnet"
        
        // Network display name
        var displayName: String {
            switch self {
            case .ethSepolia:
                return "Ethereum Sepolia"
            case .aptosTestnet:
                return "Aptos Testnet"
            case .celoSepolia:
                return "Celo Sepolia"
            case .u2uMainnet:
                return "U2U Network"
            case .solanaDevnet:
                return "Solana Devnet"
            }
        }
        
        // Supported currencies
        var supportedCurrencies: [String] {
            switch self {
            case .ethSepolia:
                return ["ETH", "USDT", "USDC"]
            case .aptosTestnet:
                return ["APT", "USDT", "USDC"]
            case .celoSepolia:
                return ["CELO", "USDT", "USDC"]
            case .u2uMainnet:
                return ["U2U", "USDT", "USDC"]
            case .solanaDevnet:
                return ["SOL", "USDT", "USDC"]
            }
        }
        
        // Default currency
        var defaultCurrency: String {
            switch self {
            case .ethSepolia:
                return "ETH"
            case .aptosTestnet:
                return "APT"
            case .celoSepolia:
                return "CELO"
            case .u2uMainnet:
                return "U2U"
            case .solanaDevnet:
                return "SOL"
            }
        }
        
        // Network icon
        var iconName: String {
            switch self {
            case .ethSepolia:
                return "hexagon"
            case .aptosTestnet:
                return "diamond"
            case .celoSepolia:
                return "circle"
            case .u2uMainnet:
                return "square"
            case .solanaDevnet:
                return "star"
            }
        }
        
        // Network color
        var accentColor: String {
            switch self {
            case .ethSepolia:
                return "blue"
            case .aptosTestnet:
                return "green"
            case .celoSepolia:
                return "yellow"
            case .u2uMainnet:
                return "purple"
            case .solanaDevnet:
                return "orange"
            }
        }
        
        // Blockchain explorer URL prefix
        var explorerURL: String {
            switch self {
            case .ethSepolia:
                return "https://sepolia.etherscan.io/tx/"
            case .aptosTestnet:
                return "https://explorer.aptoslabs.com/txn/"
            case .celoSepolia:
                return "https://celo-sepolia.blockscout.com/txs/"
            case .u2uMainnet:
                return "https://u2uscan.xyz/tx/"
            case .solanaDevnet:
                return "https://explorer.solana.com/tx/"
            }
        }
        
        // Address length (hex digits after 0x)
        var addressLength: Int {
            switch self {
            case .ethSepolia, .celoSepolia, .u2uMainnet:
                return 40  // EVM-compatible chains use 40-char addresses
            case .aptosTestnet:
                return 64  // Aptos uses 64-char addresses
            case .solanaDevnet:
                return 44  // Solana uses 44-char base58 addresses
            }
        }
        
        // Address validation regex pattern
        var addressRegexPattern: String {
            switch self {
            case .ethSepolia, .celoSepolia, .u2uMainnet, .aptosTestnet:
                return "^0x[0-9a-fA-F]{\(addressLength)}$"
            case .solanaDevnet:
                return "^[1-9A-HJ-NP-Za-km-z]{\(addressLength)}$"  // Base58 pattern
            }
        }
        
        // Address format error message
        var addressFormatError: String {
            switch self {
            case .ethSepolia, .celoSepolia, .u2uMainnet, .aptosTestnet:
                return "Address must start with '0x' followed by exactly \(addressLength) hexadecimal characters."
            case .solanaDevnet:
                return "Address must be exactly \(addressLength) base58 characters (no '0x' prefix)."
            }
        }
        
        // Address example
        var addressExample: String {
            switch self {
            case .ethSepolia, .celoSepolia, .u2uMainnet:
                return "0x1234567890abcdef1234567890abcdef12345678"
            case .aptosTestnet:
                return "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            case .solanaDevnet:
                return "6eQDtnQ7qX3Tiwqzuz8uKZHBHWKzxs3KPScMbY1DM4i6"
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
        case "CELO":
            return 18  // 1 CELO = 10^18 wei
        case "U2U":
            return 18  // 1 U2U = 10^18 wei
        case "APT":
            return 8   // 1 APT = 10^8 octas
        case "SOL":
            return 9   // 1 SOL = 10^9 lamports
        case "USDT", "USDC":
            return 6   // 1 USDT/USDC = 10^6 micro units
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
    
    // MARK: - QR Code Parsing
    
    // Generate QR code regex pattern based on network type
    private static func getQRCodePattern(for network: NetworkType) -> String {
        let addressLength = network.addressLength
        // OTP is always 64-bit hex with 0x prefix
        
        switch network {
        case .solanaDevnet:
            // Solana addresses are base58 without 0x prefix
            return #"^addr:([1-9A-HJ-NP-Za-km-z]{\#(addressLength)})[\s\r\n]+otp:(0x[0-9a-fA-F]{64})$"#
        default:
            // Other networks use 0x prefix for addresses
            return #"^addr:(0x[0-9a-fA-F]{\#(addressLength)})[\s\r\n]+otp:(0x[0-9a-fA-F]{64})$"#
        }
    }
    
    // Get QR code format description for current network
    static func getQRCodeFormatDescription() -> String {
        return getQRCodeFormatDescription(for: currentNetwork)
    }
    
    // Get QR code format description for specific network
    static func getQRCodeFormatDescription(for network: NetworkType) -> String {
        let addressLength = network.addressLength
        switch network {
        case .solanaDevnet:
            return "Expected QR code format for \(network.displayName):\naddr:[\(addressLength)-char base58]\n[whitespace or newline]\notp:0x[64-digit hex]"
        default:
            return "Expected QR code format for \(network.displayName):\naddr:0x[\(addressLength)-digit hex]\n[whitespace or newline]\notp:0x[64-digit hex]"
        }
    }
    
    // Parse QR code for current network
    static func parseQRCode(_ text: String) -> (addr: String, otp: String)? {
        return parseQRCode(text, for: currentNetwork)
    }
    
    // Parse QR code for specific network
    static func parseQRCode(_ text: String, for network: NetworkType) -> (addr: String, otp: String)? {
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
        let addrString = ns.substring(with: match.range(at: 1))
        let otpString = ns.substring(with: match.range(at: 2)).lowercased()  // Only OTP should be lowercased
        
        // For non-Solana networks, convert address to lowercase for consistency
        let finalAddrString = network == .solanaDevnet ? addrString : addrString.lowercased()
        
        // Validate address format (based on network)
        guard AddressValidator.isValidWalletAddress(finalAddrString, for: network) else {
            print("❌ Invalid addr format: \(finalAddrString)")
            print("   \(AddressValidator.getAddressFormatError(for: network))")
            return nil
        }
        
        // OTP always uses 64-bit format validation (Aptos format)
        guard AddressValidator.isValidWalletAddress(otpString, for: .aptosTestnet) else {
            print("❌ Invalid otp format: \(otpString)")
            print("   OTP must be 64-digit hex: 0x[64-digit hex]")
            return nil
        }
        
        let result = (finalAddrString, otpString)
        print("✅ QRCode parsing successful: addr=\(result.0) otp=\(result.1)")
        return result
    }
}

// Custom notification name
extension Notification.Name {
    static let networkChanged = Notification.Name("NetworkChanged")
}