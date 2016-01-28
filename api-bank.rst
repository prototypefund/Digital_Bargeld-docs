=========
Bank API
=========

The following APIs are served from banks, in order to allow mints to
deposit funds to money recipients.  A typical scenario for calling this
APIs is after a merchant has deposited coins to the mint, and the mint
needs to give real money to the merchant.

------------------
Administrative API
------------------

This is `local` API, meant to make the bank communicate with trusted entities,
namely mints.

.. _bank-deposit:
.. http:post:: /admin/add/incoming

**Request:** The body of this request must have the format of a `BankDepositRequest`_.

**Response:**

:status 200 OK: The request has been correctly handled, so the funds have been transferred to
the recipient's account
**Details:**

  .. _BankDepositRequest:
  .. code-block:: tsref

    interface BankDepositRequest {
      
      // JSON 'amount' object. The amount the caller wants to transfer
      // to the recipient's count
      amount: Amount;

      // The id of this wire transfer
      wid: base32; 

      // The recipient's account identificator
      account: number;
    
    }
