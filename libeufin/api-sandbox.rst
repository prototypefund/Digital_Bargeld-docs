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

        // As per specification, this value is:
        // "Date of processing of the corresponding EBICS order".  DD.MM.YYYY format.
        date: string;

        // As per specification, this value is:
        // "Time of processing of the corresponding EBICS order".  HH:MM:SS format.
        time: string;

        // Recipient.  Bank "ID" (FIXME to be specified).
        recipient: string;

        // Electronic signature version.  A004, for example.
        es_version: string;

        // RSA key exponent
        exponent_length: number;
        exponent: string;

        // RSA key modulus
        modulus_length: number;
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

        // As per specification, this value is:
        // "Date of processing of the corresponding EBICS order".  DD.MM.YYYY format.
        date: string;

        // As per specification, this value is:
        // "Time of processing of the corresponding EBICS order".  HH:MM:SS format.
        time: string;

        // Recipient.  Bank "ID" (FIXME to be specified).
        recipient: string;

        ////////////////////////////////////////////////////
        // Identification and authentication key details. //
        ////////////////////////////////////////////////////

        // Identification and authentication signature version, X002
        // for example.
        ia_version: string;

        // length of the exponent, in bits.
        ia_exp_length: number;
        // RSA key exponent
        ia_exponent: string;

        // length of the modulus, in bits.
        ia_mod_length: number;
        // RSA key modulus
        ia_modulus: string;

        // Hash of the identification and authentication key.
        ia_hash: string;

        /////////////////////////////
        // Encryption key details. //
        /////////////////////////////

        // Encryption version, E002 for example.
        enc_version: string;

        // length of the exponent, in bits.
        enc_exp_length: number;
        // RSA key exponent
        enc_exponent: string;

        // length of the modulus, in bits.
        enc_mod_length: number;
        // RSA key modulus
        enc_modulus: string;

        // RSA key hash.
        enc_hash: string;
      }
    } 
