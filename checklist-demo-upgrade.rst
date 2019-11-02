################################
GNU Taler Demo Upgrade Checklist
################################

.. |check| raw:: html

    <input type="checkbox">

Post-upgrade checks:

- |check| Run ``taler-deployment-arm -I`` to verify that all services are running.
- |check| Run the headless wallet to check that services are actually working:

  .. code-block:: sh

    taler-wallet-cli integrationtest -e https://exchange.demo.taler.net/ -m https://backend.demo.taler.net/ -b https://bank.demo.taler.net -w "KUDOS:10" -s "KUDOS:5"

Basics:

- |check| Visit https://demo.taler.net/ to see if the landing page is displayed correctly
- |check| Visit the wallet installation page, install the wallet, and see if the presence
  indicator is updated correctly.
- |check| Visit https://bank.demo.taler.net/, register a new user and withdraw coins into the
  browser wallet.


Blog demo:

- |check| Visit https://shop.demo.taler.net/ and purchase an article.
- |check| Verify that the balance in the wallet was updated correctly.
- |check| Go back to https://shop.demo.taler.net/ and click on the same article
  link.  Verify that the article is shown and **no** repeated payment is
  requested.
- |check| Open the fulfillment page from the previous step in an anonymous browsing session
  (without the wallet installed) and verify that it requests a payment again.
- |check| Delete cookies on https://shop.demo.taler.net/ and click on the same article again.
  Verify that the wallet detects that the article has already purchased and successfully
  redirects to the article without spending more money.

Donation demo:

- |check| Make a donation on https://donations.demo.taler.net
- |check| Make another donation with the same parameters and verify
  that the payment is requested again, instead of showing the previous
  fulfillment page.

Survey/Tipping:

- |check| Visit https://survey.demo.taler.net/ and receive a tip.
- |check| Verify that the survey stats page (https://survey.demo.taler.net/survey-stats) is working,
  and that the survey reserve has sufficient funds.
