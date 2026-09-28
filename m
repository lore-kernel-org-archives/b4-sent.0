From: Bernd Schubert <bernd@bsbernd.com>
Subject: [PATCH v2 00/14] libfuse: Add mount service safety checks and
 tests
Date: Mon, 28 Sep 2026 13:02:02 +0200
Message-Id: <20260928-mount-service-bound-open-v2-0-0f9f501d05ce@bsbernd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6CMBBFf4V07RhaXtaV/2FYMGWQmtCStjQaw
 r9bMC5dnuTec1bmyWny7JqtzFHUXluTQJwypsbOPAh0n5iJXNS5FCVMdjEB0itqRYCJerAzGWg
 KibwWRY1Dx9J9djTo16G+t1/2Cz5Jhd23L0btg3Xvox35vvtlqv+ZyCEHxIF3l1I1UlY39EjO9
 GdlJ9Zu2/YBzCy/1tQAAAA=
X-Change-ID: 20260924-mount-service-bound-open-739b16236bfa
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, neal@gompa.dev, 
 Bernd Schubert <bernd@bsbernd.com>, 
 Keerthana KT <keerthana@labs.digiscrypt.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=4201; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=ckHVGJEFaGVJTiLCGSLa28EbEN474uZYgSizuxnSUwk=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLJ2eVptfHy2/qv1cQ71Bceib5//0Z5TUPbC8rX1tjexL
 H4XWqcZd5SyMIhxMMiKKbJ0SeyxnfKPT1bt6/rrMHNYmUCGMHBxCsBEtB8xMrybJni9Z4nuOxGH
 ZGnTIv5VZrMe8nM0hGyZxjdT8X/1QWVGhllnQ2pXLnz48+28PyX7XoXqMyhIK9XKifeffB3Ke+k
 fNw8A
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

That was noticed by AI on comparison to systemd storage provider
and fuse service mount tests were missing as well.

To: fuse-devel@lists.linux.dev
Cc: Darrick J. Wong <djwong@kernel.org>
Cc: neal@gompa.dev

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
Changes in v2:
- Add more parsing logic to detect files to open from the command
  line and add admin overrides if the logic failed
- Allow open after mount, but use openat(), which avoids that
  files from the mount point are taken
- Add in '-d path' for mkfs.ext4 to copy in files for improved
  testing
- Add another sanity commit to limit max arg comand size
  (previously https://github.com/libfuse/libfuse/pull/1552)
- Change path to /run/fuse
- Add the documention patch
  (previously https://github.com/libfuse/libfuse/pull/1530)
- libfuse PR: https://github.com/libfuse/libfuse/pull/1638
- Link to v1: https://patch.msgid.link/20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com

---
Bernd Schubert (13):
      mount_service: move the command line check into arg_in_cmdline()
      mount_service: warn about paths not named on the command line
      mount_service: refuse paths the user did not name
      mount_service: use openat to OPEN paths
      util: give fuservicemount3 an absolute build-tree runpath
      mount.fuse: free the options on the service mount return path
      example/single_file: take no sector size from a regular backing file
      test: check which files fuservicemount3 opens for the server
      test: check what fuservicemount3 refuses
      test: mount the service examples through fuservicemount3
      test: run mkfs.ext4 through the service examples
      build: move the default service socket directory to /run/fuse
      Improve documentation for fuse service mount

Keerthana KT (1):
      fuse_service: bound argc and arg len read from the args memfd

 .gitignore                              |   1 +
 doc/README.service-mount                | 312 ++++++++++++++++++++++
 doc/README.service-mount-dev            | 456 ++++++++++++++++++++++++++++++++
 doc/README.service-mount-flow           | 201 ++++++++++++++
 doc/fuservicemount3.8                   | 164 +++++++++++-
 doc/mainpage.dox                        |  13 +
 doc/mount.fuse3.8                       |  25 ++
 example/service_ll.c                    |   5 +
 example/single_file.c                   |   3 +-
 include/fuse_service.h                  |   4 +-
 include/fuse_service_priv.h             |  10 +
 lib/fuse_service.c                      |  43 +++
 meson.build                             |   2 +-
 meson_options.txt                       |   2 +-
 test/cases/lib/service-example.sh       | 112 ++++++++
 test/cases/lib/service.sh               |  95 +++++++
 test/cases/lib/socket_activate.py       |  42 +++
 test/cases/mount/service-caps.sh        |  20 ++
 test/cases/mount/service-check.sh       |  38 +++
 test/cases/mount/service-hl-mkfs.sh     |   8 +
 test/cases/mount/service-hl.sh          |   7 +
 test/cases/mount/service-ll-mkfs.sh     |   8 +
 test/cases/mount/service-ll.sh          |   7 +
 test/cases/mount/service-mount-fuse.sh  |  31 +++
 test/cases/mount/service-mountpoint.sh  |  36 +++
 test/cases/mount/service-nonroot.sh     |  54 ++++
 test/cases/mount/service-null.sh        |  33 +++
 test/cases/mount/service-open-bound.sh  |  61 +++++
 test/cases/mount/service-server-exit.sh |  22 ++
 test/meson.build                        |   6 +
 test/test_fuser_conf.c                  |  55 ++++
 test/test_service.c                     | 232 ++++++++++++++++
 util/fuse.conf                          |  11 +
 util/fuser_conf.c                       |  99 +++++++
 util/fuser_conf.h                       |   3 +
 util/meson.build                        |   2 +
 util/mount.fuse.c                       |  42 +--
 util/mount_service.c                    | 128 +++++++--
 38 files changed, 2351 insertions(+), 42 deletions(-)
---
base-commit: e001ea32a977933236bcd928692c2c022594a41d
change-id: 20260924-mount-service-bound-open-739b16236bfa

Best regards,
--  
Bernd Schubert <bernd@bsbernd.com>

