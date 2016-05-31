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

  @author Florian Dold
  @author Christian Grothoff

==============
Taler Glossary
==============

.. glossary::

  auditor
      trusted third party that verifies that the exchange is operating correctly

  bank
      traditional financial service provider who offers wire :transfers: between accounts

  coin
      coins are individual token representing a certain amount of value, also known as the :denomination: of the coin

  contract
      specification of the details of a transaction, specifies the payment obligations for the customer (i.e. the amount), the deliverables of the merchant and other related information, such as deadlines or locations

  denomination
      unit of currency, specifies both the currency and the face value of a :coin:

  denomination key
      RSA key used by the exchange to certify that a given :coin: is valid and of a particular :denomination:

  deposit
      operation by which a merchant passes coins to an exchange, expecting the exchange to credit his :bank: account in the future using a wire :transfer:

  dirty coin
     a :coin: is dirty if its public key may be known to an entity other than the customer, thereby creating the danger of some entity being able to link multiple transactions of coin's owner if the coin is not refreshed first

  extension
     implementation of a :wallet: for browsers

  fresh coin
     a :coin: is fresh if its public key is only known to the customer

  master key
     offline key used by the exchange to certify denomination keys and message signing keys

  message signing key
     key used by the exchange to sign online messages, other than coins

  owner
     a :coin: is owned by the entity that knows the private key of the coin

  proof
     message that cryptographically demonstrates that a particular claim is correct

  reserve
     funds set aside for future use; either the balance of a customer at the exchange ready for :withdrawal:, or the funds kept in the exchange's bank account to cover obligations from coins in circulation

  refreshing
     operation by which a :dirty: :coin: is converted into one or more :fresh: coins

  refund
     operation by which a merchant steps back from the right to funds that he obtained from a :deposit: operation, giving the right to the funds back to the customer

  sharing
     users can share ownership of a :coin: by sharing access to the coin's private key, thereby allowing all co-owners to spend the coin at any time.

  signing key
     see message signing key.

  spending
     operation by which a customer gives a merchant the right to :deposit: coins in return for merchandise

  transfer
     method of sending funds between :bank: accounts

  transaction
     method by which ownership is exclusively transferred from one entity to another

  transaction id
     unique number by which a merchant identifies a :transaction:

  wallet
     software running on a customer's computer; withdraws, stores and spends coins

  wire transfer
     see transfer

  wire transfer identifier
     subject of a wire transfer; usually a random string to uniquely identify the transfer

  withdrawal
     operation by which a :wallet: can convert funds from a reserve to fresh coins
