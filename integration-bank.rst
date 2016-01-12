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

--------------
Presence Query
--------------

The bank website queries the wallet's presence by sending a ``taler-wire-probe`` event. The
event data should be `null`.

If the wallet is present and active, it will respond with a ``taler-wallet-present`` event.

-------------------
Change Notification
-------------------

While the user agent is displaying a bank website, the user might deactivate or
re-activate the wallet.  A bank website *should* react to those events, and
indicate to the user that they should (re-)enable if necessary.

When the wallet is activated, the ``taler-wallet-load`` event is sent
by the wallet.  When the wallet is deactivated, the ``taler-wallet-unload`` event
is sent by the wallet.

-------------------------
Reserve Creation Request
-------------------------

The bank website can request the creation of a :term:`reserve`.  Note that the
user will always be prompted by the wallet before a reserve is created in the
wallet.

As a result of the reserve creation request, the following steps will happen insequence:
 1. The wallet will prompt the user for the *mint base URL* and ask the user to
    confirm creating the reserve.
 2. The wallet will create a key pair for the reserve.
 3. The wallet will make a request to the bank, containing
    the reserve's public key and the mint base URL chosen by the user

The bank should then take steps that will establish the reserve at the
customer's requested mint.  This could, depending on the bank and mint, either
be a SEPA wire transfer or some other means.

In response to the reserve creation request, the Taler wallet MAY cause the
current document location to be changed, in order to navigate to a
wallet-internal confirmation page.

The bank requests reserve creation with the ``taler-create-reserve`` event.
The event data must be a JavaScript ``object`` with the following fields:

 * ``form_id``: The ``id`` of the ``form`` HTML element that contains data for the HTTP POST request
   that confirms reserve creation with the bank.
 * ``input_amount``: Amount of the reserve in the format ``N.C CUR``, where ``CUR`` is the
   currency code.
 * ``mint_rcv``: The ``id`` of the ``input`` HTML element in the reserve creation form
   that will contain mint base URL for the reserve
 * ``input_pub``: The ``id`` of the ``input`` HTML element in the reserve creation form
   that will contain the reserve's public key.

Note that the bank website MUST contain an HTML form with the data required for the request and
input fields for receiving data from the mint.
