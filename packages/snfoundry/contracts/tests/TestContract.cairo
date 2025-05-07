use contracts::Counter::Counter;
use contracts::Counter::{ICounterDispatcher, ICounterDispatcherTrait};
use openzeppelin_access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};
use snforge_std::EventSpyAssertionsTrait;
// Import libraries
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, spy_events, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress};

const ZERO_COUNT: u32 = 0;

// define owner
fn OWNER() -> ContractAddress {
    'OWNER'.try_into().expect('expect owner')
}

fn USER_1() -> ContractAddress {
    'USER_1'.try_into().expect('expect USER_1')
}

// deploy util function
fn _deploy_(initial_count: u32) -> (ICounterDispatcher, IOwnableDispatcher) {
    //declare contract
    let class_hash = declare("Counter").expect('failed to declare').contract_class();

    //serialize constructor
    let mut calldata: Array<felt252> = array![];
    initial_count.serialize(ref calldata);
    OWNER().serialize(ref calldata);

    // deploy contract
    let (contract_address, _) = class_hash.deploy(@calldata).expect('failed to deploy');

    let counter = ICounterDispatcher { contract_address: contract_address };
    let ownable = IOwnableDispatcher { contract_address: contract_address };

    (counter, ownable)
}

#[ignore]
#[test]
fn test_counter_deployment() {
    let (counter, ownable) = _deploy_(ZERO_COUNT);
    // get current count
    let count_1 = counter.get_counter();

    assert(count_1 == ZERO_COUNT, 'count not set');
    assert(ownable.owner() == OWNER(), 'owner not set')
}

#[ignore]
#[test]
fn test_increase_count() {
    let (counter, _) = _deploy_(ZERO_COUNT);

    // get current count
    let count_1 = counter.get_counter();

    assert(count_1 == ZERO_COUNT, 'count not set');

    counter.increase_counter();

    //retrieve current count
    let count_2 = counter.get_counter();
    assert(count_2 == count_1 + 1, 'failed to increase count');
}

#[test]
fn test_emitted_event() {
    let (counter, _) = _deploy_(ZERO_COUNT);
    let mut spy = spy_events();

    // mock a caller  // to simulate the person calling the increase counnt function
    start_cheat_caller_address(
        counter.contract_address, USER_1(),
    ); // expecting contract address and caller address as arguments
    counter.increase_counter();
    stop_cheat_caller_address(
        counter.contract_address,
    ); // expecting contract address as an argument

    spy
        .assert_emitted(
            @array![
                (
                    counter.contract_address,
                    Counter::Event::Increase(Counter::Increase { account: USER_1() }),
                ),
            ],
        );

    spy
        .assert_not_emitted(
            @array![
                (
                  counter.contract_address,
                  Counter::Event::Decrease(Counter::Decrease { account: USER_1() }),
                )
            ],
        )
}

// #[ignore]
// #[test]
// fn test_decrease_count() {
//     let (counter, _) = _deploy_(ZERO_COUNT);

//     let count_1 = counter.get_counter();

//     assert(count_1 == count_1 + 1, 'invalid count');

//     counter.decrease_counter();

//     let count_2 = counter.get_counter();

//     assert(count_2 == count_1 - 1, 'failed to decrease count')
// }
