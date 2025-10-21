import Foundation

struct QRCodeParser {
    
    // Get QR code format description for current network
    static func getQRCodeFormatDescription() -> String {
        return NetworkConfig.getQRCodeFormatDescription()
    }
    
    // Get QR code format description for specific network
    static func getQRCodeFormatDescription(for network: NetworkConfig.NetworkType) -> String {
        return NetworkConfig.getQRCodeFormatDescription(for: network)
    }
    
    // Parse QR code for current network
    static func parseQRCode(_ text: String) -> (addr: String, otp: String)? {
        return NetworkConfig.parseQRCode(text)
    }
    
    // Parse QR code for specific network
    static func parseQRCode(_ text: String, for network: NetworkConfig.NetworkType) -> (addr: String, otp: String)? {
        return NetworkConfig.parseQRCode(text, for: network)
    }
}
