# SUI NFT Rental Contract

## Contracts

- List of core contracts for SUI NFT Rental

### 1. Rental Vault

- The vault acts as the main interface in which the renter and lender interacts with.

### Core Functions:

- `lend_nft` - Lends an NFT to a renter

  - The lender must approve the vault to transfer the NFT before calling this function.
  - The lender will decide on the conditions of rental - the rental period, and the rental fee.
  - The NFT will be transferred to the rental vault. The nft is being rented out by the lender it is stored in the vault until it finds a renter

  - A `RentalContract` object will be created outlining the terms of the rental.

- `rent_nft` - The renter calls this function to rent an NFT.
  - The renter will pay the lender the agreed upon amount of tokens.
  - A `RentalNft` struct will be
- `return_nft` - The lender calls this function to return the NFT to the lender.

  - This function would only proceed if the NFT that is rented out is has passed the rental period.
  - Anyone can call this function to return the NFT after the rental period has ended.
  - This would allow for an onchain devops execution to return the NFT if the renter fails to call it.

- `pay_rent` - The renter calls this function to pay the rent before he borrows the nft.
  - The rent is paid in advance and the renter can borrow the NFT immediately after paying the rent.
  - The amout of rent should be determined by the rental period and the rental price of the NFT. However for now, we will just use a fixed amount of rent determined by the lender.

### Structs

Rental Vault struct - This struct is used to store the NFTs that are being rented out.

```move
struct RentalVault has key,store,drop {

}
```

```move
struct RentalContract has key,store,drop {
    lender: address,
    renter: address,
    nft_id: u64,
    nft_type: u64,
    rental_period: u64,
    rental_fee: u64,
    rental_start_time: u64,
    rental_end_time: u64,
    rent_paid: bool,
    nft_returned: bool,
}
```

### 2. Rental NFT

- This Rental NFT acts like a wrapper on top of the base NFT using the concept of Dynamic fields.
- Dynamic fields allows us to provide a parent child relationship of the rental NFT and the underlying NFT. In this case, the Rental NFT is the parent and the NFT is the child.
- Rental NFT wrapper restricts the utility of the NFT only to the renter, while still having the vault maintaining custody as the ownership of the parent rental nft belongs to the vault.

### Structs

### Core Functions
