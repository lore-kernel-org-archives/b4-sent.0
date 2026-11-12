From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 12 Nov 2026 12:58:15 +0900
Subject: [PATCH] overlay: test d_ino of hard links in an impure dir
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-ovl013-hlink-v1-1-4bf8f44050e9@samsung.com>
X-B4-Tracking: v=1; b=H4sIAFY59WoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0Mj3fyyHANDY92MnMy8bF3z5DRzk0Rzc9MUI2MloJaCotS0zAqwcdG
 xtbUAmgg6GV4AAAA=
To: fstests@vger.kernel.org
Cc: Zorro Lang <zlang@kernel.org>, Amir Goldstein <amir73il@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>, linux-unionfs@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794455894; l=3144;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=plEjgCid8fULCglbzGD9W9G0YpAuKpPG535Rx0K4cHg=;
 b=BNtS5aXvEsUM7uuXY9t2ozHIW284VzT+V96eupm58pb/Xld0SobXUpDoOExFLiP5k6uCqw6A3
 jT4lelpus3/B0oV9drObKKupqWxN2Oms6zXJTaEfPDrp63VeadfyZRi
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Linking a file with copy up origin into a non-merge impure dir does
not bump the dir version. readdir then reuses the impure dir cache
built before the link. The new link is not in that cache. readdir
reports its upper inode number as d_ino instead of st_ino.

The test builds the cache, then links two files with origin into the
dir: one from the dir itself and one from the overlay root. It checks
that readdir finds each new link by its st_ino.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
On the overlayfs ovl-fixes branch (0d5e729c515f) with default overlay
mount options, the test fails in 3 of 3 runs on ext4 and on xfs. With
the kernel patch "ovl: bump the impure dir version when linking a file
with origin", it passes in 3 of 3 runs on each.
---
 tests/overlay/013     | 58 +++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/overlay/013.out |  2 ++
 2 files changed, 60 insertions(+)

diff --git a/tests/overlay/013 b/tests/overlay/013
new file mode 100755
index 00000000..bc65076c
--- /dev/null
+++ b/tests/overlay/013
@@ -0,0 +1,58 @@
+#! /bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Copyright (c) 2026 Samsung Electronics. All Rights Reserved.
+#
+# FS QA Test 013
+#
+# Test consistent d_ino of hard links in an impure dir.
+#
+# Overlayfs caches the d_ino of the entries with a copy up origin in a
+# non-merge impure dir. Linking a file with copy up origin into the dir
+# must invalidate that cache, so that readdir reports the new link with
+# the same inode number as stat.
+#
+. ./common/preamble
+_begin_fstest auto quick copyup hardlink
+
+_fixed_by_kernel_commit xxxxxxxxxxxx \
+	"ovl: bump the impure dir version when linking a file with origin"
+
+_require_scratch
+_require_test_program "t_dir_type"
+
+_scratch_mkfs >>$seqres.full 2>&1
+
+lowerdir=$OVL_BASE_SCRATCH_MNT/$OVL_LOWER
+mkdir -p $lowerdir
+touch $lowerdir/foo $lowerdir/bar
+
+_scratch_mount
+
+impure_dir=$SCRATCH_MNT/impure_dir
+mkdir $impure_dir
+
+# Expect readdir of $impure_dir to find <name> by the st_ino of <name>
+check_d_ino()
+{
+	local name=$1
+	local ino=$(stat -c '%i' $impure_dir/$name)
+
+	$here/src/t_dir_type $impure_dir $ino | grep -q "^$name f$" || \
+		echo "readdir d_ino of $name does not match st_ino $ino"
+}
+
+# Copy up foo and link it into the pure upper dir, which makes the dir
+# impure. Then read the dir, so its impure entries get cached.
+ln $SCRATCH_MNT/foo $impure_dir/foo
+check_d_ino foo
+
+# Link foo again inside the dir
+ln $impure_dir/foo $impure_dir/foo_link
+check_d_ino foo_link
+
+# Copy up bar and link it into the dir
+ln $SCRATCH_MNT/bar $impure_dir/bar
+check_d_ino bar
+
+echo "Silence is golden"
+_exit 0
diff --git a/tests/overlay/013.out b/tests/overlay/013.out
new file mode 100644
index 00000000..3e66423b
--- /dev/null
+++ b/tests/overlay/013.out
@@ -0,0 +1,2 @@
+QA output created by 013
+Silence is golden

---
base-commit: 71641219a506ac62bfa231592394265ca812670e
change-id: 20261112-ovl013-hlink-7cf74a775d23

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

