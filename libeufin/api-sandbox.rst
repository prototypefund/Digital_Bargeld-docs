Sandbox API
###########


Entities
========

Customer
  ...

Bank Account
  ...

EBICS Subscriber
  ...


Assumption for sandbox:  One customer corresponds to exactly one EBICS subscriber.


HTTP API
========


.. http:post:: /ebicsweb

  Submit an EBICS request to the sandbox.


.. http:post:: /admin/customers

  Create a new customer.  A customer identifies a human that
  may own multiple bank accounts.

  When creating a customer, one EBICS subscriber is automatically
  created for the customer.

  In the future, we might add an API to create multiple additional subscribers for
  a customer.

  When creating a new customer, an ID will be assigned automatically.

  .. code-block:: tsref

    interface CustomerCreationRequest {
      // human-readable name for the customer
      name: string;
    }

.. http:get:: /admin/customers/:id

  Get information about a customer.

  
  .. code-block:: tsref

    interface CustomerInfo {
      ebicsInfo?: CustomerEbicsInfo;
      finTsInfo?: CustomerFinTsInfo;
    }

    interface CustomerEbicsInfo {
      ebicsHostId: string;
      ebicsParterId: string;
      ebicsUserId: string;

      // Info for the customer's "main subscriber"
      subscriberInitializationState: "NEW" | "PARTIALLY_INITIALIZED_INI" | "PARTIALLY_INITIALIZED_HIA" | "READY" | "INITIALIZED";
    }

.. http:post:: /admin/customers/:id/ebics/keyletter

  Accept the information from the customer's ("virtual") INI-Letter and HIA-Letter
  and change the key's state as required.

  .. code-block:: tsref

    interface KeyLetterRequest {
      partnerId: string;
      userId: string;
      // FIXME: other fields: see spec and put here
    }
