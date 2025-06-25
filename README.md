# Helix 🧬

**Generative Art Breeding Platform on Stacks**

Helix enables users to "breed" generative art NFTs by combining traits from different pieces, creating unique offspring that inherit characteristics from their parents while ensuring creators receive royalties from the lineage.

## Features

- **Art Breeding**: Combine two NFTs to create unique offspring with inherited traits
- **Generational Tracking**: Each NFT tracks its generation and lineage
- **Creator Royalties**: Original creators earn royalties when their art is used in breeding
- **Trait Inheritance**: Offspring inherit and blend characteristics from parent NFTs
- **Breeding Permissions**: Flexible permission system for breeding operations

## Smart Contract Overview

The Helix smart contract is built using Clarity for the Stacks blockchain and includes:

- **Genesis Minting**: Create generation 0 NFTs with unique traits
- **Breeding Mechanism**: Combine two NFTs to produce offspring
- **Royalty Distribution**: Automatic royalty payments to parent creators
- **Ownership Tracking**: Full lineage and ownership history
- **Admin Controls**: Configurable breeding fees and royalty rates

## Contract Functions

### Public Functions

- `mint-genesis(traits, to)` - Mint a generation 0 NFT (admin only)
- `breed-nfts(parent-a-id, parent-b-id, offspring-traits)` - Breed two NFTs
- `transfer(token-id, sender, recipient)` - Transfer NFT ownership
- `set-breeding-permission(breeder, permission)` - Grant breeding permissions (admin)
- `withdraw-royalties()` - Withdraw accumulated creator royalties

### Read-Only Functions

- `get-token-info(token-id)` - Get complete token metadata
- `get-lineage(token-id)` - Get parent information and generation
- `get-creator-royalties(creator)` - Check royalty balance
- `get-contract-stats()` - Get platform statistics

## Getting Started

### Prerequisites

- Stacks CLI or Clarinet for contract deployment
- STX tokens for breeding fees
- Compatible wallet (Hiro, Xverse, etc.)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/helix.git
cd helix
```

2. Install Clarinet (if not already installed):
```bash
curl -L https://github.com/hirosystems/clarinet/releases/download/v1.0.0/clarinet-linux-x64.tar.gz | tar xz
```

3. Deploy the contract:
```bash
clarinet deploy --testnet
```

### Usage Example

```clarity
;; Mint a genesis NFT (admin only)
(contract-call? .helix mint-genesis "traits:color=blue,style=geometric" 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)

;; Breed two NFTs
(contract-call? .helix breed-nfts u1 u2 "traits:color=purple,style=hybrid")

;; Check token lineage
(contract-call? .helix get-lineage u3)
```

## Economic Model

- **Breeding Fee**: 1 STX per breeding operation (configurable)
- **Creator Royalties**: 2.5% of breeding fees distributed to parent creators
- **Generation Tracking**: Each generation is tracked for rarity and value assessment

## Contract Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| Breeding Fee | 1 STX | Cost to breed two NFTs |
| Royalty Rate | 2.5% | Percentage of breeding fee paid to creators |
| Max Royalty | 10% | Maximum allowed royalty percentage |

## Roadmap

- [ ] Web3 frontend interface
- [ ] Advanced trait mixing algorithms
- [ ] Rarity scoring system
- [ ] Marketplace integration
- [ ] Cross-chain breeding support

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Security

This contract has been designed with security best practices:

- Owner-only administrative functions
- Input validation on all public functions
- Proper error handling and assertions
- Safe arithmetic operations

