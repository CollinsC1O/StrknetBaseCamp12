#[starknet::interface]
trait ICounter<TContractState>{
    fn get_counter(self: @TContractState) -> u32;
    fn increase_counter(ref self: TContractState);
    fn decrease_counter(ref self: TContractState);
    fn reset_counter(ref self: TContractState);
}

#[starknet::contract]
pub mod Counter{
    use OwnableComponent::InternalTrait;
use super::ICounter;
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::StoragePointerWriteAccess;
    use starknet::storage::StoragePointerReadAccess;
    use openzeppelin_access::ownable::OwnableComponent; 

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;


        
    //////////////////////////////////////////////
    /////////////  Error Module  /////////////////
    //////////////////////////////////////////////
    pub mod Error{
        pub const EMPTY_COUNTER: felt252 = 'Decrease empty counter';
    } 

    
    //////////////////////////////////////////////
    ///////////// STORAGE ////////////////////////
    //////////////////////////////////////////////
    #[storage]
    struct Storage{
        counter: u32,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    //////////////////////////////////////////////
    ///////////// EVENTS ////////////////////////
    //////////////////////////////////////////////
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event{
        Increase: Increase,
        Decrease: Decrease,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    pub struct Increase{
        account: ContractAddress,
    }


    #[derive(Drop, starknet::Event)]
    pub struct Decrease{
        account: ContractAddress,
    }


    #[constructor]
    fn constructor(ref self: ContractState, init_value: u32, owner: ContractAddress){
        self.counter.write(init_value);
        //initialize owner
        self.ownable.initializer(owner);
    }

    impl CounterImpl of ICounter<ContractState>{
        fn get_counter(self: @ContractState) -> u32{
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState){
            let new_value = self.counter.read() + 1;
            self.counter.write(new_value);
            self.emit(Increase {account: get_caller_address()})
            
        }

        fn decrease_counter(ref self: ContractState){
            let old_value = self.counter.read();
            assert(old_value > 0, Error::EMPTY_COUNTER);
            self.counter.write(old_value - 1);
            self.emit(Decrease {account: get_caller_address()})
        }

        fn reset_counter(ref self: ContractState){
            //ensure only owner can reset counter
            self.ownable.assert_only_owner();
            self.counter.write(0)
        }
    }
}