################################
GNU Taler Demo Upgrade Checklist
################################

.. |check| raw:: html

    <input checked="" type="checkbox">

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
