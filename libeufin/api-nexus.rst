Sandbox API
###########


HTTP API
========

Users Management
----------------

Users are the entity that access accounts.  They do not necessarily correspond
to the actual legal owner of an account.  Their main purpose in the nexus is
access management.

.. http:get:: <nexus>/users

  List users.

  **Required permission:** Administrator.

.. http:post:: <nexus>/users

  Create a new user.

  **Required permission:** Administrators.


Bank Account Management
-----------------------

.. http:get:: <nexus>/bank-accounts

  List bank accouts managed by nexus.


.. http:post:: <nexus>/bank-accounts

  List bank accouts managed by nexus.


.. http:get:: <nexus>/bank-accounts/{acctid}/history

  :query method: Method to query the bank transaction (cached, ebics, fints, ...)

  Query the transaction history of an account via the specified method.


.. http:get:: <nexus>/bank-accounts/{acctid}/payments

  List payments made with this bank account via nexus.

.. http:post:: <nexus>/bank-accounts/{acctid}/payments

  Initiate a payment.


Low-level EBICS API
-------------------

.. http:post:: <nexus>/ebics/subscribers

  Create a new subscriber.  Create keys for the subscriber that
  will be used in later operations.

  .. ts:def:: NexusEbicsCreateSubscriber

    interface NexusEbicsCreateSubscriber {
      ebicsUrl: string;
      hostID: string;
      partnerID: string;
      userID: string;
      systemID: string?
    }


.. http:get:: <nexus>/ebics/subscribers

  List EBICS subscribers managed by nexus.


.. http:get:: <nexus>/ebics/subscribers/{id}

  Get details about an EBICS subscriber.


.. http:post:: <nexus>/ebics/subscriber/{id}/keyletter

  Get a nicely formatted key letter.  (Does not return JSON, but markdown-formatted text)


.. http:post:: <nexus>/ebics/subscriber/{id}/sendIni

  Send INI message to the EBICS host.


.. http:post:: <nexus>/ebics/subscriber/{id}/sendHia

  Send HIA message to the EBICS host.

.. http:post:: <nexus>/ebics/subscriber/{id}/sync

  Synchronize with the EBICS server.  Sends the HPB message
  and updates the bank's keys.

.. http:post:: <nexus>/ebics/subscriber/{id}/sendEbicsOrder

  Sends an arbitrary bank-technical EBICS order.  Can be an upload
  order or a download order.

  .. ts:def:: NexusEbicsSendOrderRequest::

    interface NexusEbicsSendOrderRequest {
      // Bank-technical order type, such as C54 (query transactions)
      // or CCC (initiate payment)
      orderType: string;

      // Generic order parameters, such as a date range for querying
      // an account's transaction history.
      orderParams: OrderParams

      // Body (XML, MT940 or whatever the bank server wants)
      // of the order type, if it is an upload order
      orderMessage: string;
    }


.. http:post:: <nexus>/ebics/subscriber/{id}/ebicsOrders

  .. note::

    This one should be implemented last and specified better!

  Return a list of previously sent ebics messages together with their status.
  This allows retrying sending a message, if there was a crash during sending
  the message.
