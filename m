From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 25 Sep 2026 00:23:38 +0200
Subject: [PATCH 10/10] test: run mkfs.ext4 through the service examples
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-mount-service-bound-open-v1-10-bbf1a84c7995@bsbernd.com>
References: <20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com>
In-Reply-To: <20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=4794; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=Ks+Av68MNveryDmqSBWo5AgHNhrWPUQ1NSvO/GMgI+k=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLK2LnpeaLB486T+HvbQMEOza6dOP2hoZ52+XM/ot9e88
 pthu1bxdZSyMIhxMMiKKbJ0SeyxnfKPT1bt6/rrMHNYmUCGMHBxCsBEStoYGW7+37JonfXmXUeK
 87Yq8pet659/lumtp5vjlsRGsd+3tdoZGXY2VxscsnigX/FC22ZtI/vKhKC6mc09wSapdTx3uY0
 NOQA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The byte comparison in the service example tests does not show that a
real filesystem tool works on the file service_ll and service_hl serve.
mkfs.ext4 writes a filesystem through the mount, and e2fsck checks the
image after umount.

Assisted-by: LLM
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 example/service_ll.c                |  5 ++++
 test/cases/lib/service-example.sh   | 54 ++++++++++++++++++++++++++++++-------
 test/cases/mount/service-hl-mkfs.sh |  8 ++++++
 test/cases/mount/service-ll-mkfs.sh |  8 ++++++
 4 files changed, 66 insertions(+), 9 deletions(-)

diff --git a/example/service_ll.c b/example/service_ll.c
index fd43c40fc15b..7baf47905a33 100644
--- a/example/service_ll.c
+++ b/example/service_ll.c
@@ -43,6 +43,11 @@
  *
  *     mount -t fuse.service_ll /dev/sda /mnt
  *
+ * /mnt/single_file then holds the bytes of /dev/sda, so a filesystem can be
+ * created on it:
+ *
+ *     mkfs.ext4 /mnt/single_file
+ *
  * ## Source code ##
  * \include service_ll.c
  * \include service_ll.socket
diff --git a/test/cases/lib/service-example.sh b/test/cases/lib/service-example.sh
index 878b379b8b16..4d7e0b27f3b9 100644
--- a/test/cases/lib/service-example.sh
+++ b/test/cases/lib/service-example.sh
@@ -1,15 +1,19 @@
 # lib/service-example.sh - body for the service_ll / service_hl cases.
 #
-# Caller sets FS_NAME and LAUNCH before sourcing:
+# Caller sets FS_NAME and LAUNCH, and optionally CHECK, before sourcing:
 #   FS_NAME   service_ll | service_hl
 #   LAUNCH    fuservicemount3 | mount_fuse
+#   CHECK     bytes (default) | mkfs
 #
-# The file the example serves has to read back as the image, and what is
-# written through the mount has to reach the image.
+# bytes: the file the example serves has to read back as the image, and what
+# is written through the mount has to reach the image.
+# mkfs: mkfs.ext4 on that file has to leave an image e2fsck accepts.
 
 _fuse_no_mount_needed=1
 . "$TEST_LIB/common.sh"
 
+CHECK=${CHECK:-bytes}
+
 # Before the gates: a misspelled FS_NAME would otherwise skip as "not built"
 case ${FS_NAME:-} in
 service_ll | service_hl) ;;
@@ -19,6 +23,10 @@ case ${LAUNCH:-} in
 fuservicemount3 | mount_fuse) ;;
 *) _fail "unknown LAUNCH '${LAUNCH:-}'" ;;
 esac
+case $CHECK in
+bytes | mkfs) ;;
+*) _fail "unknown CHECK '$CHECK'" ;;
+esac
 
 _require_linux "fuservicemount3"
 _require_root
@@ -26,6 +34,10 @@ _require_fuse_device
 _require_binary util/fuservicemount3
 _require_binary "example/$FS_NAME"
 [ "$LAUNCH" != mount_fuse ] || _require_binary util/mount.fuse3
+if [ "$CHECK" = mkfs ]; then
+	_require_prog mkfs.ext4
+	_require_prog e2fsck
+fi
 
 . "$TEST_LIB/service.sh"
 
@@ -35,9 +47,16 @@ old=$TEST_TMP/old
 new=$TEST_TMP/new
 
 # The size has to be a multiple of the page size
-head -c 1048576 /dev/urandom >"$old"
-head -c 1048576 /dev/urandom >"$new"
-cp "$old" "$img"
+case $CHECK in
+bytes)
+	head -c 1048576 /dev/urandom >"$old"
+	head -c 1048576 /dev/urandom >"$new"
+	cp "$old" "$img"
+	;;
+mkfs)
+	truncate -s 64M "$img"
+	;;
+esac
 
 service_start "$TEST_LOGDIR/fs-$FS_NAME.out" "$FUSE_EXAMPLE_DIR/$FS_NAME"
 case $LAUNCH in
@@ -53,10 +72,27 @@ mount_fuse)
 esac
 
 _assert_fstype "$TEST_MNT" "fuse.$service_subtype" fuse
-_assert_file_eq "$TEST_MNT/single_file" "$old"
-dd if="$new" of="$TEST_MNT/single_file" bs=64k conv=notrunc,fsync status=none
+case $CHECK in
+bytes)
+	_assert_file_eq "$TEST_MNT/single_file" "$old"
+	dd if="$new" of="$TEST_MNT/single_file" bs=64k conv=notrunc,fsync \
+		status=none
+	;;
+mkfs)
+	# -F: single_file is a regular file, not a block device
+	mkfs.ext4 -F -q "$TEST_MNT/single_file" ||
+		_fail "mkfs.ext4 through $FS_NAME failed"
+	;;
+esac
 
 umount "$TEST_MNT"
 service_wait_exit
 _assert_eq "$service_rc" 0 "$FS_NAME exit status"
-_assert_file_eq "$img" "$new"
+case $CHECK in
+bytes)
+	_assert_file_eq "$img" "$new"
+	;;
+mkfs)
+	e2fsck -fn "$img" || _fail "e2fsck found errors in $img"
+	;;
+esac
diff --git a/test/cases/mount/service-hl-mkfs.sh b/test/cases/mount/service-hl-mkfs.sh
new file mode 100755
index 000000000000..af552818cd90
--- /dev/null
+++ b/test/cases/mount/service-hl-mkfs.sh
@@ -0,0 +1,8 @@
+#!/usr/bin/env bash
+# GROUP: mount
+
+FS_NAME=service_hl
+LAUNCH=fuservicemount3
+CHECK=mkfs
+
+. "$TEST_LIB/service-example.sh"
diff --git a/test/cases/mount/service-ll-mkfs.sh b/test/cases/mount/service-ll-mkfs.sh
new file mode 100755
index 000000000000..9908937010de
--- /dev/null
+++ b/test/cases/mount/service-ll-mkfs.sh
@@ -0,0 +1,8 @@
+#!/usr/bin/env bash
+# GROUP: mount
+
+FS_NAME=service_ll
+LAUNCH=fuservicemount3
+CHECK=mkfs
+
+. "$TEST_LIB/service-example.sh"

-- 
2.53.0

