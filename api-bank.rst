=========
Banks API
=========

The following APIs are served from banks, in order to allow mints to
deposit funds to money recipients.  A typical scenario for calling this
APIs is after a merchant has deposited coins to the mint, and the mint
needs to give real money to the merchant.

--------
Test API
--------

This API is useful for testing purposes, as no real money will be
involved.

.. _bank-deposit:
.. http:post:: /admin/add/incoming

**Request:** The body of this request must have the format of a `BankDepositRequest`_.

**Response:**

:status 200: The request has been correctly handled, so the funds have been transferred to the merchant's account
**Details:**

  .. _BankDepositRequest:
  .. code-block:: tsref

    interface BankDepositRequest {
      
      // JSON 'amount' object. The amount the caller wants to transfer
      // to the recipient's count
      f: Amount;

      // The transaction id (meant as in 'Taler transaction id') according
      // to which the caller is now giving money to the recipient. That way,
      // the recipient can link inwards money to commercial activity.
      tid: number; 

      // The recipient's account identificator. For this testing purpose, the
      // account format will the normal IBAN format having the token "TEST"
      // in place of the country code and having the check digit removed. For instance,
      // if "SA03 8000 0000 6080 1016 7519" were a valid Saudi Arabian IBAN, then
      // "TEST 8000 0000 6080 1016 7519" would be a correct test account number as well.
      account: string;
    
    }
