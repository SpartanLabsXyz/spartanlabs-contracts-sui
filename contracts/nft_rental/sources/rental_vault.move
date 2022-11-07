module nft_rental::rental_vault{
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_object_field as ofield;
    use sui::vec_map::{Self, VecMap};
    use sui::transfer;
    use sui::event::emit;
    use sui::coin::{Self, Coin};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    use std::vector as vec;
    use std::string;


    // Importing sample nft
    use nft_rental::sample_nft::{Self, SwordNft as Nft};
    use nft_rental::sample_nft::{Self, NftOwnerCap};



        
    ///*///////////////////////////////////////////////////////////////
    //                         MAIN OBJECTS                          //
    /////////////////////////////////////////////////////////////////*/
    
    struct RentalVault has key, store, drop {
      vault_id: ID,
      nft_type: string::String,
      renters: vec_map::VecMap<UID, address>,
      rentees: vec_map::VecMap<UID, address>,
      rental_terms: vec_map::VecMap<UID, RentalTerms>,
    }
    struct RentalNft has key, store, drop {
      rental_nft_id: ID,
      nft_type: string::String,
      end_date: u64
    }

    struct RentalTerm has key, store, drop {
      term_id: ID,
      renter: address,
      rentee: address,
      nft_id: u64,
      nft_type: string::String,
      rental_period: u64,
      rental_fee: Balance<T>,
      rental_start_time: u64,
      rental_end_time: u64,
      nft_returned: bool,
      payment_made: bool,
    }

    /// Belongs to the owner of the vault. Has store, which
    /// allows building something on top of it (ie shared object with multi-access policy for owner).
    struct VaultOwnerCap has key, store {
      id: ID
    }


    // ======== Events =========

    // Event. When a new rental vault has been created.
    struct RentalVaultCreated has copy, drop { id: ID }

    // Event. When a renter transfers a nft to the rental vault.
    struct NftTransferred has copy, drop { id: ID }

    // Event. When new Nft is being rented to a rentee by a 
    struct NftRented has copy, drop {
        id: ID,
        rental_term: RentalTerm,
        nft_id: u64,
        renter: address,
        rented_by: address
    }

    // Event. When a rentee returns a nft to the rental vault.
    struct NftReturned has copy, drop { id: ID }


    ///*///////////////////////////////////////////////////////////////
    //                           ERROR CODES                         //
    /////////////////////////////////////////////////////////////////*/
    
    // TODO: Fill up error codes for more detailed error handling

    /// Attempted to perform an admin-only operation without valid permissions
    /// Try using the correct `AdminCap`
    const EAdminOnly: u64 = 0;

    ///*///////////////////////////////////////////////////////////////
    //                         RENTAL VAULT LOGIC                     //
    /////////////////////////////////////////////////////////////////*/
    
    /// Create a vault with NFT of type T for rental
    public entry fun create_vault(nft_type: vector<u8>, ctx: &mut TxContext) {
        let id = object::new(ctx);
        let rental_vault = RentalVault {
            id,
            nft_type: string::utf8(nft_type),
            renters: vec_map::new(),
            rentees: vec_map::new(),
            rental_terms: vec_map::new(),
        } = object::create(ctx, id);

        // Emit the event using future object's ID.
        emit(RentalVaultCreated { id: object::uid_to_inner(&id) });
        
        // Create a capability for the owner of the vault.
        transfer::transfer(VaultOwnerCap { id: object::new(ctx) }, tx_context::sender(ctx));
    }

    
    /// Lends an NFT to a vault before vault lends to rentee.
    public entry fun lend_nft(rental_vault: &mut RentalVault, nft: &mut Nft, time_period: u64, rental_fee: u64, ctx: &mut TxContext){

      // Transfer the ownership of the NFT to the vault
      sample_nft::transfer_ownership(nft,rental_vault, ctx);

      // Assert that the vault now owns the NFT
      assert!(sample_nft::get_owner(nft) == rental_vault.address, 0);

      // Create a `RentalTerm` object and add it to the collection
      let rental_term = RentalTerm {
        id: object::new(ctx),
        renter: tx_context::sender(ctx),
        rentee: address::zero(), // Set to zero for now until rent
        nft_id: nft.id,
        nft_type: nft.name,
        rental_period: time_period,
        rental_fee: rental_fee,
        rental_start_time: 0, // Set to zero for now until rent
        rental_end_time: 0, // // Set to zero for now until rent
        nft_returned: false,
        payment_made: false,
      } = object::create(ctx, object::new(ctx));

      // Add the `RentalTerm` object to the rental_term collection
      vec_map::insert(&mut rental_vault.rental_terms, rental_term.id, rental_term);

      // Add renter to the `renters` collection
      vec_map::insert(&mut rental_vault.renters, rental_term.id, rental_term.renter);
      
      // Emit NftTransferred event
      emit(NftTransferred { id: object::uid_to_inner(&rental_vault.id) });
    }
    
    /// The rentee calls this function to rent an NFT from the vault.
    public entry fun rent_nft(_: &VaultOwnerCap, rental_vault: &mut RentalVault, nft: &Nft, rental_term: &mut RentalTerm, ctx: &mut TxContext) {

      // Check if payment has been made
      assert!(rental_term.payment_made == true, 0);

      // Get start date by using today's date
      let start_date = time::now();

      // Get end date by adding rental_period to start date
      let end_date = start_date + get_rental_period(rental_term);

      // Create a parent object with struct `RentalNft`
      let rental_nft = RentalNft {
        id: object::new(ctx),
        nft_type: rental_term.nft_type,
        end_date: end_date,
      } = object::create(ctx, object::new(ctx));

      // Add Nft as a dynamic field as child object to parent object
      add_nft(&rental_nft, nft, ctx);

      // Update `rental_term`
      let sender = tx_context::sender(ctx);
      set_rentee(rental_term, tx_context::sender(ctx));

      // Make `rental_nft` a shared object to make it accessible to the rentee
      transfer::share_object(rental_nft, sender);

      // Emit Nft Rented Event
      emit(NftRented {
        id: object::uid_to_inner(&rental_vault.id),
        rental_term: rental_term,
        nft_id: rental_term.nft_id,
        renter: rental_term.renter,
        rented_by: rental_term.rentee
      });

    }


  // The rentee calls this function to pay the rent before he borrows the nft.
  public entry fun pay_rent(rental_term: &mut RentalTerm, payment: Coin<SUI>, ctx: &mut TxContext){
   // Check if payment has been made before. If so return the function
   if (rental_term.payment_made) {
    return
   };
   
    // Get payment amount from rental term
    let rental_fee = rental_term.rental_fee;

    // Assert if the rentee has enough for payment. Assume Sui for now
    assert!(payment.value >= rental_fee, 0);

    // Make payment
    transfer::transfer(payment, rental_term.rentee);

    // Update Rental Term with payment made
    set_payment_made(rental_term);
  }

  // Get Rental Term belonging to the Renter of the Nft
  public fun get_rental_term(rental_vault: &RentalVault, nft_id: UID): RentalTerm {
    let rental_term = vec_map::get(&rental_vault.rental_terms, nft_id);
    return rental_term
  }


  ///*///////////////////////////////////////////////////////////////
  //                         RENTAL NFT LOGIC                     //
  /////////////////////////////////////////////////////////////////*/
  
  /// This function is used to add an nft as the child object of the rental nft.
  public entry fun add_nft(rental_nft: &mut RentalNft, nft: Nft) {
    ofield::add(&mut rental_nft.id, b"child", nft);
  }

  /// This function is used to reclaim the nft from the rental nft.
  public entry fun reclaim_nft(rental_nft: &mut RentalNft, rental_vault: &RentalVault, ctx: &mut TxContext){

    //  Remove the child NFT object from the parent `RentalNft` object
    let nft = ofield::remove<vector<u8>, Nft>(
        &mut rental_nft.id,
        b"child",
    );

    let renter = get_rental_term(rental_vault, rental_nft.id).renter;

    // Send the NFT back to its the renter of the NFT.
    transfer::transfer(nft, renter);

    // Emit NftReturned event
    emit(NftReturned { id: object::uid_to_inner(&rental_vault.id) });
  }

  /// Changes the NFT via the parent `RentalNft` object.
  public entry fun mutate_nft(rental_nft: &mut RentalNft, rental_term: &RentalTerm, ctx: &mut TxContext) {
  level_up(ofield::borrow_mut<vector<u8>, Nft>(
      &mut rental_nft.id,
      b"child",
    ));
  }

  /// Utilises the child nft object 
  public entry fun utilise_nft(rental_nft: &RentalNft, rental_term: &RentalTerm, ctx: &mut TxContext) {
    // using hot potato pattern to transfer the ownership of the NFT to the rentee
    let nft_owner_cap = // TODO:
    
    // Call the child nft function with the cap
    slash(nft_owner_cap, ofield::borrow_mut<vector<u8>, Nft>(
      &mut rental_nft.id,
      b"child",
    ));
  }

  /// Destroys parent `RentNft` object after the NFT has been returned.
  public fun destroy_rental_nft(rental_nft: &mut RentalNft, ctx: &mut TxContext) {
    object::destroy(ctx, rental_nft.id);
  }

  /// Returns an ID of a Nft for a given Rental Nft.
  public fun get_nft_id(rental_nft: &RentalNft): u64 {
    ofield::borrow<vector<u8>, Nft>(
      &rental_nft.id,
      b"child",
    ).id
  }



    ///*///////////////////////////////////////////////////////////////
    //                         RENTAL TERM LOGIC                     //
    /////////////////////////////////////////////////////////////////*/
    
    /// Sets the rentee of a rental Term
    public entry fun set_rentee(rental_term: &mut RentalTerm, rentee: address){
      rental_term.rentee = rentee;
    }

    /// Sets the rental start time of a rental Term
    /// The start time is set when the rentee pays the rental fee
    public entry fun set_rental_start_time(rental_term: &mut RentalTerm, rental_start_time: u64){
      rental_term.rental_start_time = rental_start_time;
    }

    /// Sets the rental end time of a rental Term
    public entry fun set_rental_end_time(rental_term: &mut RentalTerm, rental_end_time: u64){
      rental_term.rental_end_time = rental_end_time;
    }

    /// Update Rental Term with payment made
    public entry fun set_payment_made(rental_term: &mut RentalTerm){
      rental_term.payment_made = true;
    }


    // ===== Public view functions =====
    public entry fun get_renter(rental_term: &RentalTerm): address {
        rental_term.renter
    }

    public entry fun get_rentee(rental_term: &RentalTerm): address {
        rental_term.rentee
    }

    /// Returns the Rental Period of a Rental Term
    /// The rental period is the number of days the rentee can borrow the NFT
    public entry fun get_rental_period(rental_term: &RentalTerm): u64 {
        rental_term.rental_period
    }

    ///*///////////////////////////////////////////////////////////////
    //                         ADMIN ONLY LOGIC                     //
    /////////////////////////////////////////////////////////////////*/
    
    /// Checks if the address is the admin of the vault
    fun check_vault_owner<T>(self: &RentalVault, nft_owner_cap: &NftOwnerCap){
      assert!(object::borrow_id(self) == &nft_owner_cap.flash_lender_id, EAdminOnly);
    }
}