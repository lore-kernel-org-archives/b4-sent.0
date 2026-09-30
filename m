From: Bernd Schubert <bernd@bsbernd.com>
Subject: [PATCH v3 00/15] libfuse: Add mount service safety checks and
 tests
Date: Wed, 30 Sep 2026 15:10:54 +0200
Message-Id: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32N0Q6CIBhGX6VxHQ1QVLrqPVoXgj9Jm+BAWc357
 oGtrS7q8mzfd86CAngDAR13C/IQTTDOJij2O6T61l4Bmy4xYoRVRLASD262E06vaBRgmajDbgS
 L60JIWrGikrpF6T560Oa+qc+XF4dZ3kBN2ZcXvQmT84+tHWnevTP8dyZSTLCUmrZNqWoh+EkGC
 d52B+UGlEORfaqaPyqWVEQLzQntCFfwrVrX9Qm40cf/HwEAAA==
X-Change-ID: 20260924-mount-service-bound-open-739b16236bfa
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, neal@gompa.dev, 
 Bernd Schubert <bernd@bsbernd.com>, 
 Keerthana KT <keerthana@labs.digiscrypt.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=4665; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=FoXEEtMhDrRmY6HlpOqpQDGSeYoe5RzNo2MwXJ4eHMc=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL2ciXuM3fP4SlXs9hVFq9zYYrO3PK45ki/yanvfnZHs
 6QwXXrWUcrCIMbBICumyNIlscd2yj8+WbWv66/DzGFlAhnCwMUpABP5FMrI8H/PTnU3TvV9YR/N
 daReP7OxuLFAtHL/quOPPyR9nbZn93uGf/b+9U85NFu/HjyW2r2Zj++bmfJuWfHPwa/DE1IcjuR
 uZgQA
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
Changes in v3:
- Address all Darricks review comments
	- Allow "*" as subtype for service_open_path config option
	- Use sysconf(_SC_ARG_MAX)
	- Also check that pos + len do not exceed memdfd file size
	- Slight documentation wording improvement
- Move fuse_service_priv.h from include/ to lib/
- Link to v2: https://patch.msgid.link/20260928-mount-service-bound-open-v2-0-0f9f501d05ce@bsbernd.com

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
Bernd Schubert (14):
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
      move fuse_service_priv.h from include/ to lib/

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
 lib/fuse_service.c                      |  40 +++
 {include => lib}/fuse_service_priv.h    |  10 +
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
 test/test_fuser_conf.c                  |  59 +++++
 test/test_service.c                     | 232 ++++++++++++++++
 util/fuse.conf                          |  12 +
 util/fuser_conf.c                       | 106 ++++++++
 util/fuser_conf.h                       |   3 +
 util/meson.build                        |   2 +
 util/mount.fuse.c                       |  42 +--
 util/mount_service.c                    | 128 +++++++--
 38 files changed, 2360 insertions(+), 42 deletions(-)
---
base-commit: bf4fdf9df8e2d33393894d0789f89e17520944f0
change-id: 20260924-mount-service-bound-open-739b16236bfa

Best regards,
--  
Bernd Schubert <bernd@bsbernd.com>

