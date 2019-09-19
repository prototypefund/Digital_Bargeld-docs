LibEuFin Architecture
#####################

Sandbox
=======

* the sandbox's EBICS API emulates the behavior of a real bank's EBICS
  interface

* *(Only in the future)*:  FinTS API and other FinTech APIs

* the sandbox's management API allows an administrator to:

  * create new **bank** accounts
  * create new **EBICS subscriber** accounts

    * a subscriber has (optionally?) a SystemID (for technical subscribers),
      a UserID and a PartnerID
    * each bank account has a list of subscribers than can access it

  * delete accounts
  * ...

* the sandbox's "miscellaneous" API provides public functionality that is not covered
  directly by EBICS, such as:

  * a way to get the transactions in form of a JSON message, to check if it matches the EBICS response

    * you could call it a "reference history"

  * publicly accessible key management functionality, for example for the EBICS INI process

    * this is the "electronic version" of sending an HIA/INI letter

* things that we do **not** want to implement right now:

  * Distributed electronic signatures.  For now, it is enough for every order
    to be signed just by one authorized subscriber.

Nexus
=====

The Nexus takes JSON requests and translates them into API calls for the
respective real bank accounts (EBICS, FinTS, ...).  It also stores the bank
transaction history to enable a linearlized view on the transaction history
with unique transaction identifier, which some of the underlying banking APIs
don't provide directly.

``libeufin-nexus-httpd`` is the binary (or wrapper around the Java invocation)
that runs the HTTP service.


CLI Tools
=========

The Sandbox and Nexus are only HTTP services.  The CLI tools are used to
actually access them.

