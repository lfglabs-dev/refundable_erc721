#[starknet::contract]
mod ERC20 {
    use openzeppelin::token::erc20::erc20::ERC20Component::InternalTrait;
    use openzeppelin::{token::erc20::{ERC20Component, dual20::DualCaseERC20Impl}};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.erc20.initializer('Starknet Token', 'STRK');
        let target = starknet::contract_address_const::<0x123>();
        self.erc20._mint(target, 0x100000000000000000000000000000000);
    }

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
    }
}
