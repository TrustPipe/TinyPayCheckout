import Foundation

// 网络配置管理器
struct NetworkConfig {
    
    // 支持的网络类型
    enum NetworkType: String, CaseIterable {
        case ethSepolia = "eth-sepolia"
        case aptosTestnet = "aptos-testnet"
        
        // 网络显示名称
        var displayName: String {
            switch self {
            case .ethSepolia:
                return "Ethereum Sepolia"
            case .aptosTestnet:
                return "Aptos Testnet"
            }
        }
        
        // 支持的币种
        var supportedCurrencies: [String] {
            switch self {
            case .ethSepolia:
                return ["ETH", "USDT", "USDC"]
            case .aptosTestnet:
                return ["APT", "USDT", "USDC"]
            }
        }
        
        // 默认币种
        var defaultCurrency: String {
            switch self {
            case .ethSepolia:
                return "ETH"
            case .aptosTestnet:
                return "APT"
            }
        }
        
        // 网络图标
        var iconName: String {
            switch self {
            case .ethSepolia:
                return "hexagon"
            case .aptosTestnet:
                return "diamond"
            }
        }
        
        // 网络颜色
        var accentColor: String {
            switch self {
            case .ethSepolia:
                return "blue"
            case .aptosTestnet:
                return "green"
            }
        }
        
        // 区块链浏览器URL前缀
        var explorerURL: String {
            switch self {
            case .ethSepolia:
                return "https://sepolia.etherscan.io/tx/"
            case .aptosTestnet:
                return "https://explorer.aptoslabs.com/txn/"
            }
        }
    }
    
    // 获取当前选择的网络
    static var currentNetwork: NetworkType {
        let networkString = UserDefaults.standard.string(forKey: "selectedNetwork") ?? NetworkType.ethSepolia.rawValue
        return NetworkType(rawValue: networkString) ?? .ethSepolia
    }
    
    // 设置当前网络
    static func setCurrentNetwork(_ network: NetworkType) {
        UserDefaults.standard.set(network.rawValue, forKey: "selectedNetwork")
    }
    
    // 获取当前网络支持的币种
    static var currentSupportedCurrencies: [String] {
        return currentNetwork.supportedCurrencies
    }
    
    // 获取当前网络的默认币种
    static var currentDefaultCurrency: String {
        return currentNetwork.defaultCurrency
    }
    
    // 验证币种是否在当前网络中受支持
    static func isCurrencySupported(_ currency: String) -> Bool {
        return currentSupportedCurrencies.contains(currency)
    }
    
    // 获取有效的币种选择（如果当前币种不支持，返回默认币种）
    static func getValidCurrency(_ currency: String) -> String {
        return isCurrencySupported(currency) ? currency : currentDefaultCurrency
    }
    
    // 获取所有可用的网络列表
    static var allNetworks: [NetworkType] {
        return NetworkType.allCases
    }
    
    // 获取网络显示名称列表
    static var networkDisplayNames: [String] {
        return allNetworks.map { $0.displayName }
    }
    
    // 获取网络原始值列表（用于API调用）
    static var networkRawValues: [String] {
        return allNetworks.map { $0.rawValue }
    }
    
    // 通过显示名称获取网络类型
    static func networkType(from displayName: String) -> NetworkType? {
        return allNetworks.first { $0.displayName == displayName }
    }
    
    // 获取区块链浏览器完整URL
    static func getExplorerURL(for transactionHash: String) -> String {
        return currentNetwork.explorerURL + transactionHash
    }
    
    // 网络切换时的回调通知
    static func notifyNetworkChanged() {
        NotificationCenter.default.post(name: .networkChanged, object: nil)
    }
}

// 自定义通知名称
extension Notification.Name {
    static let networkChanged = Notification.Name("NetworkChanged")
}