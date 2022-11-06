module nft_rental::rental_vault{
    use sui::object::{Self, Info};
    use sui::tx_context::TxContext;
    use sui::dynamic_object_field as ofield;

    // Importing sample nft
    use nft_rental::sample_nft::Nft;



        
    ///*///////////////////////////////////////////////////////////////
    //                         MAIN OBJECTS                          //
    /////////////////////////////////////////////////////////////////*/
    
    struct RentalVault has key, store, drop {
      id: UID,
    }
    struct RentalNft has key, store, drop {
      id: UID,
      nft_type: T<Nft>,

    }
    struct RentalTerm has key, store, drop {
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

    // Event. When new Nft is being rented.
    struct NftRented has copy, drop {
        id: UID,
        gen: u64,
        genes: Genes,
        birthday: u64,
        rental_term: RentalTerm,
        rented_by: address
    }

    /// Event. When a new vault has been created.
    struct RentalVaultCreated has copy, drop { id: ID }



    ///*///////////////////////////////////////////////////////////////
    //                           ERROR CODES                         //
    /////////////////////////////////////////////////////////////////*/

    ///*///////////////////////////////////////////////////////////////
    //                         RENTAL VAULT LOGIC                     //
    /////////////////////////////////////////////////////////////////*/
    
    // Create a vault with NFT of type T for rental
    fun init(ctx: &mut TxContext) {
        let id = object::new(ctx);
        let capy_hash = hash(object::uid_to_bytes(&id));

        emit(RentalVaultCreated { id: object::uid_to_inner(&id) });

        transfer::transfer(CapyManagerCap { id: object::new(ctx) }, tx_context::sender(ctx));
        transfer::share_object(CapyRegistry {
            id,
            capy_hash,
            capy_born: 0,
            capy_day: 0,
            genes: vec::empty()
        })
    }

    
    // Lends an NFT to a vault before vault lends to rentee.
    public entry fun lend_nft(nft: &mut Nft, nft_id:  time_period: u64, rental_fee: u64, ctx: &mut TxContext){

      // Transfer the ownership of the 

      // Create a `RentalTerm` object and add it to the collection

    }
    
    // The rentee calls this function to rent an NFT from the vault.
    // public entry fun rent_nft(nft_rented: &Nft){}



    ///*///////////////////////////////////////////////////////////////
    //                         RENTAL NFT LOGIC                     //
    /////////////////////////////////////////////////////////////////*/
    public entry fun add_nft(rental_nft: &mut RentalNft, nft: Nft) {
      ofield::add(&mut rental_nft.id, b"child", nft);
    }

    public entry fun mutate_nft(rental_nft: &mut RentalNft) {
    mutate_nft(ofield::borrow_mut<vector<u8>, Nft>(
        &mut rental_nft.id,
        b"child",
     ));
    }


    ///*///////////////////////////////////////////////////////////////
    //                         RENTAL Term LOGIC                     //
    /////////////////////////////////////////////////////////////////*/
    
    // public entry add_nft_term(){}

    // public entry set_rentee(){}


    // // Return the details given a rental term object
    // public entry get_rental_terms(rental_term: &RentalTerm){}

    

}