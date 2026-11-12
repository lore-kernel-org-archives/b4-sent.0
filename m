From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 12 Nov 2026 10:37:17 +0900
Subject: [PATCH 1/2] xfs/438: retry failed metadata writes again
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-xfs-438-dquot-retry-v1-1-73149b823246@samsung.com>
References: <20261112-xfs-438-dquot-retry-v1-0-73149b823246@samsung.com>
In-Reply-To: <20261112-xfs-438-dquot-retry-v1-0-73149b823246@samsung.com>
To: Zorro Lang <zlang@kernel.org>, fstests@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 Brian Foster <bfoster@redhat.com>, Dave Chinner <dgc@kernel.org>, 
 linux-xfs@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794447436; l=2680;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=OBUGkimxrIsMu9LAjPKmqMotfyRv2/Jb4lKdfqxdUxA=;
 b=O7yMa1AHBoHyfBwnXp0F9FgRVKpxALdUSNQ7MUI3cqrBT+0WTFAecWuYEvaJzeith1G4Y92tt
 thBhwpnJVhzAEzGlUcx775GxhTgOfh8DR+eLYstW94fiuPjngonTaRJ
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs/438 checks that a dquot buffer write that keeps failing does not
hang the unmount (kernel commit 373b0589dc8d). Commit eb2ad950ea90
moved the test to _scratch_mount. Since commit 1a49022fab9b,
_scratch_mount sets the metadata EIO retries to 0. XFS then shuts
down on the second failure, before the AIL can retry the write. The
test passes even with the bug.

Turn the retries back on after the mount. Fail the test if XFS has
shut down before the unmount.

Fixes: eb2ad950ea90 ("dmflakey: override SCRATCH_DEV in _init_flakey")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested on kernels with and without XFS_DEBUG. Patch 1 gives the same
results on both. With an internal log, v7.4-rc2 passes 3 of 3. A TEST
ONLY kernel that skips the resubmission of failed AIL items hangs at
unmount (1 of 1). Without patch 2, the new check fails in three cases:

- with the dm patch and a write cache (3 of 3)
- with an external log (1 of 1)
- with an rt device that has a write cache (from the code, not run)

In each, XFS shuts down on a log error before the unmount. Patch 2
passes in the first two cases.
---
 tests/xfs/438 | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/tests/xfs/438 b/tests/xfs/438
index 4cd0b26..e4850ff 100755
--- a/tests/xfs/438
+++ b/tests/xfs/438
@@ -95,6 +95,9 @@ _require_flakey_with_error_writes
 _require_user
 _require_xfs_quota
 _require_freeze
+_require_test_sysfs_dev_attr error/fail_at_unmount
+_require_test_sysfs_dev_attr error/metadata/EIO/max_retries
+_require_test_sysfs_dev_attr error/metadata/EIO/retry_timeout_seconds
 
 echo "Silence is golden"
 
@@ -117,6 +120,12 @@ sysctl -w fs.xfs.xfssyncd_centisecs=100 >> $seqres.full 2>&1
 _qmount_option "usrquota"
 _scratch_mount
 
+# _scratch_mount turns off the retries of failed metadata writes.
+# Go back to the kernel defaults, so that the failed dquot buffer
+# write is retried from the AIL until unmount. fail_at_unmount
+# stays on, so the unmount ends the retries on a fixed kernel.
+_reset_xfs_sysfs_error_handling $SCRATCH_DEV >> $seqres.full
+
 # We need to set the quota limitation twice, and inject the write error
 # after the second setting. If we try to inject the write error after
 # the first setting, the initialization of the dquota buffer will get
@@ -145,6 +154,10 @@ _scratch_sync
 # the completion of the retried write of dquota buffer
 sleep 2
 
+# The dquot buffer write must still be failing and retried here. A shut
+# down filesystem means that the test missed the hang it checks.
+stat $SCRATCH_MNT > /dev/null
+
 _scratch_unmount
 
 _cleanup_flakey

-- 
2.43.0

