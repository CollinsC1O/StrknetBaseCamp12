// Import libraries
use snforge_std::{declare, DeclareResultTrait, ContractClassTrait};
use starknet::{ContractAddress};
use contracts::Counter::{ICounterDispatcher, ICounterDispatcherTrait}; 
use openzeppelin_access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};

const ZERO_COUNT: u32 = 0;

// define owner
fn OWNER() -> ContractAddress {
 'OWNER'.try_into().expect('expect owner')
}

// deploy util function
fn _deploy_(initial_count: u32) -> (ICounterDispatcher, IOwnableDispatcher){
    //declare contract
    let class_hash = declare("Counter").expect('failed to declare').contract_class();

    //serialize constructor
    let mut calldata: Array<felt252> = array![];
    initial_count.serialize(ref calldata);
    OWNER().serialize(ref calldata);

    // deploy contract
    let (contract_address, _) = class_hash.deploy(@calldata).expect('failed to deploy');

    let counter = ICounterDispatcher{contract_address: contract_address};
    let ownable = IOwnableDispatcher{contract_address: contract_address};

    (counter, ownable)
}

 #[test]
 fn test_counter_deployment(){
    let (counter, ownable) = _deploy_(ZERO_COUNT);
    // get current count
    let count_1 = counter.get_counter();

    assert(count_1 == ZERO_COUNT, 'count not set');
    assert(ownable.owner() == OWNER(), 'owner not set')

 }

 #[test]
 fn test_increase_count() {
    let (counter, ownable) = _deploy_(ZERO_COUNT);

      // get current count
      let count_1 = counter.get_counter();

      assert(count_1 == ZERO_COUNT, 'count not set');

      counter.increase_counter();

      //retrieve current count
      let count_2 = counter.get_counter();  
      assert(count_2 == count_1 + 1, 'failed to increase count');
 }