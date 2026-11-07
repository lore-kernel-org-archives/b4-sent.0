From: Xiubo Li <xiubo.li@clyso.com>
Date: Sat, 07 Nov 2026 03:52:27 +0100
Subject: [PATCH] ceph: flush the caps ceph_write_inode() queues from the
 delayed work
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-ceph-write-inode-flush-v1-1-6d414faf9ccd@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywqDMBCF4VeRWXfABIylr1K6qJNJMyJRMt5Af
 HfTdvlxOP8ByllY4VEdkHkVlTEVmFsFFN/pwyi+GGxtnTF1i8RTxC3LXJY0esYwLBrRk2vdvaH
 QWAPlPGUOsv/Cz9ffunQ90/ytwXleIq3U5noAAAA=
X-Change-ID: 20261107-ceph-write-inode-flush-dc67685cf521
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794019955; l=3761;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=eXGBJFcag2PmzZJslBHNOIJ2VYBfjzGWaTeJs83E7T8=;
 b=hmVP6bqC0CKaiq78vyVAC+LMrYfML6EcvTnpAfoOq8Ktsl0OVa6Ntgh6z/k1Ztlaa6esA5U+f
 DGnmqP/1QJ2DifG/Sqn0+4u4s+xohJNNkLCa3gdEePMu0oX4+WCYqr4
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_write_inode() without WB_SYNC_ALL does not flush the dirty caps:
it sets CEPH_I_FLUSH and moves the inode to the front of the delayed
cap list, so that the caps go out once, after the data writeback.  But
ceph_check_caps() turns CEPH_I_FLUSH into CHECK_CAPS_FLUSH for every
caller, and a buffered write calls it whenever it puts its last Fw
reference.  So the next write after a writeback pass flushes the caps
at once.

A file under steady writeback, with the dirty page limit reached, gets
a writeback pass for nearly every write, and every write dirties Fw
again (mtime).  The client then sends a cap flush per few writes, and
the MDS journals each one.

Honour CEPH_I_FLUSH only in the delayed cap work, which the inode was
queued for.  Other callers still flush dirty caps when they send a cap
message for another reason, and fsync() and sync writeback flush them
as before.

16 writers on 4 lazyio mounts, each writing 47008-byte records
interleaved with the others' into one shared file (IOR, -t 47008
-b 47008), with the dirty page limit reached, mean of 2 runs each:

+--------------------------+-------+---------+---------+---------+
| metric                   | unit  |    base |   patch | speedup |
+--------------------------+-------+---------+---------+---------+
| write bandwidth          | GiB/s |   0.711 |   0.713 |   1.00x |
| cap messages, the file   |       |   78360 |     368 |         |
| MDS journal events       |       |   93470 |     600 |         |
| MDS journal latency, avg | ms    |    4197 |     556 |         |
+--------------------------+-------+---------+---------+---------+

write() latency in ms, 2 runs each pooled:

+-------+-----+-----+-----+-------+--------+----------+------+
|       | p50 | p90 | p95 | p99   | p99.9  | p99.99   | max  |
+-------+-----+-----+-----+-------+--------+----------+------+
| base  | 0.2 | 0.2 | 0.2 | 16-33 | 66-131 | 524-1049 | 8854 |
| patch | 0.2 | 0.2 | 0.3 | 16-33 | 66-131 | 66-131   | 2965 |
+-------+-----+-----+-----+-------+--------+----------+------+

The gain is in the cap and journal traffic, not in bandwidth: any file
that is written while it is under writeback sends far fewer cap
flushes to the MDS.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c | 14 +++++++++++---
 1 file changed, 11 insertions(+), 3 deletions(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index aca09351a094..d95eb2f42f42 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -2211,8 +2211,6 @@ void ceph_check_caps(struct ceph_inode_info *ci, int flags)
 		return;
 	}
 
-	if (ci->i_ceph_flags & CEPH_I_FLUSH)
-		flags |= CHECK_CAPS_FLUSH;
 	/*
 	 * A revoke whose response was deferred (see handle_cap_grant()) must
 	 * still be acknowledged.  Replay the forced flush here so that even a
@@ -5056,10 +5054,20 @@ static unsigned long check_delayed_caps_list(struct ceph_mds_client *mdsc,
 
 		inode = igrab(&ci->netfs.inode);
 		if (inode) {
+			/*
+			 * Flush the dirty caps that ceph_write_inode()
+			 * queued here.  Only this work does it: other cap
+			 * checks leave them for it, so that a file under
+			 * writeback does not flush them after every write.
+			 */
+			int flags = test_bit(CEPH_I_FLUSH_BIT,
+					     &ci->i_ceph_flags) ?
+				    CHECK_CAPS_FLUSH : 0;
+
 			spin_unlock(&mdsc->cap_delay_lock);
 			doutc(cl, "on %p %llx.%llx\n", inode,
 			      ceph_vinop(inode));
-			ceph_check_caps(ci, 0);
+			ceph_check_caps(ci, flags);
 			iput(inode);
 			spin_lock(&mdsc->cap_delay_lock);
 		}

---
base-commit: 5dcec86cc31f8144857c0d9bf2a7fa13b6e6f531
change-id: 20261107-ceph-write-inode-flush-dc67685cf521

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

