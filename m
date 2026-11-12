From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 12 Nov 2026 10:37:18 +0900
Subject: [PATCH 2/2] xfs/438: fail metadata writes with the buf_ioerror
 error tag
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-xfs-438-dquot-retry-v1-2-73149b823246@samsung.com>
References: <20261112-xfs-438-dquot-retry-v1-0-73149b823246@samsung.com>
In-Reply-To: <20261112-xfs-438-dquot-retry-v1-0-73149b823246@samsung.com>
To: Zorro Lang <zlang@kernel.org>, fstests@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 Brian Foster <bfoster@redhat.com>, Dave Chinner <dgc@kernel.org>, 
 linux-xfs@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794447436; l=5124;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=uxhvdiV7rEpIfQfXZG8qo3IqaiTTume2rGdCDhiHHLQ=;
 b=3dTDa/quXyfGp9o1QrxebipImw93Jf5AUadk4lsGPoISbTArITjRzCsBtxiT7Bh3oEeluVGLR
 xqVXGUicocPCDE9W83Qxyy4Qlkusxlt4fiBjRe8xm6vSzAvASJaVUKJ
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs/438 needs metadata writes to fail while the log keeps working.
With a write cache, dm-flakey also fails the flushes that dm sends it
with REQ_PREFLUSH log writes. The internal log survives only because
dm drops that error. The dm patch "dm: fail a REQ_PREFLUSH bio with
data when its preflush fails" fixes that. With an external log, the
flakey table fails the log device too.

Use the buf_ioerror error tag. It fails async metadata buffer writes
and leaves log writes alone. The test now needs XFS_DEBUG.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
On v7.4-rc2 and on v7.4-rc2 with the dm patch, the test passes with
an internal log (3 of 3) and an external log (1 of 1). The failed
dquot write is retried until the unmount. On the TEST ONLY kernel of
patch 1 the unmount hangs with both logs (1 of 1 each).
---
 tests/xfs/438 | 76 ++++++-----------------------------------------------------
 1 file changed, 7 insertions(+), 69 deletions(-)

diff --git a/tests/xfs/438 b/tests/xfs/438
index e4850ff..5c228e4 100755
--- a/tests/xfs/438
+++ b/tests/xfs/438
@@ -14,9 +14,9 @@
 # get the same IO error, XFS will let xfsaild to restart the write and
 # xfs_buf_do_callbacks() will not be inovked.
 #
-# This test emulates the write error by using dm-flakey. The log
-# area of the XFS filesystem is excluded from the range covered by
-# dm-flakey, so the XFS will not be shutdown prematurely.
+# This test emulates the write error with the buf_ioerror error tag,
+# which fails async metadata buffer writes. Log writes are not buffer
+# writes, so the XFS will not be shutdown prematurely.
 #
 # Fixed by upstream commit 373b058 ("xfs: Properly retry failed dquot
 # items in case of error during buffer writeback")
@@ -33,85 +33,27 @@ _cleanup()
 	cd /
 	rm -f $tmp.*
 	_scratch_unmount >/dev/null 2>&1
-	_cleanup_flakey > /dev/null 2>&1
-}
-
-# inject IO write error for the XFS filesystem except its log section
-make_xfs_scratch_flakey_table()
-{
-	local tgt=flakey
-	local opt="0 1 1 error_writes"
-	local dev=${SCRATCH_DEV}
-	local dev_sz=$(blockdev --getsz $dev)
-
-	# If using an external log device, just making the writing of
-	# entire data/metadata area fail forever.
-	if [ "${USE_EXTERNAL}" = "yes" -a ! -z "$SCRATCH_LOGDEV" ]; then
-		echo "0 ${dev_sz} $tgt $dev 0 $opt"
-		return
-	fi
-
-	local blk_sz=$(_scratch_xfs_get_sb_field blocksize)
-	local log_ofs=$(_scratch_xfs_get_sb_field logstart)
-	local log_sz=$(_scratch_xfs_get_sb_field logblocks)
-	local table=""
-	local ofs=0
-	local sz
-
-	log_ofs=$(_scratch_xfs_db -r -c "convert fsb ${log_ofs} bb" | \
-			  $AWK_PROG '{gsub("[()]", "", $2); print $2}')
-	let "log_sz *= blk_sz / 512"
-
-	# Add a flakey target for the area before the log section
-	# to make the data/metadata write fail forever
-	if [ "$ofs" -lt "${log_ofs}" ]; then
-		let "sz = log_ofs - ofs"
-		table="$ofs $sz $tgt $dev $ofs $opt"
-	fi
-
-	# Add a linear target for the log section, so the log write
-	# will work normally
-	table="$table\n${log_ofs} ${log_sz} linear $dev ${log_ofs}"
-
-	# Add a flakey target for the area after the log section
-	# to make the data/metadata write fail forever
-	let "ofs = log_ofs + log_sz"
-	if [ "$ofs" -lt "${dev_sz}" ]; then
-		let "sz = dev_sz - ofs"
-		table="$table\n$ofs $sz $tgt $dev $ofs $opt"
-	fi
-
-	echo -e $table
 }
 
 # Import common functions.
-. ./common/dmflakey
 . ./common/quota
+. ./common/inject
 
 
 # due to the injection of write IO error, the fs will be inconsistent
 _require_scratch_nocheck
-_require_flakey_with_error_writes
 _require_user
 _require_xfs_quota
 _require_freeze
 _require_test_sysfs_dev_attr error/fail_at_unmount
 _require_test_sysfs_dev_attr error/metadata/EIO/max_retries
 _require_test_sysfs_dev_attr error/metadata/EIO/retry_timeout_seconds
+_require_xfs_io_error_injection buf_ioerror
 
 echo "Silence is golden"
 
 _scratch_mkfs > $seqres.full 2>&1
 
-# this needs to happen after mkfs, but before _init_flakey overrides SCRATCH_DEV
-FLAKEY_TABLE_NON_LOG_ERROR=$(make_xfs_scratch_flakey_table)
-
-# no error will be injected
-_init_flakey
-FLAKEY_TABLE_ERROR=${FLAKEY_TABLE_NON_LOG_ERROR}
-$DMSETUP_PROG info >> $seqres.full
-$DMSETUP_PROG table >> $seqres.full
-
 # save the old value for _cleanup()
 interval=$(sysctl -n fs.xfs.xfssyncd_centisecs 2>/dev/null)
 # shorten the time waiting for the push of ail items
@@ -139,10 +81,8 @@ $XFS_QUOTA_PROG -x -c "report -ih" $SCRATCH_MNT >> $seqres.full
 xfs_freeze -f $SCRATCH_MNT
 xfs_freeze -u $SCRATCH_MNT
 
-# inject write IO error
-_load_flakey_table ${FLAKEY_ERROR_WRITES}
-$DMSETUP_PROG info >> $seqres.full
-$DMSETUP_PROG table >> $seqres.full
+# fail every async metadata buffer write from now on
+_scratch_inject_error buf_ioerror 1
 
 # update the dquota buffer
 $XFS_QUOTA_PROG -x -c "limit -u isoft=400 $qa_user" $SCRATCH_MNT
@@ -160,8 +100,6 @@ stat $SCRATCH_MNT > /dev/null
 
 _scratch_unmount
 
-_cleanup_flakey
-
 # success, all done
 status=0
 exit

-- 
2.43.0

