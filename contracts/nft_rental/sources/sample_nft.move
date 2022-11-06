module nft_rental::sample_nft{
  struct Nft {

  }

  public entry fun mutate_nft(nft: &mut Nft) {
    child.count = child.count + 1;
  }
}