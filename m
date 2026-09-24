From: Bernd Schubert <bernd@bsbernd.com>
Subject: [PATCH 00/10] libfuse: Add mount service safety checks and tests
Date: Fri, 25 Sep 2026 00:23:28 +0200
Message-Id: <20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqEMAxA0atI1ga0Dh30KuKirVEzYCutiiDef
 aIu3+L/ExJFpgRNdkKknRMHLyjzDNxk/EjIvRhUoXRRqw/OYfMrSrWzI7SiHsNCHr9VbUutKm0
 HA5IvkQY+nnXbvU6b/ZFb7x9c1x/HXdkDfAAAAA==
X-Change-ID: 20260924-mount-service-bound-open-739b16236bfa
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=2509; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=3xEblVBSCa+QRcgBCx2b3N4O1pOM3iCEDdXrrcdlLXs=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLK2LnqcJqCtWfs9aElav/vVxfdV5de7r2kVejP3KvuGh
 bF2j8u8OkpYGMQ4GGTFFFm6JPbYTvnHJ6v2df11mDmsTCBDGLg4BWAid50Zfhz+/bo78duaE1wH
 E7zKbkSsaSvYc1t0VUNW3HZdM7PLugz/8+27mRbeKTU48rXrufv9qfoTEvpnzGmRZHppo+Ac8t+
 RDQA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

That was noticed by AI on comparison to systemd storage provider
and fuse service mount tests were missing as well.

To: fuse-devel@lists.linux.dev
Cc: Darrick J. Wong <djwong@kernel.org>

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
Bernd Schubert (10):
      mount_service: move the command line check into arg_in_cmdline()
      mount_service: open only paths named on the command line
      mount_service: refuse OPEN after the MNTPT request
      util: give fuservicemount3 an absolute build-tree runpath
      mount.fuse: free the options on the service mount return path
      example/single_file: take no sector size from a regular backing file
      test: check which files fuservicemount3 opens for the server
      test: check what fuservicemount3 refuses
      test: mount the service examples through fuservicemount3
      test: run mkfs.ext4 through the service examples

 .gitignore                              |   1 +
 doc/fuservicemount3.8                   |   5 +
 example/service_ll.c                    |   5 +
 example/single_file.c                   |   3 +-
 include/fuse_service.h                  |   6 +-
 test/cases/lib/service-example.sh       |  98 ++++++++++++++
 test/cases/lib/service.sh               |  93 +++++++++++++
 test/cases/lib/socket_activate.py       |  42 ++++++
 test/cases/mount/service-caps.sh        |  20 +++
 test/cases/mount/service-check.sh       |  38 ++++++
 test/cases/mount/service-hl-mkfs.sh     |   8 ++
 test/cases/mount/service-hl.sh          |   7 +
 test/cases/mount/service-ll-mkfs.sh     |   8 ++
 test/cases/mount/service-ll.sh          |   7 +
 test/cases/mount/service-mount-fuse.sh  |  31 +++++
 test/cases/mount/service-mountpoint.sh  |  36 +++++
 test/cases/mount/service-nonroot.sh     |  54 ++++++++
 test/cases/mount/service-null.sh        |  33 +++++
 test/cases/mount/service-open-bound.sh  |  46 +++++++
 test/cases/mount/service-server-exit.sh |  22 +++
 test/meson.build                        |   6 +
 test/test_service.c                     | 232 ++++++++++++++++++++++++++++++++
 util/meson.build                        |   2 +
 util/mount.fuse.c                       |  42 +++---
 util/mount_service.c                    |  58 +++++---
 25 files changed, 869 insertions(+), 34 deletions(-)
---
base-commit: e001ea32a977933236bcd928692c2c022594a41d
change-id: 20260924-mount-service-bound-open-739b16236bfa

Best regards,
--  
Bernd Schubert <bernd@bsbernd.com>

