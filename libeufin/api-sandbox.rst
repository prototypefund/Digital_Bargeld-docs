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

      ini: {
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

        // Identification token of the bank.  Not required to obey to any particular standard.
        recipient: string;

        // Electronic signature version.  Admitted values: A004, A005, A006.
        version: string;

        // Length in bits of the key exponent.
        public_exponent_length: number;
        // RSA key exponent in hexadecimaml notation.
        public_exponent: string;

        // Length in bits of the key modulus.
        public_modulus_length: number;
        // RSA key modulus in hexadecimaml notation.
        public_modulus: string;

        // RSA key hash.
        //
        // A004 version requires hash type RIPEMD-160
        // A005, A005 versions require hash type SHA-256.
        hash: string;
      }

      hia: {
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
  
        // Identification token of the bank.  Not required to obey to any particular standard.
        recipient: string;
  
        ////////////////////////////////////////////////////
        // Identification and Authentication key details. //
        ////////////////////////////////////////////////////
  
        // Identification and authentication signature version.
        // Admitted value: X002.
        ia_version: string;
  
        // length of the exponent, in bits.
        ia_public_exponent_length: number;
        // RSA key exponent in hexadecimaml notation.
        ia_public_exponent: string;
  
        // length of the modulus, in bits.
        ia_public_modulus_length: number;
        // RSA key modulus in hexadecimaml notation.
        ia_public_modulus: string;
  
        // SHA-256 hash of the identification and authentication key.
        ia_hash: string;
  
        /////////////////////////////
        // Encryption key details. //
        /////////////////////////////
  
        // Encryption version.  Admitted value: E002.
        enc_version: string;
  
        // length of the exponent, in bits.
        enc_public_exponent_length: number;
        // RSA key exponent in hexadecimaml notation.
        enc_public_exponent: string;
  
        // length of the modulus, in bits.
        enc_public_modulus_length: number;
        // RSA key modulus in hexadecimaml notation.
        enc_public_modulus: string;
  
        // SHA-256 hash of the encryption key.
        enc_hash: string;
      }
    } 
