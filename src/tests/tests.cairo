use openzeppelin::token::erc721::interface::IERC721DispatcherTrait;
use openzeppelin::token::erc20::interface::IERC20DispatcherTrait;
use refunfable_erc721::interface::IRefundableDispatcherTrait;
use super::common::deploy_contract;

use starknet::testing::{set_block_timestamp, set_contract_address};
use refunfable_erc721::tests::erc721::{IExampleERC721Dispatcher, IExampleERC721DispatcherTrait};
use core::debug::PrintTrait;

#[test]
fn test_connection() {
    let (erc20, erc721, erc721_custom, refund) = deploy_contract();
    let admin = starknet::contract_address_const::<0x123>();
    set_contract_address(admin);

    // checks that erc721 is correctly connected to refund contract
    assert(erc721_custom.get_refund_contract() == refund.contract_address, 'wrong refund contract');
    //checks that refund contract is correctly connected to erc721
    assert(refund.get_nft_contract() == erc721.contract_address, 'wrong nft contract');
}

#[test]
fn test_register_payment_by_nft_contract() {
    let (erc20, erc721, erc721_custom, refund) = deploy_contract();
    let admin = starknet::contract_address_const::<0x123>();
    set_contract_address(admin);

    let initial_balance = erc20.balance_of(admin);
    let price = 1;
    let nft_id = 1;
    erc20.approve(refund.contract_address, price);
    erc721_custom.mint(nft_id);
    assert(erc20.balance_of(admin) == initial_balance - price, 'refund contract didn\'t debit');
    assert(refund.get_claimable(nft_id) == price, 'wrong claimable value');
    assert(erc721.owner_of(nft_id) == admin, 'buyer didn\'t receive the nft')
}

#[test]
fn test_claim_refund_by_nft_owner() {
    let (erc20, erc721, erc721_custom, refund) = deploy_contract();
    let admin = starknet::contract_address_const::<0x123>();
    let normal_user = starknet::contract_address_const::<0x456>();
    set_contract_address(admin);
    erc20.transfer(normal_user, 1);
    set_contract_address(normal_user);
    // before the refund
    set_block_timestamp(500);

    let initial_balance = erc20.balance_of(normal_user);
    assert(initial_balance == 1, 'wrong initial balance');
    let price = 1;
    let nft_id = 1;
    erc20.approve(refund.contract_address, price);
    erc721_custom.mint(nft_id);
    erc721.approve(refund.contract_address, nft_id);
    refund.claim_refund(nft_id);
    assert(erc20.balance_of(normal_user) == initial_balance, 'buyer didn\'t receive its refund');
    assert(erc721.owner_of(nft_id) == admin, 'nft was not sent back to admin');
}

#[test]
#[should_panic(expected: ('The refund period has ended', 'ENTRYPOINT_FAILED'))]
fn test_claim_refund_after_end_time() {
    let (erc20, erc721, erc721_custom, refund) = deploy_contract();
    let admin = starknet::contract_address_const::<0x123>();
    let normal_user = starknet::contract_address_const::<0x456>();
    set_contract_address(admin);
    erc20.transfer(normal_user, 1);
    set_contract_address(normal_user);
    // after the refund
    set_block_timestamp(1500);

    let price = 1;
    let nft_id = 1;
    erc20.approve(refund.contract_address, price);
    erc721_custom.mint(nft_id);
    erc721.approve(refund.contract_address, nft_id);
    refund.claim_refund(nft_id);
}

#[test]
#[should_panic(expected: ('You don\'t own this NFT', 'ENTRYPOINT_FAILED'))]
fn test_claim_refund_after_end_transfer() {
    let (erc20, erc721, erc721_custom, refund) = deploy_contract();
    let admin = starknet::contract_address_const::<0x123>();
    let normal_user = starknet::contract_address_const::<0x456>();
    set_contract_address(admin);
    erc20.transfer(normal_user, 1);
    set_contract_address(normal_user);
    // before the refund
    set_block_timestamp(500);

    let price = 1;
    let nft_id = 1;
    erc20.approve(refund.contract_address, price);
    erc721_custom.mint(nft_id);
    erc721.approve(refund.contract_address, nft_id);
    // I send it to the admin (or anyone else)
    erc721.transfer_from(normal_user, admin, nft_id);
    // I try to claim the refund
    refund.claim_refund(nft_id);
}

#[test]
#[should_panic(expected: ('The refund period has ended', 'ENTRYPOINT_FAILED'))]
fn test_claim_refund_post_end_time() {
    let (erc20, erc721, erc721_custom, refund) = deploy_contract();
    let admin = starknet::contract_address_const::<0x123>();
    let normal_user = starknet::contract_address_const::<0x456>();
    set_contract_address(admin);
    erc20.transfer(normal_user, 1);
    set_contract_address(normal_user);
    // before the refund
    set_block_timestamp(500);

    let price = 1;
    let nft_id = 1;
    set_block_timestamp(1500);
    erc20.approve(refund.contract_address, price);
    erc721_custom.mint(nft_id);
    erc721.approve(refund.contract_address, nft_id);
    let prev_admin_balance = erc20.balance_of(admin);
    refund.claim_refund(nft_id);
}

#[test]
fn test_admin_claim_funds_after_end_time() {
    let (erc20, erc721, erc721_custom, refund) = deploy_contract();
    let admin = starknet::contract_address_const::<0x123>();
    let normal_user = starknet::contract_address_const::<0x456>();
    set_contract_address(admin);
    erc20.transfer(normal_user, 1);
    set_contract_address(normal_user);
    // before the refund
    set_block_timestamp(500);

    let price = 1;
    let nft_id = 1;
    erc20.approve(refund.contract_address, price);
    erc721_custom.mint(nft_id);

    set_block_timestamp(1500);
    set_contract_address(admin);
    let prev_admin_balance = erc20.balance_of(admin);
    refund.admin_claim_funds(erc20.contract_address);
    assert(erc20.balance_of(admin) == prev_admin_balance + 1, 'Admin didn\'t claim correctly')
}

#[test]
#[should_panic(expected: ('The refund period has not ended', 'ENTRYPOINT_FAILED'))]
fn test_admin_claim_funds_before_end_time() {
    let (erc20, erc721, erc721_custom, refund) = deploy_contract();
    let admin = starknet::contract_address_const::<0x123>();
    let normal_user = starknet::contract_address_const::<0x456>();
    set_contract_address(admin);
    erc20.transfer(normal_user, 1);
    set_contract_address(normal_user);
    // before the refund
    set_block_timestamp(500);

    let price = 1;
    let nft_id = 1;
    erc20.approve(refund.contract_address, price);
    erc721_custom.mint(nft_id);

    set_contract_address(admin);
    let prev_admin_balance = erc20.balance_of(admin);
    refund.admin_claim_funds(erc20.contract_address);
    assert(erc20.balance_of(admin) == prev_admin_balance + 1, 'Admin didn\'t claim correctly')
}
