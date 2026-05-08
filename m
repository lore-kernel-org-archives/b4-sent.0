From: Bernd Schubert <bernd@bsbernd.com>
Subject: [PATCH 00/10] libfuse: new mount API and SYNC_INIT fixes and tests
Date: Fri, 08 May 2026 18:39:03 +0200
Message-Id: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3LywqDQAxG4VeRrBuYKg7aVyldaOZvm4WxTKYXE
 N/docsPztnIkRVOl2ajjI+6rlZxPjUkz8keYE3V1IY2hj4MbPjysr6t8F1/cJ4scYEXZxEZk8z
 diBip/q+Mf1L3623fD79W3+5rAAAA
X-Change-ID: 20260508-new-mount-fixes-and-tests-ccc9dcb39e66
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>, Miklos Szeredi <miklos@szeredi.hu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1680; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=2v1r4XDh5tkgXXWCZRwKyNwDkZGMrV74yU/deZwKn/s=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGDL/Ca4WWzZ5oWxGt755OM8Plzyt7OgvWlZnu9w4Cw2/v
 ZuhU7Kko5SFQYyDQVZMkaVLYo/tlH98smpf11+HmcPKBDKEgYtTACYid5bhf+w9Ca0lqwQ+7X7R
 KakvaDjFYyrTq4KDmQtbpkz+J5Pyv53hn0qfwcpAl9f/zqar/Q9kEDF7kCr4ztA3vJTRovlB7z1
 eVgA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several new tests and fixes for the new mount API.

To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
Bernd Schubert (8):
      test: register pytest run as a meson test
      Add tests to verify that mountinfo matches requested options
      test: assert ro/rw, nosuid/suid, nodev/dev round-trip via fsmount
      example: silence add_languages warning by setting 'native: false'
      mount: clarify kernel_opts vs mnt_opts vs flags in fuse_kern_fsmount
      fuse_daemonize_early_start: Disallow daemonization when already active.
      fuse mount: Do not set sync_init when sync_init was not used
      highlevel: Switch fuse_main_real_versioned() to fuse_daemonize_early()

Darrick J. Wong (2):
      New mount API: read-only option is for fsmount() and fsconfig()
      libfuse: don't use SYNC_INIT unless asked for

 example/meson.build      |   2 +-
 lib/fuse_daemonize.c     |   8 ++-
 lib/fuse_lowlevel.c      |  29 +++++---
 lib/helper.c             |  30 ++++++---
 lib/mount_fsmount.c      |  21 ++++--
 lib/mount_i_linux.h      |  13 +++-
 lib/mount_util.c         |  44 ++++++------
 lib/mount_util.h         |   3 +-
 test/ci-build.sh         |   9 ++-
 test/meson.build         |  26 ++++++--
 test/test_mount_state.py | 170 +++++++++++++++++++++++++++++++++++++++++++++++
 test/util.py             |  45 +++++++++++++
 12 files changed, 341 insertions(+), 59 deletions(-)
---
base-commit: e99b3d200c04464e0dc03f1e7fce8a7f3b95503d
change-id: 20260508-new-mount-fixes-and-tests-ccc9dcb39e66

Best regards,
-- 
Bernd Schubert <bernd@bsbernd.com>

