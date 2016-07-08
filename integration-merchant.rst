..
  This file is part of GNU TALER.
  Copyright (C) 2014, 2015, 2016 INRIA
  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.
  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Marcello Stanisci

==================================
Interaction with merchant websites
==================================

.. _payprot:

+++++++++++++++++++
The payment process
+++++++++++++++++++

Before delving into the technical details, it is worth surveying the payment process from an
abstract point of view. By design, Taler implements the following three points:

0. The user must accept a contract before paying for something
1. The bought item(s) must be made available again in the future by the merchant to the customer
   (in case of physical items, this point means that the merchant must provide the receipt again
   in the future to the customer)
2. The user must be able to *share* what he bought; in other words, we want a URI which would
   hold any information about the purchase (and therefore the contract), like which items the
   user bought and any other relevant detail. This way, any person who may get in possession
   of this URI may repeat the same purchase.

In Taler terminology, we call an *offering URL* an URL of the merchant's website that triggers
the generation of a contract, being it automatically or requiring the user interaction. For example,
some merchants may implement the offering URL such that it just returns the contract's JSON, and
some other may implement it as a shopping chart page where the user can then confirm its purchase and
get the contract JSON. We call a *fulfillment URL* an URL of the merchant's website which implements
points 1. and 2. For example, let's say that Alice bought a movie and a picture, and the fulfillment URL
for this purchase is *http://merchant.example.com/fulfillment?x=8ru42*. Each time Alice visits
*http://merchant.example.com/fulfillment?x=8ru42* she gets the same movie and picture. If then Alice
decides to give Bob this URL and he visits it, then he can decide to buy or not the same movie and
picture.

---------------
Payment details
---------------

A payment process is triggered whenever the user visits a fulfillment URL and he has no rights
in the session state to get the items accounted in the fulfillment URL. Note that when the user is
not visiting a fulfillment URL he got from someone else, it is the wallet which points the browser
to a fulfillment URL after the user accepts the contract. Since each fulfillment URL carries all the
details useful to reconstruct a contract, the merchant reconstructs the contract and sends back to
the user's browser a `taler-execute-payment` DOM event, defined as follows:

  .. code-block:: tsref

    {
      // base32 encoding of the Contract's hashcode
      H_contract: string;

      // URL where to send the deposit permission (AKA coins)
      pay_url: string;

      // Offering URL
      offering_url: string;
    }

This event is listened to by the wallet which can take two decisions based on the `H_contract`
field: if `H_contract` is known to the wallet, then the user has already accepted the contract
for this purchase and the wallet will send a deposit permission to `pay_url`. If that is not the
case, then the wallet will visit the `offering_url` and the user will decide whether or not to
accept the contract. Once `pay_url` receives and approves the deposit permission, it sets the session
state for the claimed item(s) to ``payed`` and now the wallet can point again the browser to the
fulfillment URL and finally get the claimed item(s). It's worth noting that each deposit permission
is associated with a contract and the wallet can reuse the same deposit permission to get the item(s)
mentioned in the contract without spending new coins.

------------
The contract
------------

As said, the offering URL is a location where the user must pass by in order to get a contract, and
the contract is handed by the merchant to the browser by the mean of a `taler-confirm-contract` DOM
event, defined as follows:

  .. code-block:: tsref

    {
      contract_wrapper: Offer;
    }

Check at :ref:`contract` how the `Offer` interface is defined.
