# SUI


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