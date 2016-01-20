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
   
