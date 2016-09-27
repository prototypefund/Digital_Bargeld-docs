===================
Deployment Protocol
===================

------
Wallet
------

.. code-block:: none

  cd wallet-webex

  # check dependencies
  ./configure

  # edit version and version_name
  $EDITOR manifest.json

  make package-stable

The built wallet is now ready in `taler-wallet-stable-${version_name}${version}.zip`.  

FIXME:  here, we should do some semi-automated testing with selenium, to see
that everything works against `demo.taler.net`.

The package can now be uploaded to https://chrome.google.com/webstore/developer/dashboard

FIXME:  include asset links and descriptions we use in the webstore in this document

FIXME:  include instructions for other app stores


--------------------
Deploying to stable
--------------------

For all repositories that have a separate stable branch (currently exchange.git,
merchant.git, merchant-frontends.git, bank.git, landing.git) do:

.. code-block:: none

  cd $REPO
  git pull
  git checkout stable
  
  # option a: resolve conflicts resulting from hotfixes
  git merge master
  ...

  # option b: force stable to master
  git update-ref refs/heads/stable master

  git push # possible with --force

  # continue development
  git checkout master

