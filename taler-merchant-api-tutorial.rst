The GNU Taler Merchant API Tutorial
###################################

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

About this tutorial
-------------------

This tutorial addresses how to process payments using the GNU Taler
merchant Backend. This chapter explains some basic concepts. In the
second chapter, you will learn how to do basic payments.

This version of the tutorial has examples for Python3. It uses the
requests library for HTTP requests. Versions for other
languages/environments are available as well.

examples
git
If you want to look at some simple, running examples, check out these:

-  The `essay
   merchant <https://git.taler.net/blog.git/tree/talerblog/blog/blog.py>`__
   that sells single chapters of a book.

-  The `donation
   page <https://git.taler.net/donations.git/tree/talerdonations/donations/donations.py>`__
   that accepts donations for software projects and gives donation
   receipts.

-  The
   `survey <https://git.taler.net/survey.git/tree/talersurvey/survey/survey.py>`__
   that gives users who answer a question a small reward.

Architecture overview
---------------------

The Taler software stack for a merchant consists of the following main
components:

-  frontend
   A frontend which interacts with the customer’s browser. The frontend
   enables the customer to build a shopping cart and place an order.
   Upon payment, it triggers the respective business logic to satisfy
   the order. This component is not included with Taler, but rather
   assumed to exist at the merchant. This tutorial describes how to
   develop a Taler frontend.

-  backend
   A Taler-specific payment backend which makes it easy for the frontend
   to process financial transactions with Taler. For this tutorial, you
   will use a public sandbox backend. For production use, you must
   either set up your own backend or ask another person to do so for
   you.

The following image illustrates the various interactions of these key
components:

|image0|

The backend provides the cryptographic protocol support, stores
Taler-specific financial information and communicates with the GNU Taler
exchange over the Internet. The frontend accesses the backend via a
RESTful API. As a result, the frontend never has to directly communicate
with the exchange, and also does not deal with sensitive data. In
particular, the merchant’s signing keys and bank account information are
encapsulated within the Taler backend.

Some functionality of the backend (the “public interface“) is also
exposed to the customer’s browser directly. In the HTTP API, all public
endpoints are prefixed with ``/public/``.

Public Sandbox Backend and Authentication
-----------------------------------------

sandbox
authorization
How the frontend authenticates to the Taler backend depends on the
configuration. See Taler Merchant Operating Manual.

The public sandbox backend https://backend.demo.taler.net/ uses an API
key in the ``Authorization`` header. The value of this header must be
``ApiKey sandbox`` for the public sandbox backend.

::

   >>> import requests
   >>> requests.get("https://backend.demo.taler.net",
   ...              headers={"Authorization": "ApiKey sandbox"})
   <Response [200]>

If an HTTP status code other than 200 is returned, something went wrong.
You should figure out what the problem is before continuing with this
tutorial.

The sandbox backend https://backend.demo.taler.net/ uses ``KUDOS`` as an
imaginary currency. Coins denominated in ``KUDOS`` can be withdrawn from
https://bank.demo.taler.net/.

Merchant Instances
------------------

instance
The same Taler merchant backend server can be used by multiple separate
merchants that are separate business entities. Each of these separate
business entities is called a *merchant instance*, and is identified by
an alphanumeric *instance id*. If the instance is omitted, the instance
id ``default`` is assumed.

The following merchant instances are configured on
https://backend.demo.taler.net/:

-  ``GNUnet`` (The GNUnet project)

-  ``FSF`` (The Free Software Foundation)

-  ``Tor`` (The Tor Project)

-  ``default`` (Kudos Inc.)

Note that these are fictional merchants used for our demonstrators and
not affiliated with or officially approved by the respective projects.

.. _Accepting-a-Simple-Payment:

Accepting a Simple Payment
==========================

Creating an Order for a Payment
-------------------------------

order
Payments in Taler revolve around an *order*, which is a machine-readable
description of the business transaction for which the payment is to be
made. Before accepting a Taler payment as a merchant you must create
such an order.

This is done by posting a JSON object to the backend’s ``/order`` API
endpoint. At least the following fields must be given:

-  amount: The amount to be paid, as a string in the format
   ``CURRENCY:DECIMAL_VALUE``, for example ``EUR:10`` for 10 Euros or
   ``KUDOS:1.5`` for 1.5 KUDOS.

-  summary: A human-readable summary for what the payment is about. The
   summary should be short enough to fit into titles, though no hard
   limit is enforced.

-  fulfillment_url: A URL that will be displayed once the payment is
   completed. For digital goods, this should be a page that displays the
   product that was purchased. On successful payment, the wallet
   automatically appends the ``order_id`` as a query parameter, as well
   as the ``session_sig`` for session-bound payments (discussed later).

Orders can have many more fields, see `The Taler Order
Format <#The-Taler-Order-Format>`__.

After successfully ``POST``\ ing to ``/order``, an ``order_id`` will be
returned. Together with the merchant ``instance``, the order id uniquely
identifies the order within a merchant backend.

::

   >>> import requests
   >>> order = dict(order=dict(amount="KUDOS:10",
   ...                         summary="Donation",
   ...                         fulfillment_url="https://example.com/thanks.html"))
   >>> order_resp = requests.post("https://backend.demo.taler.net/order", json=order,
   ...               headers={"Authorization": "ApiKey sandbox"})
   <Response [200]>

The backend will fill in some details missing in the order, such as the
address of the merchant instance. The full details are called the
*contract terms*. contract terms

Checking Payment Status and Prompting for Payment
-------------------------------------------------

The status of a payment can be checked with the ``/check-payment``
endpoint. If the payment is yet to be completed by the customer,
``/check-payment`` will give the frontend a URL (the
payment_redirect_url) that will trigger the customer’s wallet to execute
the payment.

Note that the only way to obtain the payment_redirect_url is to check
the status of the payment, even if you know that the user did not pay
yet.

::

   >>> import requests
   >>> r = requests.get("https://backend.demo.taler.net/check-payment",
   ...                  params=dict(order_id=order_resp.json()["order_id"]),
   ...                  headers={"Authorization": "ApiKey sandbox"})
   >>> print(r.json())

If the paid field in the response is ``true``, the other fields in the
response will be different. Once the payment was completed by the user,
the response will contain the following fields:

-  paid: Set to true.

-  contract_terms: The full contract terms of the order.

-  refunded: ``true`` if a (possibly partial) refund was granted for
   this purchase.

-  refunded_amount: Amount that was refunded

-  last_session_id: Last session ID used by the customer’s wallet. See
   `Session-Bound Payments <#Session_002dBound-Payments>`__.

Once the frontend has confirmed that the payment was successful, it
usually needs to trigger the business logic for the merchant to fulfill
the merchant’s obligations under the contract.

.. _Giving-Refunds:

Giving Refunds
==============

refunds
A refund in GNU Taler is a way to “undo” a payment. It needs to be
authorized by the merchant. Refunds can be for any fraction of the
original amount paid, but they cannot exceed the original payment.
Refunds are time-limited and can only happen while the exchange holds
funds for a particular payment in escrow. The time during which a refund
is possible can be controlled by setting the ``refund_deadline`` in an
order. The default value for this refund deadline is specified in the
configuration of the merchant’s backend.

The frontend can instruct the merchant backend to authorize a refund by
``POST``\ ing to the ``/refund`` endpoint.

The refund request JSON object has the following fields:

-  order_id: Identifies for which order a customer should be refunded.

-  instance: Merchant instance to use.

-  refund: Amount to be refunded. If a previous refund was authorized
   for the same order, the new amount must be higher, otherwise the
   operation has no effect. The value indicates the total amount to be
   refunded, *not* an increase in the refund.

-  reason: Human-readable justification for the refund. The reason is
   only used by the Back Office and is not exposed to the customer.

If the request is successful (indicated by HTTP status code 200), the
response includes a ``refund_redirect_url``. The frontend must redirect
the customer’s browser to that URL to allow the refund to be processed
by the wallet.

This code snipped illustrates giving a refund:

::

   >>> import requests
   >>> refund_req = dict(order_id="2018.058.21.46.06-024C85K189H8P",
   ...                   refund="KUDOS:10",
   ...                   instance="default",
   ...                   reason="Customer did not like the product")
   >>> requests.post("https://backend.demo.taler.net/refund", json=refund_req,
   ...              headers={"Authorization": "ApiKey sandbox"})
   <Response [200]>

.. _Giving-Customers-Tips:

Giving Customers Tips
=====================

tips
GNU Taler allows Web sites to grant small amounts directly to the
visitor. The idea is that some sites may want incentivize actions such
as filling out a survey or trying a new feature. It is important to note
that tips are not enforceable for the visitor, as there is no contract.
It is simply a voluntary gesture of appreciation of the site to its
visitor. However, once a tip has been granted, the visitor obtains full
control over the funds provided by the site.

The “merchant” backend of the site must be properly configured for
tipping, and sufficient funds must be made available for tipping See
Taler Merchant Operating Manual.

To check if tipping is configured properly and if there are sufficient
funds available for tipping, query the ``/tip-query`` endpoint:

::

   >>> import requests
   >>> requests.get("https://backend.demo.taler.net/tip-query?instance=default",
   ...              headers={"Authorization": "ApiKey sandbox"})
   <Response [200]>

authorize tip
To authorize a tip, ``POST`` to ``/tip-authorize``. The following fields
are recognized in the JSON request object:

-  amount: Amount that should be given to the visitor as a tip.

-  instance: Merchant instance that grants the tip (each instance may
   have its own independend tipping funds configured).

-  justification: Description of why the tip was granted. Human-readable
   text not exposed to the customer, but used by the Back Office.

-  next_url: The URL that the user’s browser should be redirected to by
   the wallet, once the tip has been processed.

The response from the backend contains a ``tip_redirect_url``. The
customer’s browser must be redirected to this URL for the wallet to pick
up the tip. pick up tip

This code snipped illustrates giving a tip:

::

   >>> import requests
   >>> tip_req = dict(amount="KUDOS:0.5",
   ...                instance="default",
   ...                justification="User filled out survey",
   ...                next_url="https://merchant.com/thanks.html")
   >>> requests.post("https://backend.demo.taler.net/tip-authorize", json=tip_req,
   ...              headers={"Authorization": "ApiKey sandbox"})
   <Response [200]>

.. _Advanced-topics:

Advanced topics
===============

.. _Detecting-the-Presence-of-the-Taler-Wallet:

Detecting the Presence of the Taler Wallet
------------------------------------------

wallet
Taler offers ways to detect whether a user has the wallet installed in
their browser. This allows Web sites to adapt accordingly. Note that not
all platforms can do presence detection reliably. Some platforms might
have a Taler wallet installed as a separate App instead of using a Web
extension. In these cases, presence detection will fail. Thus, sites may
want to allow users to request Taler payments even if a wallet could not
be detected, especially for visitors using mobiles.

Presence detection without JavaScript
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Presence detection without JavaScript is based on CSS classes. You can
hide or show elements selectively depending on whether the wallet is
detected or not.

In order to work correctly, a special fallback stylesheet must be
included that will be used when the wallet is not present. The
stylesheet can be put into any file, but must be included via a ``link``
tag with the ``id`` attribute set to ``taler-presence-stylesheet``. If a
wallet is present, it will “hijack” this stylesheet to change how
elements with the following classes are rendered:

The following CSS classes can be used:

``taler-installed-hide``
   A CSS rule will set the ``display`` property for this class to
   ``none`` once the Taler wallet is installed and enabled. If the
   wallet is not installed, ``display`` will be ``inherit``.

``taler-installed-show``
   A CSS rule will set the ``display`` property for this class to
   ``inherit`` once the Taler wallet is installed and enabled. If the
   wallet is not installed, ``display`` will be ``none``.

The following is a complete example:

::

   <!DOCTYPE html>
   <html data-taler-nojs="true">
     <head>
       <title>Tutorial</title>
       <link rel="stylesheet"
             type="text/css"
             href="/web-common/taler-fallback.css"
             id="taler-presence-stylesheet" />
     </head>
     <body>
       <p class="taler-installed-hide">
         No wallet found.
       </p>
       <p class="taler-installed-show">
         Wallet found!
       </p>
     </body>
   </html>

The ``taler-fallback.css`` is part of the Taler’s *web-common*
repository, available at
https://git.taler.net/web-common.git/tree/taler-fallback.css. You may
have to adjust the ``href`` attribute in the HTML code above to point to
the correct location of the ``taler-fallback.css`` file on your Web
site.

Detection with JavaScript
~~~~~~~~~~~~~~~~~~~~~~~~~

The following functions are defined in the ``taler`` namespace of the
``taler-wallet-lib`` helper library available at
https://git.taler.net/web-common.git/tree/taler-wallet-lib.js.

``onPresent(callback: () => void)``
   Adds a callback to be called when support for Taler payments is
   detected.

``onAbsent(callback: () => void)``
   Adds a callback to be called when support for Taler payments is
   disabled.

Note that the registered callbacks may be called more than once. This
may happen if a user disables or enables the wallet in the browser’s
extension settings while a shop’s frontend page is open.

.. _Integration-with-the-Back-Office:

Integration with the Back Office
--------------------------------

Taler ships a Back Office application as a stand-alone Web application.
The Back Office has its own documentation at
https://docs.taler.net/backoffice/html/manual.html.

Developers wishing to tightly integrate back office support for
Taler-based payments into an existing back office application should
focus on the wire transfer tracking and transaction history sections of
the Taler Backend API specification at
https://docs.taler.net/api/api-merchant.html

.. _Session_002dBound-Payments:

Session-Bound Payments
----------------------

session
Sometimes checking if an order has been paid for is not enough. For
example, when selling access to online media, the publisher may want to
be paid for exactly the same product by each customer. Taler supports
this model by allowing the mechant to check whether the “payment
receipt” is available on the user’s current device. This prevents users
from easily sharing media access by transmitting a link to the
fulfillment page. Of course sophisticated users could share payment
receipts as well, but this is not as easy as sharing a link, and in this
case they are more likely to just share the media directly.

To use this feature, the merchant must first assign the user’s current
browser an ephemeral ``session_id``, usually via a session cookie. When
executing or re-playing a payment, the wallet will receive an additional
signature (``session_sig``). This signature certifies that the wallet
showed a payment receipt for the respective order in the current
session. cookie

Session-bound payments are triggerd by passing the ``session_id``
parameter to the ``/check-payment`` endpoint. The wallet will then
redirect to the fulfillment page, but include an additional
``session_sig`` parameter. The frontend can query ``/check-payment``
with both the ``session_id`` and the ``session_sig`` to verify that the
signature is correct.

The last session ID that was successfuly used to prove that the payment
receipt is in the user’s wallet is also available as ``last_session_id``
in the response to ``/check-payment``.

.. _Product-Identification:

Product Identification
----------------------

resource url
In some situations the user may have paid for some digital good, but the
frontend does not know the exact order ID, and thus cannot instruct the
wallet to reveil the existing payment receipt. This is common for simple
shops without a login system. In this case, the user would be prompted
for payment again, even though they already purchased the product.

To allow the wallet to instead find the existing payment receipt, the
shop must use a unique fulfillment URL for each product. Then, the
frontend must provide an additional ``resource_url`` parameter to to
``/check-payment``. It should identify this unique fulfillment URL for
the product. The wallet will then check whether it has paid for a
contract with the same ``resource_url`` before, and if so replay the
previous payment.

.. _The-Taler-Order-Format:

The Taler Order Format
----------------------

contract
terms
order
A Taler order can specify many details about the payment. This section
describes each of the fields in depth.

Financial amounts are always specified as a string in the format
``"CURRENCY:DECIMAL_VALUE"``.

amount
   amount
   Specifies the total amount to be paid to the merchant by the
   customer.

max_fee
   fees
   maximum deposit fee
   This is the maximum total amount of deposit fees that the merchant is
   willing to pay. If the deposit fees for the coins exceed this amount,
   the customer has to include it in the payment total. The fee is
   specified using the same triplet used for amount.

max_wire_fee
   fees
   maximum wire fee
   Maximum wire fee accepted by the merchant (customer share to be
   divided by the ’wire_fee_amortization’ factor, and further reduced if
   deposit fees are below ’max_fee’). Default if missing is zero.

wire_fee_amortization
   fees
   maximum fee amortization
   Over how many customer transactions does the merchant expect to
   amortize wire fees on average? If the exchange’s wire fee is above
   ’max_wire_fee’, the difference is divided by this number to compute
   the expected customer’s contribution to the wire fee. The customer’s
   contribution may further be reduced by the difference between the
   ’max_fee’ and the sum of the actual deposit fees. Optional, default
   value if missing is 1. 0 and negative values are invalid and also
   interpreted as 1.

pay_url
   pay_url
   Which URL accepts payments. This is the URL where the wallet will
   POST coins.

fulfillment_url
   fulfillment URL
   Which URL should the wallet go to for obtaining the fulfillment, for
   example the HTML or PDF of an article that was bought, or an order
   tracking system for shipments, or a simple human-readable Web page
   indicating the status of the contract.

order_id
   order ID
   Alphanumeric identifier, freely definable by the merchant. Used by
   the merchant to uniquely identify the transaction.

summary
   summary
   Short, human-readable summary of the contract. To be used when
   displaying the contract in just one line, for example in the
   transaction history of the customer.

timestamp
   Time at which the offer was generated.

pay_deadline
   payment deadline
   Timestamp of the time by which the merchant wants the exchange to
   definitively wire the money due from this contract. Once this
   deadline expires, the exchange will aggregate all deposits where the
   contracts are past the refund_deadline and execute one large wire
   payment for them. Amounts will be rounded down to the wire transfer
   unit; if the total amount is still below the wire transfer unit, it
   will not be disbursed.

refund_deadline
   refund deadline
   Timestamp until which the merchant willing (and able) to give refunds
   for the contract using Taler. Note that the Taler exchange will hold
   the payment in escrow at least until this deadline. Until this time,
   the merchant will be able to sign a message to trigger a refund to
   the customer. After this time, it will no longer be possible to
   refund the customer. Must be smaller than the pay_deadline.

products
   product description
   Array of products that are being sold to the customer. Each entry
   contains a tuple with the following values:

   description
      Description of the product.

   quantity
      Quantity of the items to be shipped. May specify a unit (``1 kg``)
      or just the count.

   price
      Price for quantity units of this product shipped to the given
      delivery_location. Note that usually the sum of all of the prices
      should add up to the total amount of the contract, but it may be
      different due to discounts or because individual prices are
      unavailable.

   product_id
      Unique ID of the product in the merchant’s catalog. Can generally
      be chosen freely as it only has meaning for the merchant, but
      should be a number in the range :math:`[0,2^{51})`.

   taxes
      Map of applicable taxes to be paid by the merchant. The label is
      the name of the tax, i.e. VAT, sales tax or income tax, and the
      value is the applicable tax amount. Note that arbitrary labels are
      permitted, as long as they are used to identify the applicable tax
      regime. Details may be specified by the regulator. This is used to
      declare to the customer which taxes the merchant intends to pay,
      and can be used by the customer as a receipt. The information is
      also likely to be used by tax audits of the merchant.

   delivery_date
      Time by which the product is to be delivered to the
      delivery_location.

   delivery_location
      This should give a label in the locations map, specifying where
      the item is to be delivered.

   Values can be omitted if they are not applicable. For example, if a
   purchase is about a bundle of products that have no individual prices
   or product IDs, the product_id or price may not be specified in the
   contract. Similarly, for virtual products delivered directly via the
   fulfillment URI, there is no delivery location.

merchant
   address
      This should give a label in the locations map, specifying where
      the merchant is located.

   name
      This should give a human-readable name for the merchant’s
      business.

   jurisdiction
      This should give a label in the locations map, specifying the
      jurisdiction under which this contract is to be arbitrated.

locations
   location
   Associative map of locations used in the contract. Labels for
   locations in this map can be freely chosen and used whenever a
   location is required in other parts of the contract. This way, if the
   same location is required many times (such as the business address of
   the customer or the merchant), it only needs to be listed (and
   transmitted) once, and can otherwise be referred to via the label. A
   non-exhaustive list of location attributes is the following:

   country
      Name of the country for delivery, as found on a postal package,
      i.e. “France”.

   state
      Name of the state for delivery, as found on a postal package, i.e.
      “NY”.

   region
      Name of the region for delivery, as found on a postal package.

   province
      Name of the province for delivery, as found on a postal package.

   city
      Name of the city for delivery, as found on a postal package.

   ZIP code
      ZIP code for delivery, as found on a postal package.

   street
      Street name for delivery, as found on a postal package.

   street number
      Street number (number of the house) for delivery, as found on a
      postal package.

   name receiver name for delivery, either business or person name.

   Note that locations are not required to specify all of these fields,
   and they is also allowed to have additional fields. Contract
   renderers must render at least the fields listed above, and should
   render fields that they do not understand as a key-value list.

.. _GNU_002dLGPL:

GNU-LGPL
========

license
LGPL
Version 2.1, February 1999
::

   Copyright © 1991, 1999 Free Software Foundation, Inc.
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA

   Everyone is permitted to copy and distribute verbatim copies
   of this license document, but changing it is not allowed.

   [This is the first released version of the Lesser GPL.  It also counts
   as the successor of the GNU Library Public License, version 2, hence the
   version number 2.1.]

**Preamble**

The licenses for most software are designed to take away your freedom to
share and change it. By contrast, the GNU General Public Licenses are
intended to guarantee your freedom to share and change free software—to
make sure the software is free for all its users.

This license, the Lesser General Public License, applies to some
specially designated software—typically libraries—of the Free Software
Foundation and other authors who decide to use it. You can use it too,
but we suggest you first think carefully about whether this license or
the ordinary General Public License is the better strategy to use in any
particular case, based on the explanations below.

When we speak of free software, we are referring to freedom of use, not
price. Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
this service if you wish); that you receive source code or can get it if
you want it; that you can change the software and use pieces of it in
new free programs; and that you are informed that you can do these
things.

To protect your rights, we need to make restrictions that forbid
distributors to deny you these rights or to ask you to surrender these
rights. These restrictions translate to certain responsibilities for you
if you distribute copies of the library or if you modify it.

For example, if you distribute copies of the library, whether gratis or
for a fee, you must give the recipients all the rights that we gave you.
You must make sure that they, too, receive or can get the source code.
If you link other code with the library, you must provide complete
object files to the recipients, so that they can relink them with the
library after making changes to the library and recompiling it. And you
must show them these terms so they know their rights.

We protect your rights with a two-step method: (1) we copyright the
library, and (2) we offer you this license, which gives you legal
permission to copy, distribute and/or modify the library.

To protect each distributor, we want to make it very clear that there is
no warranty for the free library. Also, if the library is modified by
someone else and passed on, the recipients should know that what they
have is not the original version, so that the original author’s
reputation will not be affected by problems that might be introduced by
others.

Finally, software patents pose a constant threat to the existence of any
free program. We wish to make sure that a company cannot effectively
restrict the users of a free program by obtaining a restrictive license
from a patent holder. Therefore, we insist that any patent license
obtained for a version of the library must be consistent with the full
freedom of use specified in this license.

Most GNU software, including some libraries, is covered by the ordinary
GNU General Public License. This license, the GNU Lesser General Public
License, applies to certain designated libraries, and is quite different
from the ordinary General Public License. We use this license for
certain libraries in order to permit linking those libraries into
non-free programs.

When a program is linked with a library, whether statically or using a
shared library, the combination of the two is legally speaking a
combined work, a derivative of the original library. The ordinary
General Public License therefore permits such linking only if the entire
combination fits its criteria of freedom. The Lesser General Public
License permits more lax criteria for linking other code with the
library.

We call this license the Lesser General Public License because it does
*Less* to protect the user’s freedom than the ordinary General Public
License. It also provides other free software developers Less of an
advantage over competing non-free programs. These disadvantages are the
reason we use the ordinary General Public License for many libraries.
However, the Lesser license provides advantages in certain special
circumstances.

For example, on rare occasions, there may be a special need to encourage
the widest possible use of a certain library, so that it becomes a
de-facto standard. To achieve this, non-free programs must be allowed to
use the library. A more frequent case is that a free library does the
same job as widely used non-free libraries. In this case, there is
little to gain by limiting the free library to free software only, so we
use the Lesser General Public License.

In other cases, permission to use a particular library in non-free
programs enables a greater number of people to use a large body of free
software. For example, permission to use the GNU C Library in non-free
programs enables many more people to use the whole GNU operating system,
as well as its variant, the GNU/Linux operating system.

Although the Lesser General Public License is Less protective of the
users’ freedom, it does ensure that the user of a program that is linked
with the Library has the freedom and the wherewithal to run that program
using a modified version of the Library.

The precise terms and conditions for copying, distribution and
modification follow. Pay close attention to the difference between a
“work based on the library” and a “work that uses the library”. The
former contains code derived from the library, whereas the latter must
be combined with the library in order to run.

**TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION**

1.  This License Agreement applies to any software library or other
    program which contains a notice placed by the copyright holder or
    other authorized party saying it may be distributed under the terms
    of this Lesser General Public License (also called “this License”).
    Each licensee is addressed as “you”.

    A “library” means a collection of software functions and/or data
    prepared so as to be conveniently linked with application programs
    (which use some of those functions and data) to form executables.

    The “Library”, below, refers to any such software library or work
    which has been distributed under these terms. A “work based on the
    Library” means either the Library or any derivative work under
    copyright law: that is to say, a work containing the Library or a
    portion of it, either verbatim or with modifications and/or
    translated straightforwardly into another language. (Hereinafter,
    translation is included without limitation in the term
    “modification”.)

    “Source code” for a work means the preferred form of the work for
    making modifications to it. For a library, complete source code
    means all the source code for all modules it contains, plus any
    associated interface definition files, plus the scripts used to
    control compilation and installation of the library.

    Activities other than copying, distribution and modification are not
    covered by this License; they are outside its scope. The act of
    running a program using the Library is not restricted, and output
    from such a program is covered only if its contents constitute a
    work based on the Library (independent of the use of the Library in
    a tool for writing it). Whether that is true depends on what the
    Library does and what the program that uses the Library does.

2.  You may copy and distribute verbatim copies of the Library’s
    complete source code as you receive it, in any medium, provided that
    you conspicuously and appropriately publish on each copy an
    appropriate copyright notice and disclaimer of warranty; keep intact
    all the notices that refer to this License and to the absence of any
    warranty; and distribute a copy of this License along with the
    Library.

    You may charge a fee for the physical act of transferring a copy,
    and you may at your option offer warranty protection in exchange for
    a fee.

3.  You may modify your copy or copies of the Library or any portion of
    it, thus forming a work based on the Library, and copy and
    distribute such modifications or work under the terms of Section 1
    above, provided that you also meet all of these conditions:

    a. The modified work must itself be a software library.

    b. You must cause the files modified to carry prominent notices
       stating that you changed the files and the date of any change.

    c. You must cause the whole of the work to be licensed at no charge
       to all third parties under the terms of this License.

    d. If a facility in the modified Library refers to a function or a
       table of data to be supplied by an application program that uses
       the facility, other than as an argument passed when the facility
       is invoked, then you must make a good faith effort to ensure
       that, in the event an application does not supply such function
       or table, the facility still operates, and performs whatever part
       of its purpose remains meaningful.

       (For example, a function in a library to compute square roots has
       a purpose that is entirely well-defined independent of the
       application. Therefore, Subsection 2d requires that any
       application-supplied function or table used by this function must
       be optional: if the application does not supply it, the square
       root function must still compute square roots.)

    These requirements apply to the modified work as a whole. If
    identifiable sections of that work are not derived from the Library,
    and can be reasonably considered independent and separate works in
    themselves, then this License, and its terms, do not apply to those
    sections when you distribute them as separate works. But when you
    distribute the same sections as part of a whole which is a work
    based on the Library, the distribution of the whole must be on the
    terms of this License, whose permissions for other licensees extend
    to the entire whole, and thus to each and every part regardless of
    who wrote it.

    Thus, it is not the intent of this section to claim rights or
    contest your rights to work written entirely by you; rather, the
    intent is to exercise the right to control the distribution of
    derivative or collective works based on the Library.

    In addition, mere aggregation of another work not based on the
    Library with the Library (or with a work based on the Library) on a
    volume of a storage or distribution medium does not bring the other
    work under the scope of this License.

4.  You may opt to apply the terms of the ordinary GNU General Public
    License instead of this License to a given copy of the Library. To
    do this, you must alter all the notices that refer to this License,
    so that they refer to the ordinary GNU General Public License,
    version 2, instead of to this License. (If a newer version than
    version 2 of the ordinary GNU General Public License has appeared,
    then you can specify that version instead if you wish.) Do not make
    any other change in these notices.

    Once this change is made in a given copy, it is irreversible for
    that copy, so the ordinary GNU General Public License applies to all
    subsequent copies and derivative works made from that copy.

    This option is useful when you wish to copy part of the code of the
    Library into a program that is not a library.

5.  You may copy and distribute the Library (or a portion or derivative
    of it, under Section 2) in object code or executable form under the
    terms of Sections 1 and 2 above provided that you accompany it with
    the complete corresponding machine-readable source code, which must
    be distributed under the terms of Sections 1 and 2 above on a medium
    customarily used for software interchange.

    If distribution of object code is made by offering access to copy
    from a designated place, then offering equivalent access to copy the
    source code from the same place satisfies the requirement to
    distribute the source code, even though third parties are not
    compelled to copy the source along with the object code.

6.  A program that contains no derivative of any portion of the Library,
    but is designed to work with the Library by being compiled or linked
    with it, is called a “work that uses the Library”. Such a work, in
    isolation, is not a derivative work of the Library, and therefore
    falls outside the scope of this License.

    However, linking a “work that uses the Library” with the Library
    creates an executable that is a derivative of the Library (because
    it contains portions of the Library), rather than a “work that uses
    the library”. The executable is therefore covered by this License.
    Section 6 states terms for distribution of such executables.

    When a “work that uses the Library” uses material from a header file
    that is part of the Library, the object code for the work may be a
    derivative work of the Library even though the source code is not.
    Whether this is true is especially significant if the work can be
    linked without the Library, or if the work is itself a library. The
    threshold for this to be true is not precisely defined by law.

    If such an object file uses only numerical parameters, data
    structure layouts and accessors, and small macros and small inline
    functions (ten lines or less in length), then the use of the object
    file is unrestricted, regardless of whether it is legally a
    derivative work. (Executables containing this object code plus
    portions of the Library will still fall under Section 6.)

    Otherwise, if the work is a derivative of the Library, you may
    distribute the object code for the work under the terms of Section
    6. Any executables containing that work also fall under Section 6,
    whether or not they are linked directly with the Library itself.

7.  As an exception to the Sections above, you may also combine or link
    a “work that uses the Library” with the Library to produce a work
    containing portions of the Library, and distribute that work under
    terms of your choice, provided that the terms permit modification of
    the work for the customer’s own use and reverse engineering for
    debugging such modifications.

    You must give prominent notice with each copy of the work that the
    Library is used in it and that the Library and its use are covered
    by this License. You must supply a copy of this License. If the work
    during execution displays copyright notices, you must include the
    copyright notice for the Library among them, as well as a reference
    directing the user to the copy of this License. Also, you must do
    one of these things:

    a. Accompany the work with the complete corresponding
       machine-readable source code for the Library including whatever
       changes were used in the work (which must be distributed under
       Sections 1 and 2 above); and, if the work is an executable linked
       with the Library, with the complete machine-readable “work that
       uses the Library”, as object code and/or source code, so that the
       user can modify the Library and then relink to produce a modified
       executable containing the modified Library. (It is understood
       that the user who changes the contents of definitions files in
       the Library will not necessarily be able to recompile the
       application to use the modified definitions.)

    b. Use a suitable shared library mechanism for linking with the
       Library. A suitable mechanism is one that (1) uses at run time a
       copy of the library already present on the user’s computer
       system, rather than copying library functions into the
       executable, and (2) will operate properly with a modified version
       of the library, if the user installs one, as long as the modified
       version is interface-compatible with the version that the work
       was made with.

    c. Accompany the work with a written offer, valid for at least three
       years, to give the same user the materials specified in
       Subsection 6a, above, for a charge no more than the cost of
       performing this distribution.

    d. If distribution of the work is made by offering access to copy
       from a designated place, offer equivalent access to copy the
       above specified materials from the same place.

    e. Verify that the user has already received a copy of these
       materials or that you have already sent this user a copy.

    For an executable, the required form of the “work that uses the
    Library” must include any data and utility programs needed for
    reproducing the executable from it. However, as a special exception,
    the materials to be distributed need not include anything that is
    normally distributed (in either source or binary form) with the
    major components (compiler, kernel, and so on) of the operating
    system on which the executable runs, unless that component itself
    accompanies the executable.

    It may happen that this requirement contradicts the license
    restrictions of other proprietary libraries that do not normally
    accompany the operating system. Such a contradiction means you
    cannot use both them and the Library together in an executable that
    you distribute.

8.  You may place library facilities that are a work based on the
    Library side-by-side in a single library together with other library
    facilities not covered by this License, and distribute such a
    combined library, provided that the separate distribution of the
    work based on the Library and of the other library facilities is
    otherwise permitted, and provided that you do these two things:

    a. Accompany the combined library with a copy of the same work based
       on the Library, uncombined with any other library facilities.
       This must be distributed under the terms of the Sections above.

    b. Give prominent notice with the combined library of the fact that
       part of it is a work based on the Library, and explaining where
       to find the accompanying uncombined form of the same work.

9.  You may not copy, modify, sublicense, link with, or distribute the
    Library except as expressly provided under this License. Any attempt
    otherwise to copy, modify, sublicense, link with, or distribute the
    Library is void, and will automatically terminate your rights under
    this License. However, parties who have received copies, or rights,
    from you under this License will not have their licenses terminated
    so long as such parties remain in full compliance.

10. You are not required to accept this License, since you have not
    signed it. However, nothing else grants you permission to modify or
    distribute the Library or its derivative works. These actions are
    prohibited by law if you do not accept this License. Therefore, by
    modifying or distributing the Library (or any work based on the
    Library), you indicate your acceptance of this License to do so, and
    all its terms and conditions for copying, distributing or modifying
    the Library or works based on it.

11. Each time you redistribute the Library (or any work based on the
    Library), the recipient automatically receives a license from the
    original licensor to copy, distribute, link with or modify the
    Library subject to these terms and conditions. You may not impose
    any further restrictions on the recipients’ exercise of the rights
    granted herein. You are not responsible for enforcing compliance by
    third parties with this License.

12. If, as a consequence of a court judgment or allegation of patent
    infringement or for any other reason (not limited to patent issues),
    conditions are imposed on you (whether by court order, agreement or
    otherwise) that contradict the conditions of this License, they do
    not excuse you from the conditions of this License. If you cannot
    distribute so as to satisfy simultaneously your obligations under
    this License and any other pertinent obligations, then as a
    consequence you may not distribute the Library at all. For example,
    if a patent license would not permit royalty-free redistribution of
    the Library by all those who receive copies directly or indirectly
    through you, then the only way you could satisfy both it and this
    License would be to refrain entirely from distribution of the
    Library.

    If any portion of this section is held invalid or unenforceable
    under any particular circumstance, the balance of the section is
    intended to apply, and the section as a whole is intended to apply
    in other circumstances.

    It is not the purpose of this section to induce you to infringe any
    patents or other property right claims or to contest validity of any
    such claims; this section has the sole purpose of protecting the
    integrity of the free software distribution system which is
    implemented by public license practices. Many people have made
    generous contributions to the wide range of software distributed
    through that system in reliance on consistent application of that
    system; it is up to the author/donor to decide if he or she is
    willing to distribute software through any other system and a
    licensee cannot impose that choice.

    This section is intended to make thoroughly clear what is believed
    to be a consequence of the rest of this License.

13. If the distribution and/or use of the Library is restricted in
    certain countries either by patents or by copyrighted interfaces,
    the original copyright holder who places the Library under this
    License may add an explicit geographical distribution limitation
    excluding those countries, so that distribution is permitted only in
    or among countries not thus excluded. In such case, this License
    incorporates the limitation as if written in the body of this
    License.

14. The Free Software Foundation may publish revised and/or new versions
    of the Lesser General Public License from time to time. Such new
    versions will be similar in spirit to the present version, but may
    differ in detail to address new problems or concerns.

    Each version is given a distinguishing version number. If the
    Library specifies a version number of this License which applies to
    it and “any later version”, you have the option of following the
    terms and conditions either of that version or of any later version
    published by the Free Software Foundation. If the Library does not
    specify a license version number, you may choose any version ever
    published by the Free Software Foundation.

15. If you wish to incorporate parts of the Library into other free
    programs whose distribution conditions are incompatible with these,
    write to the author to ask for permission. For software which is
    copyrighted by the Free Software Foundation, write to the Free
    Software Foundation; we sometimes make exceptions for this. Our
    decision will be guided by the two goals of preserving the free
    status of all derivatives of our free software and of promoting the
    sharing and reuse of software generally.

    NO WARRANTY
16. BECAUSE THE LIBRARY IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
    FOR THE LIBRARY, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
    WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
    PARTIES PROVIDE THE LIBRARY “AS IS” WITHOUT WARRANTY OF ANY KIND,
    EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
    PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
    LIBRARY IS WITH YOU. SHOULD THE LIBRARY PROVE DEFECTIVE, YOU ASSUME
    THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

17. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN
    WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY
    AND/OR REDISTRIBUTE THE LIBRARY AS PERMITTED ABOVE, BE LIABLE TO YOU
    FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR
    CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
    LIBRARY (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
    RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
    FAILURE OF THE LIBRARY TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
    SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
    SUCH DAMAGES.

**END OF TERMS AND CONDITIONS**

**How to Apply These Terms to Your New Libraries**

If you develop a new library, and you want it to be of the greatest
possible use to the public, we recommend making it free software that
everyone can redistribute and change. You can do so by permitting
redistribution under these terms (or, alternatively, under the terms of
the ordinary General Public License).

To apply these terms, attach the following notices to the library. It is
safest to attach them to the start of each source file to most
effectively convey the exclusion of warranty; and each file should have
at least the “copyright” line and a pointer to where the full notice is
found.

::

   one line to give the library's name and an idea of what it does.
   Copyright (C) year  name of author

   This library is free software; you can redistribute it and/or modify it
   under the terms of the GNU Lesser General Public License as published by
   the Free Software Foundation; either version 2.1 of the License, or (at
   your option) any later version.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
   USA.

Also add information on how to contact you by electronic and paper mail.

You should also get your employer (if you work as a programmer) or your
school, if any, to sign a “copyright disclaimer” for the library, if
necessary. Here is a sample; alter the names:

::

   Yoyodyne, Inc., hereby disclaims all copyright interest in the library
   `Frob' (a library for tweaking knobs) written by James Random Hacker.

   signature of Ty Coon, 1 April 1990
   Ty Coon, President of Vice

That’s all there is to it!

.. _GNU_002dFDL:

GNU-FDL
=======

license
GNU Free Documentation License
Version 1.3, 3 November 2008
::

   Copyright © 2000, 2001, 2002, 2007, 2008 Free Software Foundation, Inc.
   http://fsf.org/

   Everyone is permitted to copy and distribute verbatim copies
   of this license document, but changing it is not allowed.

1.  PREAMBLE

    The purpose of this License is to make a manual, textbook, or other
    functional and useful document free in the sense of freedom: to
    assure everyone the effective freedom to copy and redistribute it,
    with or without modifying it, either commercially or
    noncommercially. Secondarily, this License preserves for the author
    and publisher a way to get credit for their work, while not being
    considered responsible for modifications made by others.

    This License is a kind of “copyleft”, which means that derivative
    works of the document must themselves be free in the same sense. It
    complements the GNU General Public License, which is a copyleft
    license designed for free software.

    We have designed this License in order to use it for manuals for
    free software, because free software needs free documentation: a
    free program should come with manuals providing the same freedoms
    that the software does. But this License is not limited to software
    manuals; it can be used for any textual work, regardless of subject
    matter or whether it is published as a printed book. We recommend
    this License principally for works whose purpose is instruction or
    reference.

2.  APPLICABILITY AND DEFINITIONS

    This License applies to any manual or other work, in any medium,
    that contains a notice placed by the copyright holder saying it can
    be distributed under the terms of this License. Such a notice grants
    a world-wide, royalty-free license, unlimited in duration, to use
    that work under the conditions stated herein. The “Document”, below,
    refers to any such manual or work. Any member of the public is a
    licensee, and is addressed as “you”. You accept the license if you
    copy, modify or distribute the work in a way requiring permission
    under copyright law.

    A “Modified Version” of the Document means any work containing the
    Document or a portion of it, either copied verbatim, or with
    modifications and/or translated into another language.

    A “Secondary Section” is a named appendix or a front-matter section
    of the Document that deals exclusively with the relationship of the
    publishers or authors of the Document to the Document’s overall
    subject (or to related matters) and contains nothing that could fall
    directly within that overall subject. (Thus, if the Document is in
    part a textbook of mathematics, a Secondary Section may not explain
    any mathematics.) The relationship could be a matter of historical
    connection with the subject or with related matters, or of legal,
    commercial, philosophical, ethical or political position regarding
    them.

    The “Invariant Sections” are certain Secondary Sections whose titles
    are designated, as being those of Invariant Sections, in the notice
    that says that the Document is released under this License. If a
    section does not fit the above definition of Secondary then it is
    not allowed to be designated as Invariant. The Document may contain
    zero Invariant Sections. If the Document does not identify any
    Invariant Sections then there are none.

    The “Cover Texts” are certain short passages of text that are
    listed, as Front-Cover Texts or Back-Cover Texts, in the notice that
    says that the Document is released under this License. A Front-Cover
    Text may be at most 5 words, and a Back-Cover Text may be at most 25
    words.

    A “Transparent” copy of the Document means a machine-readable copy,
    represented in a format whose specification is available to the
    general public, that is suitable for revising the document
    straightforwardly with generic text editors or (for images composed
    of pixels) generic paint programs or (for drawings) some widely
    available drawing editor, and that is suitable for input to text
    formatters or for automatic translation to a variety of formats
    suitable for input to text formatters. A copy made in an otherwise
    Transparent file format whose markup, or absence of markup, has been
    arranged to thwart or discourage subsequent modification by readers
    is not Transparent. An image format is not Transparent if used for
    any substantial amount of text. A copy that is not “Transparent” is
    called “Opaque”.

    Examples of suitable formats for Transparent copies include plain
    ASCII without markup, Texinfo input format, LaTEX input format, SGML
    or XML using a publicly available DTD, and standard-conforming
    simple HTML, PostScript or PDF designed for human modification.
    Examples of transparent image formats include PNG, XCF and JPG.
    Opaque formats include proprietary formats that can be read and
    edited only by proprietary word processors, SGML or XML for which
    the DTD and/or processing tools are not generally available, and the
    machine-generated HTML, PostScript or PDF produced by some word
    processors for output purposes only.

    The “Title Page” means, for a printed book, the title page itself,
    plus such following pages as are needed to hold, legibly, the
    material this License requires to appear in the title page. For
    works in formats which do not have any title page as such, “Title
    Page” means the text near the most prominent appearance of the
    work’s title, preceding the beginning of the body of the text.

    The “publisher” means any person or entity that distributes copies
    of the Document to the public.

    A section “Entitled XYZ” means a named subunit of the Document whose
    title either is precisely XYZ or contains XYZ in parentheses
    following text that translates XYZ in another language. (Here XYZ
    stands for a specific section name mentioned below, such as
    “Acknowledgements”, “Dedications”, “Endorsements”, or “History”.) To
    “Preserve the Title” of such a section when you modify the Document
    means that it remains a section “Entitled XYZ” according to this
    definition.

    The Document may include Warranty Disclaimers next to the notice
    which states that this License applies to the Document. These
    Warranty Disclaimers are considered to be included by reference in
    this License, but only as regards disclaiming warranties: any other
    implication that these Warranty Disclaimers may have is void and has
    no effect on the meaning of this License.

3.  VERBATIM COPYING

    You may copy and distribute the Document in any medium, either
    commercially or noncommercially, provided that this License, the
    copyright notices, and the license notice saying this License
    applies to the Document are reproduced in all copies, and that you
    add no other conditions whatsoever to those of this License. You may
    not use technical measures to obstruct or control the reading or
    further copying of the copies you make or distribute. However, you
    may accept compensation in exchange for copies. If you distribute a
    large enough number of copies you must also follow the conditions in
    section 3.

    You may also lend copies, under the same conditions stated above,
    and you may publicly display copies.

4.  COPYING IN QUANTITY

    If you publish printed copies (or copies in media that commonly have
    printed covers) of the Document, numbering more than 100, and the
    Document’s license notice requires Cover Texts, you must enclose the
    copies in covers that carry, clearly and legibly, all these Cover
    Texts: Front-Cover Texts on the front cover, and Back-Cover Texts on
    the back cover. Both covers must also clearly and legibly identify
    you as the publisher of these copies. The front cover must present
    the full title with all words of the title equally prominent and
    visible. You may add other material on the covers in addition.
    Copying with changes limited to the covers, as long as they preserve
    the title of the Document and satisfy these conditions, can be
    treated as verbatim copying in other respects.

    If the required texts for either cover are too voluminous to fit
    legibly, you should put the first ones listed (as many as fit
    reasonably) on the actual cover, and continue the rest onto adjacent
    pages.

    If you publish or distribute Opaque copies of the Document numbering
    more than 100, you must either include a machine-readable
    Transparent copy along with each Opaque copy, or state in or with
    each Opaque copy a computer-network location from which the general
    network-using public has access to download using public-standard
    network protocols a complete Transparent copy of the Document, free
    of added material. If you use the latter option, you must take
    reasonably prudent steps, when you begin distribution of Opaque
    copies in quantity, to ensure that this Transparent copy will remain
    thus accessible at the stated location until at least one year after
    the last time you distribute an Opaque copy (directly or through
    your agents or retailers) of that edition to the public.

    It is requested, but not required, that you contact the authors of
    the Document well before redistributing any large number of copies,
    to give them a chance to provide you with an updated version of the
    Document.

5.  MODIFICATIONS

    You may copy and distribute a Modified Version of the Document under
    the conditions of sections 2 and 3 above, provided that you release
    the Modified Version under precisely this License, with the Modified
    Version filling the role of the Document, thus licensing
    distribution and modification of the Modified Version to whoever
    possesses a copy of it. In addition, you must do these things in the
    Modified Version:

    A. Use in the Title Page (and on the covers, if any) a title
       distinct from that of the Document, and from those of previous
       versions (which should, if there were any, be listed in the
       History section of the Document). You may use the same title as a
       previous version if the original publisher of that version gives
       permission.

    B. List on the Title Page, as authors, one or more persons or
       entities responsible for authorship of the modifications in the
       Modified Version, together with at least five of the principal
       authors of the Document (all of its principal authors, if it has
       fewer than five), unless they release you from this requirement.

    C. State on the Title page the name of the publisher of the Modified
       Version, as the publisher.

    D. Preserve all the copyright notices of the Document.

    E. Add an appropriate copyright notice for your modifications
       adjacent to the other copyright notices.

    F. Include, immediately after the copyright notices, a license
       notice giving the public permission to use the Modified Version
       under the terms of this License, in the form shown in the
       Addendum below.

    G. Preserve in that license notice the full lists of Invariant
       Sections and required Cover Texts given in the Document’s license
       notice.

    H. Include an unaltered copy of this License.

    I. Preserve the section Entitled “History”, Preserve its Title, and
       add to it an item stating at least the title, year, new authors,
       and publisher of the Modified Version as given on the Title Page.
       If there is no section Entitled “History” in the Document, create
       one stating the title, year, authors, and publisher of the
       Document as given on its Title Page, then add an item describing
       the Modified Version as stated in the previous sentence.

    J. Preserve the network location, if any, given in the Document for
       public access to a Transparent copy of the Document, and likewise
       the network locations given in the Document for previous versions
       it was based on. These may be placed in the “History” section.
       You may omit a network location for a work that was published at
       least four years before the Document itself, or if the original
       publisher of the version it refers to gives permission.

    K. For any section Entitled “Acknowledgements” or “Dedications”,
       Preserve the Title of the section, and preserve in the section
       all the substance and tone of each of the contributor
       acknowledgements and/or dedications given therein.

    L. Preserve all the Invariant Sections of the Document, unaltered in
       their text and in their titles. Section numbers or the equivalent
       are not considered part of the section titles.

    M. Delete any section Entitled “Endorsements”. Such a section may
       not be included in the Modified Version.

    N. Do not retitle any existing section to be Entitled “Endorsements”
       or to conflict in title with any Invariant Section.

    O. Preserve any Warranty Disclaimers.

    If the Modified Version includes new front-matter sections or
    appendices that qualify as Secondary Sections and contain no
    material copied from the Document, you may at your option designate
    some or all of these sections as invariant. To do this, add their
    titles to the list of Invariant Sections in the Modified Version’s
    license notice. These titles must be distinct from any other section
    titles.

    You may add a section Entitled “Endorsements”, provided it contains
    nothing but endorsements of your Modified Version by various
    parties—for example, statements of peer review or that the text has
    been approved by an organization as the authoritative definition of
    a standard.

    You may add a passage of up to five words as a Front-Cover Text, and
    a passage of up to 25 words as a Back-Cover Text, to the end of the
    list of Cover Texts in the Modified Version. Only one passage of
    Front-Cover Text and one of Back-Cover Text may be added by (or
    through arrangements made by) any one entity. If the Document
    already includes a cover text for the same cover, previously added
    by you or by arrangement made by the same entity you are acting on
    behalf of, you may not add another; but you may replace the old one,
    on explicit permission from the previous publisher that added the
    old one.

    The author(s) and publisher(s) of the Document do not by this
    License give permission to use their names for publicity for or to
    assert or imply endorsement of any Modified Version.

6.  COMBINING DOCUMENTS

    You may combine the Document with other documents released under
    this License, under the terms defined in section 4 above for
    modified versions, provided that you include in the combination all
    of the Invariant Sections of all of the original documents,
    unmodified, and list them all as Invariant Sections of your combined
    work in its license notice, and that you preserve all their Warranty
    Disclaimers.

    The combined work need only contain one copy of this License, and
    multiple identical Invariant Sections may be replaced with a single
    copy. If there are multiple Invariant Sections with the same name
    but different contents, make the title of each such section unique
    by adding at the end of it, in parentheses, the name of the original
    author or publisher of that section if known, or else a unique
    number. Make the same adjustment to the section titles in the list
    of Invariant Sections in the license notice of the combined work.

    In the combination, you must combine any sections Entitled “History”
    in the various original documents, forming one section Entitled
    “History”; likewise combine any sections Entitled
    “Acknowledgements”, and any sections Entitled “Dedications”. You
    must delete all sections Entitled “Endorsements.”

7.  COLLECTIONS OF DOCUMENTS

    You may make a collection consisting of the Document and other
    documents released under this License, and replace the individual
    copies of this License in the various documents with a single copy
    that is included in the collection, provided that you follow the
    rules of this License for verbatim copying of each of the documents
    in all other respects.

    You may extract a single document from such a collection, and
    distribute it individually under this License, provided you insert a
    copy of this License into the extracted document, and follow this
    License in all other respects regarding verbatim copying of that
    document.

8.  AGGREGATION WITH INDEPENDENT WORKS

    A compilation of the Document or its derivatives with other separate
    and independent documents or works, in or on a volume of a storage
    or distribution medium, is called an “aggregate” if the copyright
    resulting from the compilation is not used to limit the legal rights
    of the compilation’s users beyond what the individual works permit.
    When the Document is included in an aggregate, this License does not
    apply to the other works in the aggregate which are not themselves
    derivative works of the Document.

    If the Cover Text requirement of section 3 is applicable to these
    copies of the Document, then if the Document is less than one half
    of the entire aggregate, the Document’s Cover Texts may be placed on
    covers that bracket the Document within the aggregate, or the
    electronic equivalent of covers if the Document is in electronic
    form. Otherwise they must appear on printed covers that bracket the
    whole aggregate.

9.  TRANSLATION

    Translation is considered a kind of modification, so you may
    distribute translations of the Document under the terms of section
    4. Replacing Invariant Sections with translations requires special
    permission from their copyright holders, but you may include
    translations of some or all Invariant Sections in addition to the
    original versions of these Invariant Sections. You may include a
    translation of this License, and all the license notices in the
    Document, and any Warranty Disclaimers, provided that you also
    include the original English version of this License and the
    original versions of those notices and disclaimers. In case of a
    disagreement between the translation and the original version of
    this License or a notice or disclaimer, the original version will
    prevail.

    If a section in the Document is Entitled “Acknowledgements”,
    “Dedications”, or “History”, the requirement (section 4) to Preserve
    its Title (section 1) will typically require changing the actual
    title.

10. TERMINATION

    You may not copy, modify, sublicense, or distribute the Document
    except as expressly provided under this License. Any attempt
    otherwise to copy, modify, sublicense, or distribute it is void, and
    will automatically terminate your rights under this License.

    However, if you cease all violation of this License, then your
    license from a particular copyright holder is reinstated (a)
    provisionally, unless and until the copyright holder explicitly and
    finally terminates your license, and (b) permanently, if the
    copyright holder fails to notify you of the violation by some
    reasonable means prior to 60 days after the cessation.

    Moreover, your license from a particular copyright holder is
    reinstated permanently if the copyright holder notifies you of the
    violation by some reasonable means, this is the first time you have
    received notice of violation of this License (for any work) from
    that copyright holder, and you cure the violation prior to 30 days
    after your receipt of the notice.

    Termination of your rights under this section does not terminate the
    licenses of parties who have received copies or rights from you
    under this License. If your rights have been terminated and not
    permanently reinstated, receipt of a copy of some or all of the same
    material does not give you any rights to use it.

11. FUTURE REVISIONS OF THIS LICENSE

    The Free Software Foundation may publish new, revised versions of
    the GNU Free Documentation License from time to time. Such new
    versions will be similar in spirit to the present version, but may
    differ in detail to address new problems or concerns. See
    http://www.gnu.org/copyleft/.

    Each version of the License is given a distinguishing version
    number. If the Document specifies that a particular numbered version
    of this License “or any later version” applies to it, you have the
    option of following the terms and conditions either of that
    specified version or of any later version that has been published
    (not as a draft) by the Free Software Foundation. If the Document
    does not specify a version number of this License, you may choose
    any version ever published (not as a draft) by the Free Software
    Foundation. If the Document specifies that a proxy can decide which
    future versions of this License can be used, that proxy’s public
    statement of acceptance of a version permanently authorizes you to
    choose that version for the Document.

12. RELICENSING

    “Massive Multiauthor Collaboration Site” (or “MMC Site”) means any
    World Wide Web server that publishes copyrightable works and also
    provides prominent facilities for anybody to edit those works. A
    public wiki that anybody can edit is an example of such a server. A
    “Massive Multiauthor Collaboration” (or “MMC”) contained in the site
    means any set of copyrightable works thus published on the MMC site.

    “CC-BY-SA” means the Creative Commons Attribution-Share Alike 3.0
    license published by Creative Commons Corporation, a not-for-profit
    corporation with a principal place of business in San Francisco,
    California, as well as future copyleft versions of that license
    published by that same organization.

    “Incorporate” means to publish or republish a Document, in whole or
    in part, as part of another Document.

    An MMC is “eligible for relicensing” if it is licensed under this
    License, and if all works that were first published under this
    License somewhere other than this MMC, and subsequently incorporated
    in whole or in part into the MMC, (1) had no cover texts or
    invariant sections, and (2) were thus incorporated prior to November
    1, 2008.

    The operator of an MMC Site may republish an MMC contained in the
    site under CC-BY-SA on the same site at any time before August 1,
    2009, provided the MMC is eligible for relicensing.

**ADDENDUM: How to use this License for your documents**

To use this License in a document you have written, include a copy of
the License in the document and put the following copyright and license
notices just after the title page:

::

     Copyright (C)  year  your name.
     Permission is granted to copy, distribute and/or modify this document
     under the terms of the GNU Free Documentation License, Version 1.3
     or any later version published by the Free Software Foundation;
     with no Invariant Sections, no Front-Cover Texts, and no Back-Cover
     Texts.  A copy of the license is included in the section entitled ``GNU
     Free Documentation License''.

If you have Invariant Sections, Front-Cover Texts and Back-Cover Texts,
replace the “with…Texts.” line with this:

::

       with the Invariant Sections being list their titles, with
       the Front-Cover Texts being list, and with the Back-Cover Texts
       being list.

If you have Invariant Sections without Cover Texts, or some other
combination of the three, merge those two alternatives to suit the
situation.

If your document contains nontrivial examples of program code, we
recommend releasing these examples in parallel under your choice of free
software license, such as the GNU General Public License, to permit
their use in free software.

.. _Concept-Index:

Concept Index
=============

.. |image0| image:: arch-api.png

