From: Xiubo Li <xiubo.li@clyso.com>
Date: Fri, 17 Jul 2026 17:33:42 +0800
Subject: [PATCH] ceph: revalidate ki_pos for O_APPEND writes after cap
 acquisition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260717-ceph-append-fix-v1-1-c51907ac8e36@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMBCE4VeRPbuQRDDaVykeYpzW9ZCGpJaC+
 O5GPX4D82+UkQSZHtVGCT/J8gkFuq7Izy68wTIVk1GmVVZb9ogzuxgRJn7Jn/vOKDSjdrbzVF4
 xocxX8Tnczuu4wH/PDO37ARDDs0pzAAAA
X-Change-ID: 20260717-ceph-append-fix-9820e3b1a78c
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: Jeff Layton <jlayton@kernel.org>, ceph-devel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784280859; l=3198;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=Yw5DgupygwidMrShTyytzkydWyOnKoHEMS/lC2aH5aE=;
 b=QHcnFItQZPyLEMzc/JfulHuqvJbIDzojQQJGXuOnbbSf9tU6eejTHZbJygY5c/8TlAf1Mmm8/
 Vc632Pprc1LDVnpaVVOBsgVSn0pThk6KIctb0V0J1D61qS6NWu+K/OQ
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For O_APPEND writes, ki_pos is set to the current EOF via
generic_write_checks() after fetching i_size from the MDS.  However,
ceph_get_caps() may need to wait for Fwx exclusive caps if the write
extends the file (endoff > i_max_size).  While waiting for Fwx, the
previous Fwx holder (another client) may have already extended the
file.  When the MDS grants us Fwx, the cap grant message updates the
local i_size, but ki_pos remains at the old EOF, causing the append
write to land at a stale offset and overwrite data from the other
client.

Fix by re-reading i_size_read(inode) after ceph_get_caps() returns.
At this point we hold Fwx exclusive caps, no other client can modify
the file, and i_size reflects the true EOF from the MDS cap grant.
No extra MDS round-trip is needed.  Only adjust ki_pos when the EOF
has actually changed.

Link: https://tracker.ceph.com/issues/7333
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
For O_APPEND writes, ki_pos is set to EOF via generic_write_checks()
after fetching i_size from the MDS via ceph_do_getattr().  However,
ceph_get_caps() may wait for Fwx exclusive caps (because endoff >
i_max_size).  During that wait, the previous Fwx holder may have
already extended the file.  When the MDS grants us Fwx, the local
i_size is updated via the cap grant message, but ki_pos is still
the old EOF, resulting in the append write overwriting data.

Fix by revalidating ki_pos against i_size_read(inode) after
ceph_get_caps() returns.  We now hold Fwx — no other client can
change the file, so i_size is stable and correct.

Fixes: 8e4473bb50a1 ("ceph: do not execute direct write in parallel if O_APPEND is specified")
Link: https://tracker.ceph.com/issues/7333
---
 fs/ceph/file.c | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/fs/ceph/file.c b/fs/ceph/file.c
index 9d89d7fc1095..b35c9aee48dd 100644
--- a/fs/ceph/file.c
+++ b/fs/ceph/file.c
@@ -2491,6 +2491,32 @@ static ssize_t ceph_write_iter(struct kiocb *iocb, struct iov_iter *from)
 	if (err < 0)
 		goto out;
 
+	/*
+	 * For O_APPEND writes we may have waited for Fwx exclusive caps
+	 * while the previous Fwx holder (another client) extended the
+	 * file.  i_size has been updated via the cap grant message from
+	 * the MDS, but ki_pos is still the old EOF.  Re-read i_size here
+	 * (no extra MDS round-trip needed) and adjust ki_pos to the true
+	 * EOF.  Since we hold Fwx, no other client can change the file.
+	 */
+	if (iocb->ki_flags & IOCB_APPEND) {
+		loff_t cur_eof = i_size_read(inode);
+
+		if (cur_eof != pos) {
+			doutc(cl,
+			      "%p %llx.%llx O_APPEND: pos adjusted %lld -> %lld\n",
+			      inode, ceph_vinop(inode), pos, cur_eof);
+			iocb->ki_pos = cur_eof;
+			pos = cur_eof;
+			if (pos >= limit) {
+				err = -EFBIG;
+				goto out_caps;
+			}
+			iov_iter_truncate(from, limit - pos);
+			count = iov_iter_count(from);
+		}
+	}
+
 	err = file_update_time(file);
 	if (err)
 		goto out_caps;

---
base-commit: df47791ab9f12cd9144aca477ddae195f68072a5
change-id: 20260717-ceph-append-fix-9820e3b1a78c

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

