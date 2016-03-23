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

++++++++++++++++
Payment protocol
++++++++++++++++

The events described below get triggered when the user confirms its
purchase on a checkout page, or visits some merchant's resource
that needs a payment to be visualized.  We call this situation `IIG` (Interest
In some Good).  The user can initialize a IIG by visiting one of the following kind
of URL

* offering URL
* fulfillment URL

Offering URLs are visited the very first time the user wants to get some resource, whereas
fulfillment URLs let both the user access bought items later in the future (by bookmarking it)
and share its purchases with other users.  In the last case, the fulfillment URL acts like
a `pointer to the chart` whose items can be bought by who visits the fulfillment URL.

There is no hard separation between physical and virtual resources since
the receipt for a physical resource plays the same role of a 100% virtual resource like a
blog article.  In other words, when seeing a pay-per-view blog article on his screen, then
the user has payed for the article; on the other end, when seeing an electronic receipt of
a physical good on his screen, the user will receive it by mail.

IIG triggers different flows according to the user visiting an offering or a fulfillment
URL. For clarity, below are listed the steps taken when the user visits an offering URL.

.. _offer:

---------------------
IIG by `offering` URL
---------------------

0. If the state associated to the resource requested is `payed`, go to 7.

1. The merchant sends the following object embedded in a `taler-confirm-contract` event

  .. code-block:: tsref

    {
      // Contract and cryptographic information
      contract_wrapper: {
        contract: Contract;
        // base32 of the merchant's signature over this contract
        merchant_sig: string;
        // base32 of this contract's hashcode
        H_contract: string;      
      };

      // If true, the 'back-button' seen by the user when this contract is to be
      // payed will not point to this HTML, but to the previous one.
      replace_navigation: boolean
    }

2. The wallet's reaction is dual: it can either let the user pay for this contract, or
   detect whether the user has already payed for this resource by looking at the `repurchase_correlation_id`
   field in the contract.  In the first case, the wallet stores `H_contract` in its local database.
   If there is a match, the wallet starts a IIG by visiting the fulfillment URL associated with the
   already-made payment (see :ref:`ffil`)

3. The wallet visits the fulfillment URL (which indicated in the Contract). Since the merchant keeps
   no state for any purchase, it needs relevant information in the fulfillment URL in order to
   reconstruct the contract and send the payment to the backend.  This information is implicit in the
   mention of 'fulfillment URL'.

4. When a fulfillment URL is visited, the merchant reconstructs the contract and sends back to
   the user the a `taler-execute-payment` event which embeds the following object

  .. code-block:: tsref

    {
      // base32 of the Contract's hashcode
      H_contract: string;

      // URL where to send deposit permission
      pay_url: string;

      // Used in 'IIG by fulfillment URL'
      offering_url: string;
    }

5. The wallet sends the deposit permission to `pay_url`

6. If the payment is successful, then the merchant sets the state for the bought
   item to `payed` and communicate the outcome to the wallet (see :ref:`merchant API <pay>` for
   involved HTTP codes and JSONs)

7. Finally, the wallet can visit again the fulfillment URL and get the payed resource
   thanks to the `payed` state

.. _ffil:

------------------------
IIG by `fulfillment` URL
------------------------

We stress again that the fulfillment URL contains all the information a merchant needs
to reconstruct a contract.

0. If the state associated to the resource requested is `payed`, get the wanted resource.

1. The user visits a fulfillment URL

2. The merchant replies with the same data structure shown in point 4 above

3. The wallet checks if `H_contract` already exists in its database.  If it does not exist,
   then the wallet will automatically visit the offering URL (by looking at the `offering_url`
   field) and all the process will restart as in point 1 above.  Typically, this occurs when a
   user visits a fulfillment URL gotten from some other user.  If `H_contract` is known, then the
   wallet takes the associated deposit permission from its database and the process will continue
   as from point 5 above.  Please note that the latter scenario is not double spending since the
   same coins are spent on the same contract.
