#[starknet::contract]
mod RefundableERC721 {
    use openzeppelin::token::erc721::interface::IERC721DispatcherTrait;
    use starknet::{get_caller_address, get_contract_address, get_block_timestamp, ContractAddress};
    use refunfable_erc721::interface::IRefundable;
    use storage_read::{main::storage_read_component, interface::IStorageRead};
    use openzeppelin::{
        token::{
            erc20::interface::{IERC20Camel, IERC20Dispatcher, IERC20DispatcherTrait},
            erc721::interface::{IERC721, IERC721Dispatcher, IERC721CamelOnlyDispatcherTrait}
        },
    };

    #[abi(embed_v0)]
    impl StorageReadImpl = storage_read_component::StorageRead<ContractState>;

    component!(path: storage_read_component, storage: storage_read, event: StorageReadEvent);

    #[storage]
    struct Storage {
        nft_contract: ContractAddress,
        payment_erc20: ContractAddress,
        refund_end_time: u64,
        admin: ContractAddress,
        refundable: LegacyMap<u256, u256>,
        #[substorage(v0)]
        storage_read: storage_read_component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        StorageReadEvent: storage_read_component::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        nft_contract: ContractAddress,
        payment_erc20: ContractAddress,
        refund_end_time: u64,
        admin: ContractAddress,
    ) {
        self.nft_contract.write(nft_contract);
        self.payment_erc20.write(payment_erc20);
        self.refund_end_time.write(refund_end_time);
        self.admin.write(admin);
    }

    #[abi(embed_v0)]
    impl Refundable of IRefundable<ContractState> {
        fn register_payment(
            ref self: ContractState, nft_id: u256, buyer: ContractAddress, price: u256
        ) {
            // called first to avoid reentrancy
            IERC20Dispatcher { contract_address: self.payment_erc20.read() }
                .transfer_from(buyer, get_contract_address(), price);
            // only the NFT contract can trigger a payment (because it is linked to an id)
            assert(
                get_caller_address() == self.nft_contract.read(), 'Not the right erc721 contract'
            );
            let existing_value = self.refundable.read(nft_id);
            assert(existing_value == 0, 'You can\'t overwrite a price');
            self.refundable.write(nft_id, price);
        }

        fn claim_refund(ref self: ContractState, nft_id: u256) {
            let to_refund = self.refundable.read(nft_id);
            let caller = get_caller_address();
            // so you can't claim twice the same NFT
            self.refundable.write(nft_id, 0);
            assert(
                self.refund_end_time.read() > get_block_timestamp(), 'The refund period has ended'
            );
            let nft_dispatcher = IERC721Dispatcher { contract_address: self.nft_contract.read() };
            assert(nft_dispatcher.owner_of(nft_id) == caller, 'You don\'t own this NFT');
            // pay for the NFT
            IERC20Dispatcher { contract_address: self.payment_erc20.read() }
                .transfer(caller, to_refund);
            // take nft from user
            nft_dispatcher.transfer_from(caller, self.admin.read(), nft_id);
        }

        fn admin_claim_funds(ref self: ContractState, erc20: ContractAddress) {
            // erc20 is a param so you can withdraw anything
            let erc20_dispatcher = IERC20Dispatcher { contract_address: erc20 };
            erc20_dispatcher
                .transfer(
                    get_caller_address(), erc20_dispatcher.balance_of(get_contract_address())
                );
            assert(
                self.refund_end_time.read() <= get_block_timestamp(),
                'The refund period has not ended'
            );
        }

        fn get_claimable(self: @ContractState, nft_id: u256) -> u256 {
            self.refundable.read(nft_id)
        }

        fn get_nft_contract(self: @ContractState) -> ContractAddress {
            self.nft_contract.read()
        }
    }
}
