===================
Deployment Protocol
===================

------
Wallet
------

.. code-block:: none

  $ cd wallet-webex

  # check dependencies
  $ ./configure

  # edit version and version_name
  $ $EDITOR manifest.json

  $ make package-stable

The built wallet is now ready in `taler-wallet-stable-${version_name}${version}.zip`.

FIXME:  here, we should do some semi-automated testing with selenium, to see
that everything works against `demo.taler.net`.

The package can now be uploaded to https://chrome.google.com/webstore/developer/dashboard

FIXME:  include asset links and descriptions we use in the webstore in this document

FIXME:  include instructions for other app stores

-----------------
Deploying to test
-----------------

1. From a clean home directory, first clone the deployment repository
.. code-block:: none
  
  $ git clone /var/git/deployment.git

2. Run the bootstrap script; this will checkout any needed repository
.. code-block:: none
  
  $ deployment/bootstrap-bluegreen test

3. Compile the project
.. code-block:: none
  
  $ source activate
  $ taler-deployment-build

4. Create exchange's keys

5. Sign exchange's /wire response

6. ?

--------------------
Deploying to stable
--------------------

First, make sure that the deployment *AND* the deployment scripts work on the `test.taler.net` deployment.

For all repositories that have a separate stable branch (currently exchange.git,
merchant.git, merchant-frontends.git, bank.git, landing.git) do:

.. code-block:: none

  $ cd $REPO
  $ git pull origin master stable
  $ git checkout stable

  # option a: resolve conflicts resulting from hotfixes
  $ git merge master
  $ ...

  # option b: force stable to master
  $ git update-ref refs/heads/stable master

  $ git push # possibly with --force

  # continue development
  $ git checkout master


Log into taler.net with the account that is *not* active by looking
at the `sockets` symlink of the `demo` account.

The following instructions wipe out the old deployment completely.

.. code-block:: none

  $ ls -l ~demo/sockets

  [...] sockets -> /home/demo-green/sockets/

In this case, `demo-green` is the active deployment, and `demo-blue` should be updated.
After the update is over, the `/home/demo/sockets` symlink will be pointed to `demo-blue`.

.. code-block:: none

  # Remove all existing files
  $ find $HOME -exec rm -fr {} \;

  $ git clone /var/git/deployment.git
  $ ./deployment/bootstrap-bluegreen demo

  # set environment appropriately
  $ . activate
  $ taler-deployment-build

  # upgrade the database!  this
  # process depends on the specific version

  $ taler-deployment-start

  # look at the logs, verify that everything is okay

Now the symlink can be updated.
