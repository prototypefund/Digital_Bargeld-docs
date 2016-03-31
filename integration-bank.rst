==============================
Interaction with bank websites
==============================

This section describes how bank websites can interact with the
Taler wallet.

Currently the following functionality is supported:
 * Querying for the presence of a Taler wallet.
 * Receiving change notifications from the Taler wallet.
 * Creating a reserve.


For JavaScript code examples, see :ref:`communication`.

-------------------------
Reserve Creation Request
-------------------------

The bank website can request the creation of a :term:`reserve`.  This operation
will require the user to specify the exchange where he wants to create the reserve
and the resolution of a CAPTCHA, before any action will be taken.

As a result of the reserve creation request, the following steps will happen in sequence:
 1. The user chooses the desired amount from the bank's form
 2. Upon confirmation, the wallet fetches the desired amount from the user-filled form and
    prompts the user for the *exchange base URL*. Then ask the user to confirm creating the
    reserve.
 2. The wallet will create a key pair for the reserve.
 3. The wallet will request the CAPTCHA page to the bank. In that request's parameters it
    communicates the desired amount, the reserve's public key and the exchange base URL to the
    bank
 4. Upon successful resolution of the CAPTCHA by the user, the bank initiates the reserve
    creation according to the gotten parameters. Together with `200 OK` status code sent back
    to the wallet, it gets also a `ReserveCreated`_ object.

Note that the reserve creation can be done by a SEPA wire transfer or some other means,
depending on the user's bank and chosen exchange.

In response to the reserve creation request, the Taler wallet MAY cause the
current document location to be changed, in order to navigate to a
wallet-internal confirmation page.

The bank requests reserve creation with the ``taler-create-reserve`` event.
The event data must be a `CreateReserveDetail`_:


.. _CreateReserveDetail:
.. code-block:: tsref

  interface CreateReserveDetail {
    
    // JSON 'amount' object. The amount the caller wants to transfer
    // to the recipient's count
    amount: Amount;

    // CAPTCHA's page URL which needs the following parameters
    // query parameters:
    // amount_value
    // amount_fraction
    // amount_currency
    // reserve_pub
    // exchange
    // type ("TEST" or "SEPA")
    // account_number (which account number has this exchange at this bank)
    callback_url: string;

    // list of wire transfer types supported by the bank
    // e.g. "SEPA", "TEST"
    wt_types: Array<string>
  }

.. _ReserveCreated:
.. code-block:: tsref

  interface ReserveCreated {

    // A URL informing the user about the succesfull outcome
    // of his operation
    redirect_url: string;  

  }
