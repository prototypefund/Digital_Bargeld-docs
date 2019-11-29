Errors and Testing
##################

This page lists errors that occur during the operation of GNU Taler.


Error Conditions
================

``EXCHANGE_KEYS_INFO_UNAVAILABLE``
  An exchange does not return an HTTP 200 response for the ``/keys`` request.

``EXCHANGE_KEYS_INFO_MALFORMED``
  The exchange returned an HTTP 200 response, but the body
  did not confirm the schema for ``/keys``.

``EXCHANGE_KEYS_INFO_OUTDATED``
  The exchange returned a response for ``/keys`` with an issuing date
  earlier than the previous one.

  **Type**: Warning
  **Handling**:  The wallet should ignore the response and try again later.

``EXCHANGE_WIRE_INFO_UNAVAILABLE``
  An exchange does not return an HTTP 200 response for the ``/wire`` request.

``EXCHANGE_WIRE_INFO_MALFORMED``
  The exchange returned an HTTP 200 response, but the body
  did not confirm the schema for ``/wire``.

``EXCHANGE_PROTOCOL_VERSION_UNSUPPORTED``
  An exchanges ``/keys`` response indicates a version number that
  is not compatible with the client.

``EXCHANGE_MASTER_PUB_CHANGED``
  An exchange returns a /keys response with a master public key that differs
  from a previous response.

``EXCHANGE_DENOM_MISSING``
  A denomination that has been previously offered by the exchange is not offered anymore,
  even though it hasn't expired yet.

``EXCHANGE_DENOM_SIGNATURE_INVALID``
  The signature by the exchange's master key on a denomination is invalid.

``EXCHANGE_DENOM_CHANGED``
  A denomination offered by the exchange is valid (syntax, content, signature),
  but has different information (fees, expiry) for the same public key compared
  to a previous keys response.

``EXCHANGE_DENOM_CONTENT_INVALID``
  A denomination offered by the exchange is syntactically correct, but
  semantically malformed.  For example, the expiration dates are not in the
  correct temporal order or the denomination public key can't be decoded.

``EXCHANGE_WIRE_FEE_SIGNATURE_INVALID``
  The signature by the exchange's master key on a wire fee is invalid.

``EXCHANGE_DENOMS_INADEQUATE``
  The denominations currently offered are inadequate for withdrawing digital cash.
  This can happen when all offered denominations are past their withdrawal expiry date.

``EXCHANGE_RESERVE_STATUS_UNAVAILABLE``

``WALLET_BUG``
  The wallet encountered a programming bug that should be reported to the developers.

  **Handling**:  The wallet should allow the user to report this bug to the wallet developers.


End-To-End Testing Scenarios
============================

This section describes some advanced end-to-end testing scenarios that should
eventually be covered by our tests.

* Reserve is created, closed, and then money is sent again to the reserve

* Amount from payback should end up in customer's account again
