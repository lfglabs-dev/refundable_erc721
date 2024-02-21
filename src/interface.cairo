use starknet::ContractAddress;

#[starknet::interface]
trait IRefundable<TContractState> {
    fn register_payment(
        ref self: TContractState, nft_id: u256, buyer: ContractAddress, price: u256
    );

    fn claim_refund(ref self: TContractState, nft_id: u256);

    fn admin_claim_funds(ref self: TContractState, erc20: ContractAddress);

    fn get_claimable(self: @TContractState, nft_id: u256) -> u256;

    fn get_nft_contract(self: @TContractState) -> ContractAddress;
}
