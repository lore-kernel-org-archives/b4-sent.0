From: Xiubo Li <xiubo.li@clyso.com>
Date: Tue, 21 Jul 2026 13:06:53 +0800
Subject: [PATCH v3] ceph: revalidate ki_pos for O_APPEND writes after cap
 acquisition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260721-ceph-append-fix-v3-1-403d1b5204d3@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ7CIBBFr9KwFgNUC3XlPYwLOp1ajBYCldg0v
 btQN02Myzf5781MAnqDgZyKmXiMJhg7JCh3BYFeDzekpk1MBBMVk1xSQNdT7RwOLe3Mm9ZKMCw
 brqUCkiznMZ3X4uX65fBq7ghjzuRFb8Jo/bS+jDzv/tcjp5zCkddMalBYVmd4TMHuwT5Jrkex9
 dWvL5KvVAtw6FQpebf1l2X5ANo3Bv0AAQAA
X-Change-ID: 20260717-ceph-append-fix-9820e3b1a78c
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: Jeff Layton <jlayton@kernel.org>, ceph-devel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784610426; l=3946;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=qkIjobO/mwWY4xsUADl5gozVcTVXv6RN/HBnNhNTqRo=;
 b=uqA7/lI2k+N5/dVR+VextbMjcfz7khcaqA3Tw9Pzjp7+jiO376EoDTvU7m1VifUF39tkw7UU7
 6gIQiEXv/VsCBFv49tTvbb58a1EcvO7Tv6rUuAiHrl4DxXuxfUZ7e+N
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

After adjusting ki_pos forward, the write range [pos, pos+count) may
now exceed the i_max_size that was validated by ceph_get_caps() for
the old range.  Re-check against i_max_size and truncate the write
if necessary to stay within the MDS-granted limit.

Fixes: 8e4473bb50a1 ("ceph: do not execute direct write in parallel if O_APPEND is specified")
Link: https://tracker.ceph.com/issues/7333
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
Changes in v3:
- Protect ci->i_max_size access with i_ceph_lock to avoid data race with handle_cap_grant() which updates i_max_size from the messenger thread.(Viacheslav Dubeyko)
- Link to v2: https://patch.msgid.link/20260718-ceph-append-fix-v2-1-88dcc4f8371f@clyso.com

Changes in v2:
- Re-check write range against i_max_size after adjusting ki_pos forward, and truncate if it exceeds the MDS-granted limit.(Viacheslav Dubeyko)
- Link to v1: https://patch.msgid.link/20260717-ceph-append-fix-v1-1-c51907ac8e36@clyso.com
---
 fs/ceph/file.c | 48 ++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 48 insertions(+)

diff --git a/fs/ceph/file.c b/fs/ceph/file.c
index 3823671ab95a..c26bd4fef7d3 100644
--- a/fs/ceph/file.c
+++ b/fs/ceph/file.c
@@ -2489,6 +2489,54 @@ static ssize_t ceph_write_iter(struct kiocb *iocb, struct iov_iter *from)
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
+
+			/*
+			 * ceph_get_caps() validated the old endoff
+			 * against i_max_size; adjusting ki_pos forward
+			 * may have shifted the write range beyond the
+			 * granted max_size.  Re-check and truncate if
+			 * necessary.
+			 */
+			spin_lock(&ci->i_ceph_lock);
+			if (pos + count > (loff_t)ci->i_max_size) {
+				loff_t max_size = ci->i_max_size;
+
+				spin_unlock(&ci->i_ceph_lock);
+				if (pos >= max_size) {
+					err = -EFBIG;
+					goto out_caps;
+				}
+				iov_iter_truncate(from, max_size - pos);
+				count = iov_iter_count(from);
+			} else {
+				spin_unlock(&ci->i_ceph_lock);
+			}
+		}
+	}
+
 	err = file_update_time(file);
 	if (err)
 		goto out_caps;

---
base-commit: afffcd98d2d22f2e7ebe42f71231d52d4eed8ef7
change-id: 20260717-ceph-append-fix-9820e3b1a78c

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

