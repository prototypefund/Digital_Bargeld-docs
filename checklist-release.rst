###########################
GNU Taler Release Checklist
###########################


Release checklists for GNU Taler:

Wallet:

- [ ] build wallet
- [ ] verify wallet works against 'test.taler.net'
- [ ] tag repo.
- [ ] upgrade 'demo.taler.net' to 'test.taler.net'
- [ ] upload new wallet release to app store
- [ ] Update bug tracker (mark release, resolved -> closed)
- [ ] Send announcement to taler@gnu.org
- [ ] Send announcement to info-gnu@gnu.org (major releases only)
- [ ] Send announcement to coordinator@translationproject.org

For exchange:

- [ ] check no compiler warnings at "-Wall"
- [ ] ensure Coverity static analysis passes
- [ ] make check.
- [ ] upgrade 'demo.taler.net' to 'test.taler.net'
- [ ] make dist, make check on result of 'make dist'.
- [ ] Change version number in configure.ac.
- [ ] make dist for release.
- [ ] tag repo.
- [ ] Upload triplet to ftp-upload.gnu.org/incoming/ftp or /incoming/alpha
- [ ] Update bug tracker (mark release, resolved -> closed)
- [ ] Send announcement to taler@gnu.org
- [ ] Send announcement to info-gnu@gnu.org (major releases only)
- [ ] Send announcement to coordinator@translationproject.org

For merchant (C backend):

- [ ] check no compiler warnings at "-Wall"
- [ ] ensure Coverity static analysis passes
- [ ] make check.
- [ ] upgrade 'demo.taler.net' to 'test.taler.net'
- [ ] make dist, make check on result of 'make dist'.
- [ ] Change version number in configure.ac.
- [ ] make dist for release.
- [ ] tag repo.
- [ ] Upload triplet to ftp-upload.gnu.org/incoming/ftp or /incoming/alpha
- [ ] Update bug tracker (mark release, resolved -> closed)
- [ ] Send announcement to taler@gnu.org
- [ ] Send announcement to info-gnu@gnu.org (major releases only)
- [ ] Send announcement to coordinator@translationproject.org

For bank:

- TBD

For Python merchant frontend:

- TBD

For PHP merchant frontend:

- TBD

For auditor:

- TBD

For libebics:

- TBD
