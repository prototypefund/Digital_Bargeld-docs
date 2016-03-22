==================================
Interaction with merchant websites
==================================

-------------
Purchase Flow
-------------

The purchase flow consists of the following steps:

1. UA visits merchant's checkout page
2. The merchant's checkout page notifies the wallet
   of the contract (``taler-deliver-contract``).
3. The user reviews the contract inside the wallet
4. The wallet directs the UA to the payment execution page
5. The execution page must send the event ``taler-execute-payment`` with
   the contract hash of the payment to be executed.
6. The wallet executes the payment in the domain context of the
   execution page and emits the ``taler-payment-result`` event
   on the execution page.
7. The execution page reacts to the payment result (which
   is either successful or unsuccessful) by showing
   an appropriate response to the user.

----------------
Event Reference
----------------

.. topic:: ``taler-deliver-contract``

  The event takes an :ref:`offer <offer>` as event detail.

.. topic:: ``taler-execute-payment``

  The event takes `H_contract` of a :ref:`Contract <tsref-type-Contract>` as event detail.

.. topic:: ``taler-payment-result``

  The event takes the following object as event detail:

  .. code-block:: tsref

    {
      // was the payment successful?
      success: boolean;

      // human-readable indication of what went wrong
      hint: string;
    }
   


----------------
Payment protocol
----------------

The events descripted below get triggered when the user confirms its
purchase on a checkout page, or when by visiting some merchant's resource
that needs a payment to be visualized.  We call this situation `IIG` (Interest
In some Good).  There are two kinds of URL that let a merchant know when
IIG occurs, they are

* offering URLs
* fulfillment URLs

Generally, offering URLs' purpose is to send Taler-type contracts to the user, whereas
fulfillment URLs can be used both by wallets to send coins for a payment or by users to
access a payed resource multiple times.  In other words, fulfillment URLs are bookmarkable
and shareable.  There is no hard separation between physical and virtual resources since
the receipt for a physical resource plays the same role of a 100% virtual resource like a
blog article.  In other words, when seeing a pay-per-view blog article on his screen, then
the user has payed for the article; on the other end, when seeing an electronic receipt of
a physical good on his screen, the user will receive it by mail.

IIG triggers different flows according to the user visiting an offering or a fulfillment
URL. For clarity, below are listed the steps taken when the user visits an offering URL.

1. The merchant sends the following object embedded in a `taler-confirm-contract` event

  .. code-block:: tsref

    {
      // Contract and cryptographic information
      contract_wrapper: {
        contract: :ref:`Contract <tsref-type-Contract>`;
        // base32 of the merchant's signature over this contract
        merchant_sig: string;
        // base32 of this contract's hashcode
        H_contract: string;      
      };

      // If true, the 'back-button' seen by the user when this contract is to be
      // payed will not point to this HTML, but to the previous one.
      replace_navigation: boolean
    }

2. The wallet's reaction is dual: it can either let the user pay for this contract, or
detect whether the user has already payed for this resource by looking at the `repurchase_corelation_id`
field in the contract.  In the first case, the wallet stores `H_contract` in its local database.
If there is a match, the wallet starts a IIG by visiting the fulfillment URL associated with the
already-made payment (see next section)

3. The payment is asked to the merchant by visiting the fulfillment URL (which inficated in the
Contract). Since the merchant keeps no state for any purchase, it needs relevant information
in the fulfillment URL in order to reconstruct the contract and send the payment to the backend.
This information is implicit in the mention of 'fulfillment URL'.

4. When a fulfillment URL is visited, the merchant reconstructs the contract and sends back to
the user the a `taler-execute-payment` event which embeds the following object

    .. code-block:: tsref

    {
      // base32 of the Contract's hashcode
      H_contract: string;

      // URL where to send deposit permission
      pay_url: string;

      // Used in the other IIG initiation (see next section)
      offering_url: string;
    }

5. The wallet sends the deposit permission to `pay_url`

6. If the payment is successful, then the merchant sets the state for the bought
item to `payed` and communicate the outcome to the wallet (see merchant API for
involved HTTP codes and JSONs)

7. Finally, the wallet can visit again the fulfillment URL and get the payed resource
thanks to the `payed` state
