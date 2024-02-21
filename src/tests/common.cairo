use starknet::{class_hash::Felt252TryIntoClassHash, ContractAddress, SyscallResultTrait};
use openzeppelin::token::{erc20::interface::IERC20Dispatcher, erc721::interface::IERC721Dispatcher};
use refunfable_erc721::interface::IRefundableDispatcher;
use refunfable_erc721::tests::erc20::ERC20;
use refunfable_erc721::tests::erc721::{
    ERC721, IExampleERC721Dispatcher, IExampleERC721DispatcherTrait
};
use refunfable_erc721::contract::RefundableERC721;


fn deploy(contract_class_hash: felt252, calldata: Array<felt252>) -> ContractAddress {
    let (address, _) = starknet::deploy_syscall(
        contract_class_hash.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap_syscall();
    address
}

// erc721 and erc721_custom link to the same contract_address but with a different interface
fn deploy_contract() -> (
    IERC20Dispatcher, IERC721Dispatcher, IExampleERC721Dispatcher, IRefundableDispatcher
) {
    // strk
    let strk = deploy(ERC20::TEST_CLASS_HASH, array![]);
    // erc721, 0x123 will receive the supply
    let erc721 = deploy(ERC721::TEST_CLASS_HASH, array![]);
    // refund_contract, 0x123 is the admin, we end the refund at t=1000
    let refund_contract = deploy(
        RefundableERC721::TEST_CLASS_HASH, array![erc721.into(), strk.into(), 1000, 0x123]
    );
    // connects nft to refund contract
    IExampleERC721Dispatcher { contract_address: erc721 }.set_refund_contract(refund_contract);
    (
        IERC20Dispatcher { contract_address: strk },
        IERC721Dispatcher { contract_address: erc721 },
        IExampleERC721Dispatcher { contract_address: erc721 },
        IRefundableDispatcher { contract_address: refund_contract }
    )
}
