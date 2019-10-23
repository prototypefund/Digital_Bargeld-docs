GNU Taler NFC Guide
###################

This guide explains how NFC (near-field communication) is
used in the GNU Taler payment system.

Introduction
============

NFC is currently used for two different purposes:

1. Operations in the wallet (payment, withdrawal, ...) can be triggered by a
   merchant PoS (Point-of-Sale) terminal or Taler-capable ATM.
2. When either the wallet or the merchant do not have Internet connectivity,
   the protocol messages to the exchange or merchant backend service can be
   tunneled via NFC through the party that has Internet connectivity.


Background: Payment Processing with GNU Taler
=============================================

The following steps show a simple payment process with GNU Taler.  Examples are
written in `Bash <https://www.gnu.org/software/bash/>`_ syntax,
using `curl <https://curl.haxx.se/docs/manpage.html>`_ to make HTTP(S) requests.


1. The merchant creates an *order*, which contains the details of the payment
   and the product/service that the customer will receive.
   An order is identified by an alphanumeric *order ID*.

   The *fulfillment URL* is an URL that the wallet will redirect the customer
   to once the payment is complete.  For digital products, this is typically an
   ``https(s)://`` URL that renders the purchased content.  For physical
   products and in-store purchases, a ``taler://fulfillment-success/<message>``
   URL should be specified instead.  The wallet will display the URL-encoded
   UTF-8 text ``<message>`` when the payment has succeeded.

   .. hint::

     When an ``http(s)://`` URL is used as the fulfillment URL in an in-store / NFC payment,
     the user might not be able to view the page, as request tunneling only works for requests
     made by the wallet to the merchant backend / exchange.

     In these situations, wallets should display to the user that a page to view the purchase
     can be opened, and give a warning if it is detected that the devices does not have Internet
     connectivity.

   The following :http:post:`/order` request to the merchant backend creates a
   simple order:

   .. code-block:: sh

    $ backend_base_url=https://backend.demo.taler.net/
    $ auth_header='Authorization: ApiKey sandbox'
    $ order_req=$(cat <<EOF
      {
        "order": {
          "summary": "one ice cream",
          "amount": "KUDOS:1.5",
          "fulfillment_url":
            "taler://fulfillment-success/Enjoy+your+ice+cream!"
       }
      }
    EOF
    )
    $ curl -XPOST -H"$auth_header" -d "$order_req" "$backend_base_url"/order
    {
      "order_id": "2019.255-02YDHMXCBQP6J"
    }

2. The merchant checks the payment status of the order using
   :http:get:`/check-payment`:

   .. code-block:: sh

     $ backend_base_url=https://backend.demo.taler.net/
     $ auth_header='Authorization: ApiKey sandbox'
     $ curl -XGET -H"$auth_header" \
        "$backend_base_url/check-payment?order_id=2019.255-02YDHMXCBQP6J"
     # Response:
     {
       "taler_pay_uri": "taler://pay/backend.demo.taler.net/-/-/2019.255-02YDHMXCBQP6J",
       "paid": false,
       # ... (some fields omitted)
     }

   As expected, the order is not paid.  To actually proceed with the payment, the value of ``taler_pay_uri``
   must be processed by the customer's wallet.  There are multiple ways for the wallet to obtain the ``taler://pay/`` URI

   * in a QR code
   * in the ``Taler:`` HTTP header of a Web site
   * by manually entering it in the command-line wallet
   * **via NFC** (explained in this guide)

   The details of ``taler://`` URIs are specified :ref:`here <taler-uri-scheme>`.

3. The wallet processes the ``taler://pay/`` URI.  In this example, we use the
   command-line wallet:

   .. code-block:: sh

     # Withdraw some toy money (KUDOS) from the demo bank
     $ taler-wallet-cli test-withdraw \
       -e https://exchange.demo.taler.net/ \
       -b https://bank.demo.taler.net/ \
       -a KUDOS:10
     # Pay for the order from the merchant.
     $ taler-wallet-cli pay-uri 'taler://pay/backend.demo.taler.net/-/-/2019.255-02YDHMXCBQP6J'
     # [... User is asked to confirm the payment ...]

   .. hint::

     The command-line wallet is typically used by developers and not by end-users.
     See the :ref:`wallet manual <command-line-wallet>` for installation instructions.


4. The merchant checks the payment status again:

   .. code-block:: sh

     $ backend_base_url=https://backend.demo.taler.net/
     $ auth_header='Authorization: ApiKey sandbox'
     $ curl -XGET -H"$auth_header" \
        "$backend_base_url/check-payment?order_id=2019.255-02YDHMXCBQP6J"
     # Response:
     {
       "paid": true,
       # ... (some fields omitted)
     }

   .. note::

     When paying for digital products displayed on a Web site identified by the
     fulfillment URL, the merchant only needs to check the payment status
     before responding with the fulfillment page.

     For in-store payments, the merchant must periodically check the payment status.
     Instead of polling in a busy loop, the ``long_poll_ms`` parameter of :http:get:`/check-payment`
     should be used.


Taler NFC Basics
================

The NFC communication in GNU Taler follows the ISO-DEP (`ISO 14443-4
<https://www.iso.org/standard/73599.html>`_) standard.  The wallet always acts
as a tag (or more precisely, emulated card), while the merchant PoS terminal
and bank terminal act as a reader.

The basic communication unit is the application protocol data unit (`APDU
<https://en.wikipedia.org/wiki/Smart_card_application_protocol_data_unit>`_), with the structure
and commands defined in `ISO 7816 <https://cardwerk.com/iso-7816-smart-card-standard>`_.

The GNU Taler wallet uses the AID (application identifier) ``F00054414c4552``.
The ``F`` prefix indicates the proprietary/unregistered namespace of AIDs, and
the rest of the identifier is the hex-encoded ASCII-string ``TALER`` (with one
0-byte left padding).

During the time that the wallet is paired with a reader, there is state
associated with the communication channel. Most importantly, the first message
sent by the reader to the wallet must be a ``SELECT FILE (=0xA4)`` that selects
the GNU Taler AID.  Messages that are sent before the correct ``SELECT FILE``
message results in implementation-defined behavior, such as the tag disconnecting,
ignoring the message or an app other than the wallet receiving the message.

The reader sends commands to the wallet with the ``PUT DATA (=0xDA)``
instruction, using the instruction parameters ``0x0100``, denoting a
proprietary instruction.

The command data of the ``PUT DATA`` APDU is prefixed by a one-byte Taler
instruction ID (TID).  Currently, the following TIDs are used:

.. list-table::
  :widths: 5 50
  :header-rows: 1

  * - TID (reader to wallet)
    - Description
  * - ``0x01``
    - Dereference the UTF-8 encoded ``taler://`` URI in the remainder of the command data.
  * - ``0x02``
    - Accept the UTF-8 encoded JSON object in the remainder of the command data as a request tunneling response.


The ``GET DATA (=0xCA)`` instruction (again with the instruction parameters
``0x0100`` is used to request a command from the wallet.  The APDU with this
instruction must be sent with a ``0x0000`` trailer to indicate that up to 65536
bytes of data are expected in the response from the wallet.  Note that the
wallet itself cannot initiate communication, and thus the reader must "poll"
the wallet for commands.

The response to the ``GET DATA`` instruction has a Taler instruction ID in the
first byte.  The rest of the
body is interpreted depending on the TID.

.. list-table::
  :widths: 15 50
  :header-rows: 1

  * - TID
      (wallet to reader)
    - Description
  * - ``0x03``
    - Accept the UTF-8 encoded JSON object in the remainder of the command data as a request tunneling request.


Sending taler:// URIs to the Wallet via NFC
===========================================

To make the wallet process a ``taler://`` URI via NFC, the merchant PoS
terminal sends a ``SELECT FILE`` command with the GNU Taler AID, and a ``PUT
DATA`` command with TID ``0x01`` and the URI in the rest
of the command data.

Here is an example protocol trace from an interaction which caused the wallet
to dereference the ``taler://pay`` URI from the example above:

.. code-block:: none

  # SELECT FILE
  m->w 00A4040007F00054414c4552
  # success response with no data
  m<-w 9000

  # PUT DATA (TID=0x01)
  m->w 00DA01007c0174616c65723a2f2f7061792f6261636b656e642e64656d6f2e74
       616c65722e6e65742f2d2f2d2f323031392e3235352d30325944484d58434251
       50364a
  # success response with no data
  m<-w 9000

(Note that this process works analogously for communication between a bank/ATM
terminal or "tipping provider".)


Request tunneling
=================

Request tunneling allows tunneling a (very) restricted subset of HTTP through
NFC. In particular, only JSON request and response bodies are allowed.

It is currently assumed that the requests and responses fit into one APDU frame.
For devices with more limited maximum APDU sizes, additional TIDs for segmented
tunnel requests/responsed may be defined in the future.

A request for tunneling is initiated with TID ``0x03`` and responded to with
TID ``0x02`` (see tables above).  A tunneling request is identified by a
numeric ID, which must be unique during one pairing between reader and tag.

The request tunneling request/response JSON messages have the following schema:

.. code-block:: tsref

  interface TalerRequestTunnelRequest {
    // Identifier for the request
    id: number;

    // Request URL
    url: string;

    // HTTP method to use
    method: "post" | "get";

    // Request headers
    headers?: { [name: string]: string };

    // JSON body for the request, only applicable to POST requests
    body?: object;
  }

  interface TalerRequestTunnelResponse {
    // Identifier for the request
    id: number;

    // Response HTTP status code,
    // "0" if there was no response.
    status: number;

    // JSON body of the response, or undefined
    // if the response wasn't JSON.
    // May contain error details if 'status==0'
    body?: object;
  }

