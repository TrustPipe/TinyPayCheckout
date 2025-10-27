# TinyPay Checkout

A SwiftUI-based iOS payment application for receiving cryptocurrency payments on Solana blockchain.

## Overview

This is a merchant payment application that allows businesses to receive cryptocurrency payments on Solana network by scanning customer payment QR codes. Currently supports SOL, USDT, and USDC tokens.

## Features

- Scan QR codes to receive payments
- Support for SOL, USDT, and USDC tokens
- Set payment amount and currency
- View transaction history
- Configure receiving address
- View transaction status and blockchain explorer links

## Project Structure

```
TinyPayCheckout/
├── TinyPayCheckoutApp.swift          # App entry point
├── ContentView.swift                  # Main content view with tabs
├── AmountSetter/
│   └── AmountSetterView.swift        # Amount input interface
├── Network/
│   └── PaymentService.swift          # API communication layer
├── Onboarding/
│   └── OnboardingView.swift          # First-time user setup
├── Payment/
│   ├── PaymentTabView.swift          # Payment checkout UI
│   └── TransactionStatusModal.swift  # Transaction status overlay
├── QRCodeNative/
│   ├── QRCodeParser.swift            # QR code validation
│   └── QRCodeScannerView.swift       # Camera QR scanner
├── Settings/
│   └── SettingsTabView.swift         # App settings
├── Transactions/
│   ├── TransactionsData.swift        # Transaction data model
│   └── TransactionsTabView.swift     # Transaction history UI
└── Utils/
    ├── AddressValidator.swift         # Wallet address validation
    ├── NetworkConfig.swift            # Network configuration
    └── NetworkConfig_Usage_Examples.swift
```

## Requirements

- Xcode 15.0+
- iOS 17.0+
- macOS Sonoma or later

## Installation

1. Clone the repository
   ```bash
   git clone https://github.com/TrustPipe/TinyPayCheckout.git
   cd TinyPayCheckout
   ```

2. Open the project
   ```bash
   open TinyPayCheckout.xcodeproj
   ```

3. Select target device in Xcode and press `⌘ + R` to run

## Usage

### Initial Setup

1. Launch the app and enter your Solana receiving address (44-character base58 format) on the onboarding screen
2. Start using the app after address validation passes

### Payment Flow

1. Tap "Set Amount" to set payment amount and currency
2. Tap "Scan QR Code" to scan customer's payment QR code
3. App automatically processes the payment request
4. View processing status in the transaction status modal
5. Transaction is automatically saved to history after completion

### QR Code Format

Expected QR code format:

```
addr:[44-character base58 Solana address]
otp:0x[64-character hex OTP]
```

Example:
```
addr:6eQDtnQ7qX3Tiwqzuz8uKZHBHWKzxs3KPScMbY1DM4i6
otp:0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
```

## Configuration

### Network Configuration

Configured for Solana Devnet by default. Settings in `NetworkConfig.swift`:

- Network: Solana Devnet
- Supported Currencies: SOL, USDT, USDC
- Default Currency: SOL
- Block Explorer: https://explorer.solana.com/tx/

### API Configuration

Modify API endpoint in `PaymentService.swift`:

```swift
private let baseURL = "https://api-tinypay.predictplay.xyz"
```

### Token Decimals

- SOL: 9 decimals (lamports)
- USDT/USDC: 6 decimals

## API Endpoints

### Create Payment

```
POST /api/payments
```

Request body:
```json
{
  "payer_addr": "string",
  "otp": "string",
  "payee_addr": "string",
  "amount": 0,
  "currency": "string",
  "network": "solana-devnet"
}
```

### Query Transaction Status

```
GET /api/payments/{transaction_hash}?network=solana-devnet
```

### Response Codes

- `1001` - Payment created successfully (returns transaction hash)
- `1002` - Transaction pending
- `1003` - Transaction confirmed
- `2000` - Amount must be greater than 0
- `2001` - Over limit
- `2002` - Insufficient balance
- `2003` - Incorrect OTP
- `2004` - Missing field
- `2005` - Transaction does not exist

## Transaction Flow

```
Scan QR Code → Validate Format → Create Payment Request → Get Transaction Hash → Poll Status (5 times, 1s interval) → Success/Failed/Pending
```

## Tech Stack

- SwiftUI - UI framework
- AVFoundation - QR code scanning
- UserDefaults - Local data storage
- URLSession - Network requests

## Security

- All wallet addresses are validated for correct format
- Strict QR code format matching required
- OTP verified server-side
- App never handles or stores private keys

## Disclaimer

This application is for testing on Solana Devnet only. Thoroughly test before using with real funds on mainnet.
