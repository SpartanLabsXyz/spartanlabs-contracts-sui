# SUI NFT Rental Contract

### Terminoology

Ownership: The person who the nft belongs to

Custody: The person who holds the nft

Utility: The person who can use the properties of the nft

Rentees: People who have a NFT of interest and are willing to lend that NFT out to the protocol to take custody of the NFT, but still remain owners of the NFT.

Renters: People who are willing and able to borrow an NFT’s utility for a price that is paid to the renters

## Contracts

- List of core contracts for SUI NFT Rental

### 1. Rental Vault

- The vault acts as the main interface in which the renter and rentee interacts with.

#### Core Functions:

- `create_vault` - Create a vault with NFT of type T for rental

- `lend_nft` - Lends an NFT to a vault before vault lends to rentee

  - The lender must approve the vault to transfer the NFT before calling this function.
  - The lender will decide on the conditions of rental - the rental period, and the rental fee.
  - The NFT will be transferred to the rental vault. The nft is being rented out by the lender it is stored in the vault until it finds a renter
  - A `RentalTerm` object will be created outlining the terms of the rental.

- `rent_nft` - The rentee calls this function to rent an NFT from the vault.
  - The rentee will pay the renter the agreed upon amount of tokens.
  - A `RentalNft` struct will be
- `return_nft` - The lender calls this function to return the NFT to the lender.

  - This function would only proceed if the NFT that is rented out is has passed the rental period.
  - Anyone can call this function to return the NFT after the rental period has ended.
  - This would allow for an onchain devops execution to return the NFT if the renter fails to call it.

- `pay_rent` - The rentee calls this function to pay the rent before he borrows the nft.
  - The rent has to be paid in advance and the rentee can borrow the NFT immediately after paying the rent.
  - The amout of rent should be determined by the rental period and the rental price of the NFT. However for now, we will just use a fixed amount of rent determined by the renter.
  - The rent payment would be transferred to the renter.

Since rental vault also stores all the `RentalTerms`, these functions exposes the `RentalTerms` to the rentee and renter.

- `add_rental_term` - Adds a new `RentalTerm` to the `RentalTerm` collection table.
- `get_rental_terms` - Returns all the rental terms stored in the collection table.
- `get_rental_term_by_nft_id` - This function is used to get a rental term from the rental term list based on nft id.
- `get_rental_term_by_renter` - This function is used to get a rental term from the rental term list based on renter address.

#### Structs

Rental Vault struct - This struct is used to store the NFTs that are being rented out.

```move
  struct RentalVault has key, store, drop {
      vault_id: ID,
      nft_type: string::String,
      renters: vec_map::VecMap<UID, address>,
      rentees: vec_map::VecMap<UID, address>,
      rental_terms: vec_map::VecMap<UID, RentalTerms>,
    }
```

### 3. Rental Term

- This contract is used to store the terms of the rent.
- Once the NFT is rented out, the rental term is created and stored in the rental vault.
- When the nft is returned, the rental term is deleted from the rental vault.

#### Core Functions:

- `add_rental_term` - This function is used to add a rental contract to the rental term list.
- `set_rentee` - This function is used to set the rentee of a rental contract.
- `get_rental_terms` - Return the details given a rental term object

#### Structs

Rental Term struct - This struct is used to store the terms of the rental.

```move
struct RentalTerm has key,store,drop {
    id: UID,
    renter: address,
    rentee: address,
    nft_id: u64,
    nft_type: u64,
    rental_period: u64,
    rental_fee: u64,
    rental_start_time: u64,
    rental_end_time: u64,
    nft_returned: bool,
}
```

### 3. Rental NFT

- This Rental NFT acts like a wrapper on top of the base NFT using the concept of Dynamic fields.
- Dynamic fields allows us to provide a parent child relationship of the rental NFT and the underlying NFT. In this case, the Rental NFT is the parent and the NFT is the child.
- Rental NFT wrapper restricts the utility of the NFT only to the renter, while still having the vault maintaining custody as the ownership of the parent rental nft belongs to the vault.
  - Rental NFT is a shared object which is owned by the rental vault but has utility (read and write function) exposed to the rentee

#### Core Functions

#### Structs

Rental NFT struct - This struct is a dynamic field wrapper on top of the NFT struct that provides the rental logic on top of the NFT. Rental NFT is the parent and NFT is the child.

```move
   struct RentalNft has key, store, drop {
      id: ID,
      nft_type: string::String,
      end_date: u64
    }
```

- `add_nft` - This function is used to add an nft as the child object of the rental nft.
- `reclaim_nft` - This function is used to reclaim the nft from the rental nft.
  - This will remove the child NFT object from the parent `RentalNft` object and send the NFT back to its the renter of the NFT.
  - The `RentalNft` object is then de-structured and destroyed.
- `get_nft_id` - This function is used to get the details of the nft from the rental nft.

#### 4. VaultOwnerCap

- VaultOwnerCap is a capability that is used to restrict the access of the vault to only the owner of the vault.

#### Struct

```move
    struct VaultOwnerCap has key, store {
      id: ID
    }
```

#### 5. Sample NFT

- This is a sample NFT contract that is used to test the rental contract.
