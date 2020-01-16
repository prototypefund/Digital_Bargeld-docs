GNU Taler bank manual
#####################

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

About this manual
-----------------

This manual documents how the demonstrator bank interoperates with the
other GNU Taler components. The demonstrator bank implements a simple
closed banking system for the purpose of illustrating how GNU Taler
works in the Taler demo. It could also be used as a starting point for a
local/regional currency. Finally, “real” banks might use it as a
reference implementation for a tight integration with the GNU Taler
wallet.

Headless Testing API Reference
==============================

The demonstrator bank offers the following APIs to allow automated testing.  These APIs should
be switched off during a production deployment.


.. _bank-register:
.. http:post:: /register

  This API provides programmatic user registration at the bank.

  **Request** The body of this request must have the format of a
  `BankRegistrationRequest`.

  **Response**

  :status 200 OK:
    The new user has been correctly registered.
  :status 409 Conflict:
    The username requested by the client is not available anymore.
  :status 400 Bad Request:

    * Unacceptable characters were given for the username. See
      https://docs.djangoproject.com/en/2.2/ref/contrib/auth/#django.contrib.auth.models.User.username
      for the accepted character set.

**Details**

.. ts:def:: BankRegistrationRequest

  interface BankRegistrationRequest {
  
    // Username to use for registration; max length is 150 chars.
    username: string;

    // Password to associate with the username.  Any characters and
    // any length are valid; next releases will enforce a minimum length
    // and a safer characters choice.
    password: string;
  }


