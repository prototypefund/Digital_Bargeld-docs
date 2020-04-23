Design Doc 004: Wallet Withdrawal Flow
######################################

Summary
=======

This document describes the recommended way of implementing the user experience
of withdrawing digital cash in GNU Taler wallets.

Motivation
==========

When digital cash is withdrawn, it is tied to and in custody of an exchange.
There can be many exchanges offered by different entities,
each having their custom legal agreement documents and fee structures.
The user is free to choose an exchange.
Therefore, the process of withdrawing needs to account for this choice.

Proposed Solution
=================

There are three screens involved in the process:

1. **Select exchange**:
   Here the user can pick an exchange from a list of known exchanges
   or add a new one for immediate use.
   For details see :doc:`002-wallet-exchange-management`.
2. **Display an exchange's Terms of Service**:
   Shows the terms and gives an option to accept them.
   For details see :doc:`003-tos-rendering`.
3. **Withdrawal details and confirmation**:
   This should show the amount to be withdrawn along with its currency,
   the currently selected exchange and the fee charged by it for the withdrawal.

The user flow between these screens is described in the following graph:

.. graphviz::

   digraph G {
       rankdir=LR;
       nodesep=0.5;
       default_exchange [
           label = "Has default\nexchange?";
           shape = diamond;
       ];
       tos_changed [
           label = "ToS\nchanged?";
           shape = diamond;
       ];
       tos_accepted [
           label = "ToS\naccepted?";
           shape = diamond;
       ];
       accept_tos [
           label = "Accept\nToS?";
           shape = diamond;
       ];
       withdrawal_action [
           label = "Withdrawal\nAction";
           shape = diamond;
       ];
       select_exchange [
           label = "Select\nexchange";
           shape = rect;
       ];
       tos [
           label = "ToS";
           shape = rect;
       ];
       withdraw [
           label = "Confirm\nwithdrawal";
           shape = rect;
       ];
       transactions [
           label = "Transactions";
           shape = circle;
       ];

       default_exchange -> tos_changed [label="Yes"];
       default_exchange -> select_exchange [label="No"];
       tos_changed -> tos [label="Yes"];
       tos_changed -> withdraw [label="No"];
       select_exchange -> tos_accepted;
       tos_accepted -> tos_changed [label="Yes"];
       tos_accepted -> tos [label="No"];
       tos -> accept_tos;
       accept_tos -> withdraw [label="Yes"];
       accept_tos -> select_exchange [label="No"];
       withdraw -> withdrawal_action;
       withdrawal_action -> transactions [label="Confirm"];
       withdrawal_action -> select_exchange [label="Change Exchange"];

       { rank=same; tos_accepted; tos_changed; }
       { rank=same; select_exchange; tos; }
       { rank=same; withdrawal_action; withdraw; }
   }

This enables the user to change the current exchange at any time in the process.
It ensures that the latest version of the exchange's terms of service have been accepted by the user
before allowing them to confirm the withdrawal.

Some special regional or test currencies might have only a single known exchange.
For those, the wallet should not offer the option to change an exchange.

Alternatives
============

We considered and rejected the following alternatives:

* Do not allow more than one exchange to make Taler simpler to use and understand:
  Taler wants to allow custom exchanges for custom currencies
  and foster competition between exchanges for the same currency
  to provide the best possible service to users at the lowest fee.
* Do not require acceptance to terms of service:
  Having these terms and prompting the user to accept them
  is a legal and business requirement in many jurisdictions,
  so Taler needs to support them.
  However, Taler encourages exchanges to keep their terms as short and simple as possible.

Discussion / Q&A
================

* Should wallets pre-set a default exchange for the most common currencies,
  so that users will not be burdened to understand exchanges and their fee structures
  when making their first withdrawal?
  This could increase user retention, but discourage
* What should happen when an exchange changes its terms of service
  and the user wants to use the funds stored there,
  but does not initiate a new withdrawal with that exchange?
