Design Doc 001: New Browser Integration
#######################################

.. note::

  This design document is currently a draft, it
  does not reflect any implementation decisions yet.

Summary
=======

A new and improved mechanism for the integration of GNU Taler wallets with web
browsers is proposed.  The mechanism is meant for browsers that support the
WebExtension API, but do not have native support for GNU Taler.

The new approach allows the wallet extension to be installed without
excessive, "scary" permissions, while being simpler and still flexible.


Motivation
==========

The current browser integration of the GNU Taler wallet relies heavily being
able to hook into various browser mechanisms via the following mechanisms:

* A blocking ``webRequest`` handler that is run for every request the browser
  makes, and looks at the status code and the presence of a "``Taler:``" HTTP header.
* A content script that's injected on every (!) page, which injects CSS (for
  wallet presence detection) and JavaScript listeners into the page.  The
  injection is opt-in via a "data-taler" tag on the root html element.

This has multiple problems:

* It requires excessive permissions on **all** Websites.  This is scary for us (in case we mess up)
  and for users.  It also slows down the publication of the extension on extension stores.
* We have not measured the performance implications, but our JavaScript code is executed for every
  single request the browser is making.
* The CSS-based wallet detection integration is not very flexible.  Only being able
  to show/hide some element when the wallet is detected / not detected might not be
  the optimal thing to do when we now have mobile wallets.


Requirements
============

* The new browser integration should require as few permissions as possible.
  In particular, the wallet may not require "broad host" permissions.
* Fingerprinting via this API should be minimized.
* It must be possible for Websites to interact with the wallet without using JavaScript.
* Single Page Apps (using JavaScript) should be able to interact the wallet without
  requiring a browser navigation.


Proposed Solution
=================

We first have to accept the fundamental limitation that a WebExtension is not
able to read a page's HTTP request headers without intrusive permissions.
Instead, we need to rely on the content and/or URL of the fallback page that is
being rendered by the merchant backend.

To be compatible with mobile wallets, merchants and banks **must** always render a fallback
page that includes the same ``taler://`` URI.

Manual Triggering
-----------------

Using the only the ``activeTab`` permission, we can access a page's content
*while and only while* the user is opening the popup (or a page action).
The extension should look at the DOM and search for ``taler://`` links.
If such a link as been found, the popup should display an appropriate
dialog to the user (e.g. "Pay with GNU Taler on the current page.").

Using manual triggering is not the best user experience, but works on every Website
that displays a ``taler://`` link.

.. note::

  Using additional permissions, we could also offer:

  * A context ("right click") menu for ``taler://pay`` links
  * A declarative pageAction, i.e. an additional clickable icon that shows up
    on the right side of the address bar.  Clicking it would lead to directly
    processing the ``taler://`` link.

  It's not clear if this improves the user experience though.


Fragment-based Triggering
-------------------------

This mechanism improves the user experience, but requires extra support from merchants
and broader permissions, namely the ``tabs`` permission.  This permission
is shown as "can read your history", which sounds relatively intrusive.
We might decide to make this mechanism opt-in.

The extension uses the ``tabs`` permission to listen to changes to the
URL displayed in the currently active tab.  It then parses the fragment,
which can contain a ``taler://`` URI, such as:

.. code:: none

  https://shop.taler.net/checkout#taler://pay/backend.shop.taler.net/-/-/2020.099-03C5F644XCNMR

The fragment is processed the same way a "Taler: " header is processed.
For examle, a ``taler://pay/...`` fragment navigates to an in-wallet page
and shows a payment request to the user.


Fragment-based detection
------------------------

To support fragment-based detection of the wallet, a special
``taler://check-presence/${redir}`` URL can be used to cause a navigation to
``${redir}`` if the wallet is installed.  The redirect URL can be absolute or
relative to the current page and can contain a fragment.

For example:

.. code:: none

  https://shop.taler.net/checkout#taler://check-presence/taler-installed

  -> (when wallet installed)

  https://shop.taler.net/taler-installed


To preserve correct browser history navigation, the wallet does not initiate the redirect if
the tab's URL changes from ``${redir}`` back to the page with the ``check-presence`` fragment.


Asynchronous API
----------------

The fragment-based triggering does not work well on single-page apps: It
interferes with the SPA's routing, as it requires a change to the navigation
location's fragment.

The only way to communicate with a WebExtension is by knowing its extension ID.
However, we want to allow users to build their own version of the WebExtension,
and extensions are assigned different IDs in different browsers.  We thus need
a mechanism to obtain the wallet extension ID in order to asynchronously communicate
with it.

To allow the Website to obtain this extension ID, we can extend the redirection URL
of the ``taler://check-presence`` fragment to allow a placeholder for the extension ID.

.. code:: none

  https://shop.taler.net/checkout#taler://check-presence/#taler-installed-${extid}

  -> (when wallet installed)

  https://shop.taler.net/checkout#taler-installed-12345ASDFG

.. warning::

  This allows fingerprinting, and thus should be an opt-in feature.
  The wallet could also ask the user every time to allow a page to obtain the

.. note::

  To avoid navigating away from an SPA to find out the extension ID, the SPA
  can open a new tab/window and communicate the updated extension ID back to
  original SPA page.

Once the Website has obtained the extension ID, it can use the ``runtime.connect()`` function
to establish a communication channel to the extension.


Alternatives
============

* manual copy&paste of ``taler://`` URIs :-)
* integration of GNU Taler into all major browsers :-)
* convincing Google and/or Mozilla to provide better support
  for reacting to a limited subset of request headers in
  a declarative way
* convince Google and/or Mozilla to implement a general mechanism
  where extensions can offer a "service" that websites can then
  connect to without knowing some particular extension ID.
* convince Google and/or Mozilla to add better support for
  registering URI schemes from a WebExtension

Drawbacks
=========

* Firefox currently does not support messages from a website to an extension, and currently
  cannot support the asynchronous wallet API.
  There is a bug open for this issue: https://bugzilla.mozilla.org/show_bug.cgi?id=1319168
