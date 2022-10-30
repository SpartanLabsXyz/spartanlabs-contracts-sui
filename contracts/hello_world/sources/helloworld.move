module hello_world::hello_world {
    // Part 1: imports
    // use sui::object::{Self, UID};
    // use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::debug;


    // Part 3: module initializer to be executed when this module is published
    fun init(_ctx: &mut TxContext) {
      // create a string of hello world
      let hello_world = b"Hello World!";

      debug::print(&hello_world);
    }

    #[test]
    fun test_hello_world() {
      use sui::tx_context;

      let ctx = tx_context::dummy();
      init(&mut ctx);
    }

}