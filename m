From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 25 Sep 2026 00:23:37 +0200
Subject: [PATCH 09/10] test: mount the service examples through
 fuservicemount3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-mount-service-bound-open-v1-9-bbf1a84c7995@bsbernd.com>
References: <20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com>
In-Reply-To: <20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=5702; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=ZjVhclM5VaRPOhRsLbvxcnJ4p7C2UM1NZ48bT+7OZ0s=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLK2LnrGof3sf7vFvQVfz/Ate67Mc9V4crhUDafwgbJ9c
 sePKr3v7ShlYRDjYJAVU2TpkthjO+Ufn6za1/XXYeawMoEMYeDiFICJBKYw/DMSb4i47H2iM+rx
 X7nPejPTP6rLZJ6SP7mFd1GL/bO9W3kZGXobIkTySi4v2KhqfO19o+iu+St8F75UXe3LzjrjaF1
 vJjcA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No test ran service_ll, service_hl or null in service mode. No test
checked that mount.fuse3 mounts through a listening service socket, and
runs the filesystem program when the socket refuses the connection.

Assisted-by: LLM
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 test/cases/lib/service-example.sh      | 62 ++++++++++++++++++++++++++++++++++
 test/cases/mount/service-hl.sh         |  7 ++++
 test/cases/mount/service-ll.sh         |  7 ++++
 test/cases/mount/service-mount-fuse.sh | 31 +++++++++++++++++
 test/cases/mount/service-null.sh       | 33 ++++++++++++++++++
 5 files changed, 140 insertions(+)

diff --git a/test/cases/lib/service-example.sh b/test/cases/lib/service-example.sh
new file mode 100644
index 000000000000..878b379b8b16
--- /dev/null
+++ b/test/cases/lib/service-example.sh
@@ -0,0 +1,62 @@
+# lib/service-example.sh - body for the service_ll / service_hl cases.
+#
+# Caller sets FS_NAME and LAUNCH before sourcing:
+#   FS_NAME   service_ll | service_hl
+#   LAUNCH    fuservicemount3 | mount_fuse
+#
+# The file the example serves has to read back as the image, and what is
+# written through the mount has to reach the image.
+
+_fuse_no_mount_needed=1
+. "$TEST_LIB/common.sh"
+
+# Before the gates: a misspelled FS_NAME would otherwise skip as "not built"
+case ${FS_NAME:-} in
+service_ll | service_hl) ;;
+*) _fail "unknown FS_NAME '${FS_NAME:-}'" ;;
+esac
+case ${LAUNCH:-} in
+fuservicemount3 | mount_fuse) ;;
+*) _fail "unknown LAUNCH '${LAUNCH:-}'" ;;
+esac
+
+_require_linux "fuservicemount3"
+_require_root
+_require_fuse_device
+_require_binary util/fuservicemount3
+_require_binary "example/$FS_NAME"
+[ "$LAUNCH" != mount_fuse ] || _require_binary util/mount.fuse3
+
+. "$TEST_LIB/service.sh"
+
+service_setup "test-$FS_NAME-$$"
+img=$TEST_SRC/img
+old=$TEST_TMP/old
+new=$TEST_TMP/new
+
+# The size has to be a multiple of the page size
+head -c 1048576 /dev/urandom >"$old"
+head -c 1048576 /dev/urandom >"$new"
+cp "$old" "$img"
+
+service_start "$TEST_LOGDIR/fs-$FS_NAME.out" "$FUSE_EXAMPLE_DIR/$FS_NAME"
+case $LAUNCH in
+fuservicemount3)
+	"$FUSE_UTIL_DIR/fuservicemount3" "$img" "$TEST_MNT" \
+		-t "fuse.$service_subtype" ||
+		_fail "fuservicemount3 did not mount $FS_NAME"
+	;;
+mount_fuse)
+	"$FUSE_UTIL_DIR/mount.fuse3" "$service_subtype#$img" "$TEST_MNT" ||
+		_fail "mount.fuse3 did not mount $FS_NAME"
+	;;
+esac
+
+_assert_fstype "$TEST_MNT" "fuse.$service_subtype" fuse
+_assert_file_eq "$TEST_MNT/single_file" "$old"
+dd if="$new" of="$TEST_MNT/single_file" bs=64k conv=notrunc,fsync status=none
+
+umount "$TEST_MNT"
+service_wait_exit
+_assert_eq "$service_rc" 0 "$FS_NAME exit status"
+_assert_file_eq "$img" "$new"
diff --git a/test/cases/mount/service-hl.sh b/test/cases/mount/service-hl.sh
new file mode 100755
index 000000000000..6db3add3a5d1
--- /dev/null
+++ b/test/cases/mount/service-hl.sh
@@ -0,0 +1,7 @@
+#!/usr/bin/env bash
+# GROUP: mount
+
+FS_NAME=service_hl
+LAUNCH=fuservicemount3
+
+. "$TEST_LIB/service-example.sh"
diff --git a/test/cases/mount/service-ll.sh b/test/cases/mount/service-ll.sh
new file mode 100755
index 000000000000..036553889f7a
--- /dev/null
+++ b/test/cases/mount/service-ll.sh
@@ -0,0 +1,7 @@
+#!/usr/bin/env bash
+# GROUP: mount
+
+FS_NAME=service_ll
+LAUNCH=fuservicemount3
+
+. "$TEST_LIB/service-example.sh"
diff --git a/test/cases/mount/service-mount-fuse.sh b/test/cases/mount/service-mount-fuse.sh
new file mode 100755
index 000000000000..6bc95240c772
--- /dev/null
+++ b/test/cases/mount/service-mount-fuse.sh
@@ -0,0 +1,31 @@
+#!/usr/bin/env bash
+# GROUP: mount
+#
+# mount.fuse3 mounts through the service when its socket listens, and execs a
+# program named after the type when the socket refuses the connection.
+
+_fuse_no_mount_needed=1
+. "$TEST_LIB/common.sh"
+
+_require_binary example/hello
+
+FS_NAME=service_ll
+LAUNCH=mount_fuse
+
+. "$TEST_LIB/service-example.sh"
+
+fallback=test-fallback-$$
+service_setup "$fallback"
+
+# Bound but never listening, so connect() gets ECONNREFUSED
+python3 -c 'import socket, sys
+socket.socket(socket.AF_UNIX, socket.SOCK_SEQPACKET).bind(sys.argv[1])' \
+	"$service_sock"
+
+mkdir "$TEST_TMP/bin"
+ln -s "$FUSE_EXAMPLE_DIR/hello" "$TEST_TMP/bin/$fallback"
+export PATH="$TEST_TMP/bin:$PATH"
+
+fuse_mount_helper "$fallback" >/dev/null
+_assert_listdir "$TEST_MNT" hello
+fuse_umount
diff --git a/test/cases/mount/service-null.sh b/test/cases/mount/service-null.sh
new file mode 100755
index 000000000000..b89107ae3a40
--- /dev/null
+++ b/test/cases/mount/service-null.sh
@@ -0,0 +1,33 @@
+#!/usr/bin/env bash
+# GROUP: mount
+#
+# The null example mounts through fuservicemount3 on a regular file.
+# null has no backing file and mounts on a regular file, so it does not use
+# lib/service-example.sh.
+
+_fuse_no_mount_needed=1
+. "$TEST_LIB/common.sh"
+
+_require_linux "fuservicemount3"
+_require_root
+_require_fuse_device
+_require_binary util/fuservicemount3
+_require_binary example/null
+
+. "$TEST_LIB/service.sh"
+
+service_setup "test-null-$$"
+mnt_file=$TEST_TMP/file
+_at_exit "umount -l '$mnt_file' 2>/dev/null"
+printf 'dummy' >"$mnt_file"
+
+service_start "$TEST_LOGDIR/fs-null.out" "$FUSE_EXAMPLE_DIR/null"
+# null takes no source, only the mount point
+"$FUSE_UTIL_DIR/fuservicemount3" "$mnt_file" -t "fuse.$service_subtype" ||
+	_fail "fuservicemount3 did not mount null"
+
+_check fuse_test_null_roundtrip "$mnt_file"
+
+umount "$mnt_file"
+service_wait_exit
+_assert_eq "$service_rc" 0 "null exit status"

-- 
2.53.0

