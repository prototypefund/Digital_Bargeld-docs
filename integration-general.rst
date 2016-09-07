.. _integration-general:

================================
Taler Wallet Website Integration
================================

.. note::
 The wallet-Websites communication is switching to a new policy which
 is NOT based on DOM events, therefore obsoleting this page. To be soon
 documented.


Websites (such as banks and online shops) can communicate with
the Taler wallet by a standardized protocol.

From a technical perspective, the Taller wallet communicates with
the website by sending and receiving `DOM events <http://www.w3.org/TR/DOM-Level-3-Events/>`_
on the bank website's ``HTMLDocument``.

DOM events used by Taler have the prefix ``taler-``.

-------------------------
Wallet Presence Awareness
-------------------------

The bank website queries the wallet's presence by sending a ``taler-probe`` event. The
event data should be `null`.

If the wallet is present and active, it will respond with a ``taler-wallet-present`` event.

While the user agent is displaying a website, the user might deactivate or
re-activate the wallet.  A Taler-aware *should* react to those events, and
indicate to the user that they should (re-)enable the wallet if necessary.

When the wallet is activated, the ``taler-wallet-load`` event is sent
by the wallet.  When the wallet is deactivated, the ``taler-wallet-unload`` event
is sent by the wallet.

.. _communication:

----------------------
Communication Example
----------------------

The bank website can send the event ``taler-XYZ`` with the event data ``eventData``
to the wallet with the following JavaScript code:

.. sourcecode:: javascript

  const myEvent = new CustomEvent("taler-XYZ", eventData);
  document.dispatchEvent(myEvent);

Events can be received by installing a listener:


.. sourcecode:: javascript

  function myListener(talerEvent) {
    // handle event here!
  }
  document.addEventListener("taler-XYZ", myListener);


--------------------
Normalized Base URLs
--------------------

Exchanges and merchants have a base URL for their service.  This URL *must* be in a
canonical form when it is stored (e.g. in the wallet's database) or transmitted
(e.g. to a bank page).

1. The URL must be absolute.  This implies that the URL has a schema.
2. The path component of the URL must end with a slash.
3. The URL must not contain a fragment or query.

When a user enters a URL that is, technically, relative (such as "alice.example.com/exchange"), wallets
*may* transform it into a canonical base URL ("http://alice.example.com/exchange/").  Other components *should not* accept
URLs that are not canonical.

Rationale:  Joining non-canonical URLs with relative URLs (e.g. "exchange.example.com" with "reserve/status") 
results in different and slightly unexpected behavior in some URL handling libraries.
Canonical URLs give more predictable results with standard URL joining.
