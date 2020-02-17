..
  This file is part of GNU TALER.

  Copyright (C) 2014-2020 Taler Systems SA

  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.

  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Florian Dold

=====================
Taler Bank Access API
=====================

This chapter describes the API that the GNU Taler demonstrator bank offers to access accounts.

This API differes from the "Bank Integration API" in that it provides advanced API access to accounts, as opposed
to enabling wallets to withdraw with an better user experience ("tight integration").


------------------------
Accounts and Withdrawals
------------------------

The following endpoints require HTTP "Basic" authentication with the account
name and account password, at least in the GNU Taler demo bank implementation.


.. http:get:: ${BANK_API_BASE_URL}/accounts/${account_name}/balance

  Request the current balance of an account.

  **Response**

  **Details**

  .. ts:def:: BankAccountBalanceResponse

    interface BankAccountBalanceResponse {
      // Amount with plus or minus sign, representing the current
      // available account balance.
      balance: SignedAmount;
    }


.. http:POST:: ${BANK_API_BASE_URL}/accounts/${account_name}/withdrawals

  Create a withdrawal operation, resulting in a ``taler://withdraw`` URI.

  **Response**

  **Details**

  .. ts:def:: BankAccountCreateWithdrawalResponse

    interface BankAccountCreateWithdrawalResponse {
      // ID of the withdrawal, can be used to view/modify the withdrawal operation
      withdrawal_id: string;

      // URI that can be passed to the wallet to initiate the withdrawal
      taler_withdraw_uri: string;
    }


.. http:POST:: ${BANK_API_BASE_URL}/accounts/${account_name}/withdrawals

  Create a withdrawal operation, resulting in a ``taler://withdraw`` URI.

  **Request**

  .. ts:def:: BankAccountCreateWithdrawalRequest

    interface BankAccountCreateWithdrawalRequest {
      // Amount to withdraw
      amount: Amount;
    }

  **Response**

  .. ts:def:: BankAccountCreateWithdrawalResponse

    interface BankAccountCreateWithdrawalResponse {
      // ID of the withdrawal, can be used to view/modify the withdrawal operation
      withdrawal_id: string;

      // URI that can be passed to the wallet to initiate the withdrawal
      taler_withdraw_uri: string;
    }


.. http:GET:: ${BANK_API_BASE_URL}/accounts/${account_name}/withdrawals/${withdrawal_id}

  Query the status of a withdrawal operation

  **Response**

  **Details**

  .. ts:def:: BankAccountGetWithdrawalResponse

    interface BankAccountGetWithdrawalResponse {
      // Amount that will be withdrawn with this withdrawal operation
      amount: Amount;

      // Was the withdrawal aborted?
      aborted: boolean;

      // Has the withdrawal been confirmed by the bank?
      // The wire transfer for a withdrawal is only executed once
      // both confirmation_done is true and selection_done is true.
      confirmation_done: boolean;

      // Did the wallet select reserve details?
      selection_done: boolean;

      // Reserve public key selected by the exchange,
      // only non-null if selection_done is 'true'
      selected_reserve_pub: string | null;

      // Exchange account selected by the exchange,
      // only non-null if selection_done is 'true'
      selected_exchange_account: string | null;
    }


.. http:POST:: ${BANK_API_BASE_URL}/accounts/${account_name}/withdrawals/${withdrawal_id}/abort

  Abort a withdrawal operation.  Has no effect on an already aborted withdrawal operation.

  :status 200 OK: The withdrawl operation has been aborted.  The response is an empty JSON object.
  :status 409 Conflict:  The reserve operation has been confirmed previously and can't be aborted.


.. http:POST:: ${BANK_API_BASE_URL}/accounts/${account_name}/withdrawals/${withdrawal_id}/confirm

  Confirm a withdrawal operation.  Has no effect on an already confirmed withdrawal operation.

  **Response**

  :status 200 OK: The withdrawl operation has been confirmed.  The response is an empty JSON object.
  :status 409 Conflict:  The reserve operation has been aborted previously and can't be confirmed.




----------------------
Registration (Testing)
----------------------


.. http:POST:: ${BANK_API_BASE_URL}/testing/register

  Create a new bank account.  This endpoint should be disabled for most deployments, but is useful
  for automated testing / integration tests.

  **Request**

  .. ts:def:: BankRegistrationRequest

    interface BankRegistrationRequest {
      username: string;

      password: string;
    }


  **Response**

  :status 200 OK:  Registration was successful
