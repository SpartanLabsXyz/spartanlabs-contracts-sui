# SUI

This repository contains contracts that are developed by Spartan Labs for the SUI blockchain.

## Contracts

### NFT Rental
description: NFT Rental contract based on Spartan Labs article on NFT Rental #TODO : link to article
path: `contracts/nft_rental`


### Basic Commands

create an empty Move package
```move
sui move new my_first_package
```


Build Package
```
sui move build
```

Test Package
```
sui move test
```

Run only a subset of unit tests
```
sui move test --filter sword
```

For more info check out https://docs.sui.io/build/move/write-package


Publishing on chain

```bash
sui client publish --path SUI_Objects/sui_objects --gas-budget 10000
```