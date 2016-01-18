==================================
Interaction with merchant websites
==================================

-------------
Purchase Flow
-------------

The purchase flow consists of the following steps:

1. UA visits merchant's checkout page
2. The merchant's checkout page notifies the wallet
   of the contract (``taler-deliver-contract``)
3. The user reviews the contract inside the wallet
4. The wallet directs the UA to the payment execution page (``taler-execute-contract``)

The *execution page* allows the wallet to make a request
to the merchant from the store's domain.


