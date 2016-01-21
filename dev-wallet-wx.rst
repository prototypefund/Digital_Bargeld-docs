=====================
WebExtensions Wallet
=====================

------------
Introduction
------------

The WebExtensions Wallet (*wxwallet*) can be used to pay with GNU Taler on web
sites from within modern web browsers.  The `WebExtensions
<https://wiki.mozilla.org/WebExtensions>`_ API interface that enables the
development cross-browser extensions.  Google Chrome / Chromium, Mozilla
Firefox, Opera and Microsoft Edge will all offer support for WebExtensions in
the future.

Currently Chrome hast the best support for WebExtensions (since the API is a superset
of Chrome's extension API).

-----------------------
Development Environment
-----------------------

The *wxwallet* mainly written in the `TypeScript
<http://www.typescriptlang.org/>`_ language, which is a statically typed
superset of JavaScript.

While the *wxwallet* is mainly intended to be run from inside a browser, the
logic is implemented in browser-independent modules that can also be called
from other environments such as `nodejs <https://nodejs.org>`_.  This is
especially useful for automatically running unit tests.


-----------------
Project Structure
-----------------

.. parsed-literal::
  
  **manifest.json**               extension configuration
  **package.json**                node.js package configuration
  **tsconfig.json**               TypeScript compiler configuration
  **lib/**
      **vendor/**                 3rd party libraries
      **wallet/**                 actual application logic
      **emscripten/**             emscripten object file and glue
  **test/**
       **run_tests.js**           nodejs entry point for tests
       **tests/**                 test cases
  **content_scripts/notify.ts**   wallet<->website signaling
  **backgrond/main.ts**           backend entry point
  **img/**                        static image resources
  **style/**                      CSS stylesheets
  **pages/**                      pages shown in browser tabs
  **popup/**                      pages shown the extension popup

----------
Emscripten
----------

`Emscripten <https://kripken.github.io/emscripten-site/index.html>`_ is C/C++
to JavaScript compiler.  Emscripten is used in the *wxwallet* to access
low-level cryptography from *libgcrypt*, and miscellaneous functionality from
*libgnunetutil* and *libtalerwallet*.


--------------------------------------
Target Environments and Modularization
--------------------------------------

Modules in the wallet are declared in TypeScript with
the ES6 module syntax.  These modules are then compiled
to `SystemJS <https://github.com/systemjs/systemjs>`_ `register` modules.

SystemJS modules can be loaded from the browser as well as from nodejs.
However they require special entry points that configure the module system,
load modules and execute code.  Examples are `backgrond/main.ts` for the
browser and `test/run_tests.js` for nodejs.

Note that special care has to be taken when loading the Emscript code,
as it is not compatible with the SystemJS module, even in the `globals`
compatibility mode.

The TypeScript sources in the *wxwallet* are compiled down to ES5, both to
enable running in node.js without transpilers and to avoid a `bug
<https://github.com/Microsoft/TypeScript/issues/6426>`_ in the TypeScript
compiler.

----------------------------
IndexedDB Query Abstractions
----------------------------

The *wxwallet* uses a fluent-style API for queries on IndexedDB.

TODO: say more about this


-------
Testing
-------

Test cases for the wallet are written in TypeScript and
run with `mochajs <http://mochajs.org/>`_ and the `better-assert <https://github.com/tj/better-assert>`_ assertion
library.

Run the default test suite with ``XXX``.

