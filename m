From: Daniel Gomez <da.gomez@samsung.com>
Date: Sun, 30 Jun 2024 23:52:44 +0200
Subject: [PATCH v2 5/5] common/rc: print test mount options
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240630-common-fixes-v2-5-16d26fb1dee0@samsung.com>
References: <20240630-common-fixes-v2-0-16d26fb1dee0@samsung.com>
In-Reply-To: <20240630-common-fixes-v2-0-16d26fb1dee0@samsung.com>
To: fstests@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, Zorro Lang <zlang@redhat.com>, 
 mcgrof@kernel.org, gost.dev@samsung.com, 
 Samsung Samsung <"Daniel Gomez d+samsung"@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719784382; l=2734;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=NkZG9YGxsIk1iK1q+OR884fD08LAqJ4Ql3wlQbinl1o=;
 b=1b9VZWGWwZU+PkQz3IMf3M4LrEaiHUkU2GTjkVX2ETo6y6GemZmPgtXTFMuiB5xmatqRu6RlL
 B7nTKREM/JjAVYxKCF2VfmkV/cWFCtdLH3RnDLzJpRaKXycu3Zzjtdi
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Mount options for a SCRATCH device might not be the same for a TEST
device if RECREATE_TEST_DEV is not enabled. Add mount options for TEST
devices when printing fstest header to clarify this.

Add mount and mkfs info for TEST devices so we get the same information
being printed for both devices.

Export new TEST_{MKFS/MOUNT}_OPTIONS and include them in the report.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 check         |  2 ++
 common/rc     | 19 ++++++++++++++++++-
 common/report |  1 +
 3 files changed, 21 insertions(+), 1 deletion(-)

diff --git a/check b/check
index 9222cd7e4..ca30771c5 100755
--- a/check
+++ b/check
@@ -819,6 +819,8 @@ function run_section()
 	# print out our test configuration
 	echo "FSTYP         -- `_full_fstyp_details`"
 	echo "PLATFORM      -- `_full_platform_details`"
+	echo "TEST_MKFS_OPTIONS  -- `_test_mkfs_options`"
+	echo "TEST_MOUNT_OPTIONS -- `_test_mount_options`"
 	if [ ! -z "$SCRATCH_DEV" ]; then
 	  echo "MKFS_OPTIONS  -- `_scratch_mkfs_options`"
 	  echo "MOUNT_OPTIONS -- `_scratch_mount_options`"
diff --git a/common/rc b/common/rc
index 627dbaaaa..bbbd274a7 100644
--- a/common/rc
+++ b/common/rc
@@ -235,6 +235,15 @@ _scratch_mount_options()
 					$SCRATCH_DEV $SCRATCH_MNT $*
 }
 
+_test_mount_options()
+{
+	_test_options mount
+
+	export TEST_MOUNT_OPTIONS="$TEST_OPTIONS $TEST_FS_MOUNT_OPTS \
+				$SELINUX_MOUNT_OPTIONS $* $TEST_DEV $TEST_DIR"
+	echo $TEST_MOUNT_OPTIONS
+}
+
 _supports_filetype()
 {
 	local dir=$1
@@ -457,7 +466,7 @@ _test_mount()
     fi
 
     _test_options mount
-    _mount -t $FSTYP$FUSE_SUBTYP $TEST_OPTIONS $TEST_FS_MOUNT_OPTS $SELINUX_MOUNT_OPTIONS $* $TEST_DEV $TEST_DIR
+    _mount -t $FSTYP$FUSE_SUBTYP `_test_mount_options $*`
     mount_ret=$?
     [ $mount_ret -ne 0 ] && return $mount_ret
     _idmapped_mount $TEST_DEV $TEST_DIR
@@ -571,6 +580,14 @@ _metadump_dev() {
 	esac
 }
 
+_test_mkfs_options()
+{
+	_test_options mkfs
+
+	export TEST_MKFS_OPTIONS="$TEST_OPTIONS $MKFS_OPTIONS $* $TEST_DEV"
+	echo $TEST_MKFS_OPTIONS
+}
+
 _test_mkfs()
 {
     case $FSTYP in
diff --git a/common/report b/common/report
index 0e91e481f..44de33e61 100644
--- a/common/report
+++ b/common/report
@@ -5,6 +5,7 @@
 # List of xfstests's enviroment variables to include reports
 ## TODO automate list population inside common/conf
 REPORT_ENV_LIST=("SECTION" "FSTYP" "PLATFORM" "MKFS_OPTIONS" "MOUNT_OPTIONS" \
+		 "TEST_MKFS_OPTIONS" "TEST_MOUNT_OPTIONS" \
 		 "HOST_OPTIONS" "CHECK_OPTIONS" "XFS_MKFS_OPTIONS" \
 		 "TIME_FACTOR" "LOAD_FACTOR" "TEST_DIR" "TEST_DEV" \
 		 "SCRATCH_DEV" "SCRATCH_MNT" "OVL_UPPER" "OVL_LOWER" "OVL_WORK")

-- 
2.43.0

