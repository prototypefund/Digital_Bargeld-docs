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

  .. ts:def:: CustomerInfo

    interface CustomerInfo {
      ebicsInfo?: CustomerEbicsInfo;
      finTsInfo?: CustomerFinTsInfo;
    }

  .. ts:def:: CustomerEbicsInfo

    interface CustomerEbicsInfo {
      ebicsHostId: string;
      ebicsParterId: string;
      ebicsUserId: string;

      // Info for the customer's "main subscriber"
      subscriberInitializationState: "NEW" | "PARTIALLY_INITIALIZED_INI" | "PARTIALLY_INITIALIZED_HIA" | "READY" | "INITIALIZED";
    }

  .. ts:def:: CustomerFinTsInfo
    
    // TODO

.. http:post:: /admin/customers/:id/ebics/keyletter

  Accept the information from the customer's ("virtual") INI-Letter and HIA-Letter
  and change the key's state as required.

  .. code-block:: tsref

    interface KeyLetterRequest {

      INI: {
        // The user ID that participates in a EBICS subscriber.
        userId: string;

        // The customer ID specific to the bank (therefore not
        // participating in a EBICS subscriber).
        customerId: string;

        // Human name of the user
        name: string;

        // Date of key creation.  DD.MM.YYYY format.
        date: string;

        // Time of key creation.  HH:MM:SS format.
        time: string;

        // Recipient.  Bank "ID" (FIXME to be specified).
        recipient: string;

        // Electronic signature version.  A004, for example.
        es_version: string;

        // RSA key exponent
        exponent: string;

        // RSA key modulus
        modulus: string;

        // RSA key hash
        hash: string;
    }

      HIA: {
        // The user ID that participates in a EBICS subscriber.
        userId: string;

        // The customer ID specific to the bank (therefore not
        // participating in a EBICS subscriber).
        customerId: string;

        // Human name of the user
        name: string;

        // Date of key creation.  DD.MM.YYYY format.
        date: string;

        // Time of key creation.  HH:MM:SS format.
        time: string;

        // Recipient.  Bank "ID" (FIXME to be specified).
        recipient: string;

        // Identification and authentication signature version, X002 for example.
        ia_version: string;

        // Encryption version, E002 for example.
        enc_version: string;

        // RSA key exponent
        exponent: string;

        // RSA key modulus
        modulus: string;

        // RSA key hash
        hash: string;
      }
    } 
