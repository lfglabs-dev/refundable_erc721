# RefundableERC721 StarkNet Smart Contract

## Overview

The `RefundableERC721` smart contract is designed for the StarkNet ecosystem, leveraging OpenZeppelin's ERC721 and ERC20 token standards. It provides a unique mechanism allowing users to claim refunds for ERC721 tokens (NFTs) within a specified timeframe. The contract handles payments in ERC20 and stores the received tokens until a specific timestamp. Before that timestamp, any payment can be refunded by allowing this contract to take your NFT. After that timestamp, the configured admin can claim the funds on his wallet. The admin serves no other purpose than receiving the NFTs and claiming the funds, especially, it can't upgrade the contract.

## Key Features

- **NFT Payment Registration**: Registers the payment associated with an NFT, ensuring that only the designated NFT contract can initiate payments.
- **Claim Refunds**: Allows NFT owners to claim refunds within a predetermined period, transferring the NFT back to the admin and the corresponding funds back to the owner.
- **Admin Fund Withdrawal**: Enables the admin to withdraw funds after the refund period has ended.
- **Query Functions**: Provides functions to retrieve the claimable amount for an NFT and the address of the NFT contract.
