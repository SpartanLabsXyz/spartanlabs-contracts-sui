module nft_rental::rental_vault{
    use sui::object::{Self, Info};
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_object_field as ofield;
    use sui::vec_map::{Self, VecMap};
    use sui::transfer;
    use sui::event::emit;

    use std::vector as vec;
    use std::string;


    // Importing sample nft
    use nft_rental::sample_nft::DevNetNFT;


        
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
      rental_fee: u64,
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






    ///*///////////////////////////////////////////////////////////////
    //                           ERROR CODES                         //
    /////////////////////////////////////////////////////////////////*/

    ///*///////////////////////////////////////////////////////////////
    //                         RENTAL VAULT LOGIC                     //
    /////////////////////////////////////////////////////////////////*/
    
    // Create a vault with NFT of type T for rental
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

    
    // Lends an NFT to a vault before vault lends to rentee.
    public entry fun lend_nft(rental_vault: &mut RentalVault, nft: &mut DevNetNFT, time_period: u64, rental_fee: u64, ctx: &mut TxContext){

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
    
    // The rentee calls this function to rent an NFT from the vault.
    public entry fun rent_nft(rental_vault: &mut RentalVault, nft: &DevNetNFT, rental_term: &mut RentalTerm, ctx: &mut TxContext) {
      // make payment to the rentee

      // Check if payment has been made
      assert!(rental_term.payment_made == true, 0);

      // Get start date by using today's date

      // Get end date by adding rental_period to start date

      // Create a parent object with struct `RentalNft`

      // Add Nft as a dynamic field as child object to parent object

      // Update `rental_term`

      // Make `rental_nft` a shared object

      // Transfer `rental_nft` to rentee

      // Emit Nft Rented Event

    }

  //   - `pay_rent` - The rentee calls this function to pay the rent before he borrows the nft.
  // - The rent has to be paid in advance and the rentee can borrow the NFT immediately after paying the rent.
  // - The amout of rent should be determined by the rental period and the rental price of the NFT. However for now, we will just use a fixed amount of rent determined by the renter.
  // - The rent payment would be transferred to the renter.

  // The rentee calls this function to pay the rent before he borrows the nft.
  public entry fun pay_rent(rental_term: &mut RentalTerm, ctx: &mut TxContext){
   // Check if payment has been made before. If so return the function
   if (rental_term.payment_made) {
    return
   };
   
    // Get payment amount from rental term
    let payment_amount = rental_term.payment_amount;

    // Assert if the rentee has enough for payment. Assume Sui for now

    // Make payment

    // Update Rental Term with payment made

  }



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
    //                         RENTAL TERM LOGIC                     //
    /////////////////////////////////////////////////////////////////*/
    
    // Sets the rentee of a rental Term
    public entry fun set_rentee(){}


    // ===== Public view functions =====
    public entry fun get_renter(rental_term: &RentalTerm): address {
        rental_term.renter
    }
    


    

}