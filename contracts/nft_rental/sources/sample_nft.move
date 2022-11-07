module nft_rental::sample_nft {
    use sui::url::{Self, Url};
    use std::string;
    use sui::object::{Self, ID, UID};
    use sui::event;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// An example NFT that can be minted by anybody
    struct SwordNft has key, store {
        id: UID,
        /// Name for the Sword
        name: string::String,
        /// Description of the Sword
        description: string::String,
        /// URL for the Sword
        url: Url,
        /// The level of the Sword
        level: u64,
    }

    /// Type that marks Owner's abilities to use the Sword `Nft`s.
    struct NftOwnerCap has key { id: UID }

    // ===== Events =====

    struct NFTMinted has copy, drop {
        // The Object ID of the NFT
        object_id: ID,
        // The creator of the NFT
        creator: address,
        // The name of the NFT
        name: string::String,
    }

    ///*///////////////////////////////////////////////////////////////
    //                         NFT LOGIC                     //
    /////////////////////////////////////////////////////////////////*/
    

    // ===== Public view functions =====

    /// Get the NFT's `name`
    public fun name(nft: &SwordNft): &string::String {
        &nft.name
    }

    /// Get the NFT's `description`
    public fun description(nft: &SwordNft): &string::String {
        &nft.description
    }

    /// Get the NFT's `url`
    public fun url(nft: &SwordNft): &Url {
        &nft.url
    }

    // ===== Entrypoints =====

    /// Create a new devnet_nft
    public entry fun mint_to_sender(
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);

        // Create the Sword NFT
        let nft = SwordNft {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url),
            level: 1,
        };


        event::emit(NFTMinted {
            object_id: object::id(&nft),
            creator: sender,
            name: nft.name,
        });

        transfer::transfer(nft, sender);

        // Create an instance of tyhe NFT Owner capability and send it to the owner of the NFT
        transfer::transfer(NftOwnerCap {id: nft.id}, sender);
    }

    /// Transfer `nft` to `recipient`
    public entry fun transfer(
        nft: SwordNft, recipient: address, _: &mut TxContext
    ) {
        transfer::transfer(nft, recipient)
    }

    /// Update the `description` of `nft` to `new_description`
    public entry fun update_description(
        nft: &mut SwordNft,
        new_description: vector<u8>,
        _: &mut TxContext
    ) {
        nft.description = string::utf8(new_description)
    }

    /// Permanently delete `nft`
    public entry fun burn(nft: SwordNft, _: &mut TxContext) {
        let SwordNft { id, name: _, description: _, url: _ } = nft;
        object::delete(id)
    }

    /// Transfer the ownership by transferring the NFT Owner capability to recipient
    public entry fun transfer_ownership(
        _: &NftOwnerCap,
        nft: &mut SwordNft,
        recipient: address,
        _: &mut TxContext
    ) {
        let SwordNft { id, name: _, description: _, url: _ } = nft;
        let cap = NftOwnerCap { id };
        transfer::transfer(cap, recipient)
    }


    // ===== Sword NFT Specific Function =====

    /// Sample Function of levelling up the sword
    public entry fun level_up(nft: &mut SwordNft) {
        nft.level = nft.level + 1;
    }

    /// Sample Function of showing utility of the Sword NFT
    /// This function can only be called by the owner of the sword
    public entry fun slash(_: NftOwnerCap, nft: &SwordNft){
        // TODO: Implement slashing logic
    }

}
