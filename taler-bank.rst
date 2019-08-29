The GNU Taler bank manual
#########################

Introduction
============

About GNU Taler
---------------

GNU Taler is an open protocol for an electronic payment system with a
free software reference implementation. GNU Taler offers secure, fast
and easy payment processing using well understood cryptographic
techniques. GNU Taler allows customers to remain anonymous, while
ensuring that merchants can be held accountable by governments. Hence,
GNU Taler is compatible with anti-money-laundering (AML) and
know-your-customer (KYC) regulation, as well as data protection
regulation (such as GDPR).

About this manual
-----------------

This manual documents how the demonstrator bank interoperates with the
other GNU Taler components. The demonstrator bank implements a simple
closed banking system for the purpose of illustrating how GNU Taler
works in the Taler demo. It could also be used as a starting point for a
local/regional currency. Finally, “real” banks might use it as a
reference implementation for a tight integration with the GNU Taler
wallet.

.. _Reference:

Reference
=========

.. _Bank_002dWallet-interaction:

Bank-Wallet interaction
-----------------------

The HTTP status code ``202 Accepted`` can be used by the bank website to
trigger operations in the user agent. The operation is determined by the
``X-Taler-Operation`` header. The following operations are understood:

``create-reserve``
   Ask the Taler wallet to create a reserve and call back the bank with
   the reserve public key. The following headers are mandatory:

   -  ``X-Taler-Callback-Url``: URL that the wallet will visit when the
      reserve was created and the user has selected an exchange.

   -  ``X-Taler-Wt-Types``: JSON-encoded array of wire transfer types
      that this bank supports.

   -  ``X-Taler-Amount``: The amount that will be transferred to the
      reserve.

   -  ``X-Taler-Sender-Wire``: JSON-encoded wire account details of the
      sender, that is the user that is currently logged in with the bank
      and creates the reserve.

   The following header is optional:

   -  ``X-Taler-Suggested-Exchange``: Exchange that the bank recommends
      the customer to use. Note that this is a suggestion and can be
      ignored by the wallet or changed by the user.

   On successful reserve creation, the wallet will navigate to the
   callback URL (effectively requesting it with a GET) with the
   following additional request parameters:

   -  ``exchange``: The URL of the exchange selected by the user

   -  ``wire_details``: The wire details of the exchange.

   -  ``reserve_pub``: The reserve public key that the bank should
      transmit to the exchange when transmitting the funds.

``confirm-reserve``
   To secure the operation, the (demo) bank then shows a "CAPTCHA page"
   – a real bank would instead show some PIN entry dialog or similar
   security method – where the customer can finally prove she their
   identity and thereby confirm the withdraw operation to the bank.

   Afterwards, the bank needs to confirm to the wallet that the user
   completed the required steps to transfer funds to an exchange to
   establish the reserve identified by the ``X-Taler-Reserve-Pub``
   header.

   This does not guarantee that the reserve is already created at the
   exchange (since the actual money transfer might be executed
   asynchronously), but it informs that wallet that it can start polling
   for the reserve.

.. _Bank_002dExchange-interaction:

Bank-Exchange interaction
-------------------------

The interaction between a bank and the exchange happens in two
situations: when a wallet withdraws coins, and when the exchange pays a
merchant.

Withdraw
~~~~~~~~

Once a withdrawal operation with the wallet has been confirmed, the the
bank must wire transfer the withdrawn amount from the customer account
to the exchange’s. After this operation is done, the exchange needs to
be informed so that it will create the reserve.

For the moment, the bank will use the exchange’s ``/admin/add/incoming``
API, providing those arguments it got along the ``X-Taler-Callback-Url``
URL. (In the future, the exchange will poll for this information.)
However, the bank will define two additional values for this API:
``execution_date`` (a operation’s timestamp), and ``transfer_details``
(just a "seed" to make unique the operation). See
https://docs.taler.net/api/api-exchange.html#administrative-api-bank-transactions.

The polling mechanism is possbile thanks to the ``/history`` API
provided by the bank. The exchange will periodically use this API to see
if it has received new wire transfers; upon receiving a new wire
transfer, the exchange will automatically create a reserve and allow the
money sender to withdraw.

``GET /history``
   Ask the bank to return a list of money transactions related to a
   caller’s bank account.

   -  ``auth`` a string indicating the authentication method to use;
      only ``"basic"`` value is accepted so far. The username and
      password credentials have to be sent along the HTTP request
      headers. Namely, the bank will look for the following two headers:
      ``X-Taler-Bank-Username`` and ``X-Taler-Bank-Password``, which
      will contain those plain text credentials.

   -  ``delta`` returns the first ``N`` records younger (older) than
      ``start`` if ``+N`` (``-N``) is specified.

   -  ``start`` according to delta, only those records with row id
      strictly greater (lesser) than start will be returned. This
      argument is optional; if not given, delta youngest records will be
      returned.

   -  ``direction`` optional argument taking values debit or credit,
      according to the caller willing to receive both incoming and
      outgoing, only outgoing, or only incoming records

   -  ``account_number`` optional argument indicating the bank account
      number whose history is to be returned. If not given, then the
      history of the calling user will be returned

Exchange pays merchant
~~~~~~~~~~~~~~~~~~~~~~

To allow the exchange to send payments to a merchant, the bank exposes
the ``/admin/add/incoming`` API to exchanges.

``POST /admin/add/incoming``
   Ask the bank to transfer money from the caller’s account to the
   receiver’s.

   -  ``auth`` a string indicating the authentication method to use;
      only ``"basic"`` value is accepted so far. The username and
      password credentials have to be sent along the HTTP request
      headers. Namely, the bank will look for the following two headers:
      ``X-Taler-Bank-Username`` and ``X-Taler-Bank-Password``, which
      will contain those plain text credentials.

   -  ``amount`` a JSON object complying to the Taler amounts layout.
      Namely, this object must contain the following fields: ``value``
      (number), ``fraction`` (number), and ``currency`` (string).

   -  ``exchange_url`` a string indicating the calling exchange base
      URL. The bank will use this value to define wire transfers subject
      lines.

   -  ``wtid`` a alphanumeric string that uniquely identifies this
      transfer at the exchange database. The bank will use this value
      too to define wire transfers subject lines. Namely, subject lines
      will have the following format: ``'wtid exchange_url'``.

   -  ``debit_account`` number indicating the exchange bank account.
      NOTE: this field is currently ignored, as the bank can retrieve
      the exchange account number from the login credentials. However,
      in future release, an exchange could have multiple account at the
      same bank, thereby it will have the chance to specify any of them
      in this field.

   -  ``credit_account`` bank account number that will receive the
      transfer. Tipically the merchant account number.
