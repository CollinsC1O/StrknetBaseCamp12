// Import libraries
use contracts::Counter::Counter;
use contracts::Counter::{
    ICounterDispatcher, ICounterDispatcherTrait, ICounterSafeDispatcher,
    ICounterSafeDispatcherTrait,
};
use openzeppelin_access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};
use snforge_std::EventSpyAssertionsTrait;
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
fn _deploy_(
    initial_count: u32,
) -> (ICounterDispatcher, IOwnableDispatcher, ICounterSafeDispatcher) {
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
    let safe_dispatcher = ICounterSafeDispatcher { contract_address: contract_address };

    (counter, ownable, safe_dispatcher)
}


#[test]
fn test_counter_deployment() {
    let (counter, ownable, _) = _deploy_(ZERO_COUNT);
    // get current count
    let count_1 = counter.get_counter();

    assert(count_1 == ZERO_COUNT, 'count not set');
    assert(ownable.owner() == OWNER(), 'owner not set')
}


#[test]
fn test_increase_count() {
    let (counter, _, _) = _deploy_(ZERO_COUNT);

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
    let (counter, _, _) = _deploy_(ZERO_COUNT);
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
                ),
            ],
        )
}


#[test]
#[feature("safe_dispatcher")]
fn test_safe_panic_decrease_counter() {
    let (counter, _, safe_dispatcher) = _deploy_(ZERO_COUNT);

    //asserting that counter is set to zero
    assert(counter.get_counter() == ZERO_COUNT, 'invalid count');

    // ensuring that count can't be reduced below zero
    match safe_dispatcher.decrease_counter() {
        Result::Ok(_) => panic!("can not decrease to 0"),
        Result::Err(e) => assert(
            *e[0] == 'Decrease empty counter', *e.at(0),
        ) // this error(e) returns an array, we need the first index
    }
}

#[test]
#[should_panic(expected: 'Decrease empty counter')]
fn test_panic_decrease_counter() {
    let (counter, _, _) = _deploy_(ZERO_COUNT);

    //asserting that counter is set to zero
    assert(counter.get_counter() == ZERO_COUNT, 'invalid count');

    // trying to decrease below zero here
    counter.decrease_counter();
}


#[test]
fn test_successful_decrease_counter() {
    let (counter, _, _) = _deploy_(5);

    let count_1 = counter.get_counter();
    //asserting that counter is set to zero
    assert(count_1 == 5, 'invalid count');

    counter.decrease_counter();

    let final_count = counter.get_counter();
    assert(final_count == count_1 - 1, 'invalid decrease count');
}

#[test]
fn test_successful_reset_counter() {
    let (counter, _, _) = _deploy_(5);

    let count_1 = counter.get_counter();
    //asserting that counter is set to zero
    assert(count_1 == 5, 'invalid count');

    //using start and stop cheat caller to prank/simulate the owner
    start_cheat_caller_address(counter.contract_address, OWNER());
    //reset count to zero
    counter.reset_counter();
    stop_cheat_caller_address(counter.contract_address);

   //get the current count
    let final_count = counter.get_counter();
    assert(final_count == 0, 'invalid reset count');
}

#[test]
#[feature("safe_dispatcher")]
fn test_safe_panic_reset_by_non_owner() {
    let (counter, _, safe_dispatcher) = _deploy_(ZERO_COUNT);

    //asserting that counter is set to zero
    assert(counter.get_counter() == ZERO_COUNT, 'invalid count');

    start_cheat_caller_address(counter.contract_address, USER_1());
    // ensuring that count can't be reduced below zero
    match safe_dispatcher.reset_counter() {
        Result::Ok(_) => panic!("can not reset"),
        Result::Err(e) => assert(
            *e[0] == 'Caller is not the owner', *e.at(0),
        ) // this error(e) returns an array, we need the first index
    }
}