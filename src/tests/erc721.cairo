use starknet::ContractAddress;
#[starknet::interface]
trait IExampleERC721<TContractState> {
    fn mint(ref self: TContractState, token_id: u256);
    fn set_refund_contract(ref self: TContractState, refund_contract: ContractAddress);
    fn get_refund_contract(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
mod ERC721 {
    use refunfable_erc721::interface::IRefundableDispatcherTrait;
    use starknet::{ContractAddress, get_contract_address, get_caller_address};
    use storage_read::{main::storage_read_component, interface::IStorageRead};
    use refunfable_erc721::interface::{IRefundable, IRefundableDispatcher};
    use openzeppelin::{
        token::erc721::{
            ERC721Component, erc721::ERC721Component::InternalTrait as ERC721InternalTrait
        },
        introspection::{src5::SRC5Component}
    };

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5CamelImpl = SRC5Component::SRC5CamelImpl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.erc721.initializer('Refundable NFT', 'rNFT');
    }

    #[abi(embed_v0)]
    impl GenerationImpl of super::IExampleERC721<ContractState> {
        fn mint(ref self: ContractState, token_id: u256) {
            let buyer = get_caller_address();
            self.erc721._mint(buyer, token_id);
            // the minting price is 1 unit of token for this example
            IRefundableDispatcher { contract_address: self.refund_contract.read() }
                .register_payment(token_id, buyer, 1);
        }

        fn set_refund_contract(ref self: ContractState, refund_contract: ContractAddress) {
            self.refund_contract.write(refund_contract);
        }

        fn get_refund_contract(self: @ContractState) -> ContractAddress {
            self.refund_contract.read()
        }
    }

    #[storage]
    struct Storage {
        refund_contract: ContractAddress,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
    }
}
