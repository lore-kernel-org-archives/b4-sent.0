From: Xiubo Li <xiubo.li@clyso.com>
Date: Sat, 18 Jul 2026 10:29:48 +0800
Subject: [PATCH v2] ceph: revalidate ki_pos for O_APPEND writes after cap
 acquisition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260718-ceph-append-fix-v2-1-88dcc4f8371f@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQ6CMBBEf4Xs2TVtiRQ8+R+GQ1lWqVHatEgkp
 P9uwbPHN5l5s0LkYDnCuVgh8GyjdWMGdSiABjPeGW2fGZRQldBSI7Ef0HjPY483+8GmVoLLThp
 dE+SVD5zj3Xhtfxzf3YNp2jRbY7BxcmHZL2e59f7bZ4kS6SQboQ3VXFYXei7RHcm9oE0pfQG1O
 etKwAAAAA==
X-Change-ID: 20260717-ceph-append-fix-9820e3b1a78c
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: Jeff Layton <jlayton@kernel.org>, ceph-devel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784341791; l=3519;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=4gyxWWukSVVylN8aTt8ukM2xS92PDXN0uFkXnfmDBdc=;
 b=S7It9ZgfjWgUD8UvMSnDfwa4xlMFLYd7HECVSLi1hgUzfq4B9wX3OdD0y8veivISz/SI1xRA9
 RBYWU5tgEnMB14cIJNwe0EHe6RCzX1KOt2nD8QvqaOSjC3bXVehUHMP
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
Changes in v2:
- Re-check write range against i_max_size after adjusting ki_pos forward, and truncate if it exceeds the MDS-granted limit.(Viacheslav Dubeyko)
- Link to v1: https://patch.msgid.link/20260717-ceph-append-fix-v1-1-c51907ac8e36@clyso.com
---
 fs/ceph/file.c | 42 ++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 42 insertions(+)

diff --git a/fs/ceph/file.c b/fs/ceph/file.c
index 9d89d7fc1095..a2b4d261e23c 100644
--- a/fs/ceph/file.c
+++ b/fs/ceph/file.c
@@ -2491,6 +2491,48 @@ static ssize_t ceph_write_iter(struct kiocb *iocb, struct iov_iter *from)
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
+			if (pos + count > (loff_t)ci->i_max_size) {
+				if (pos >= (loff_t)ci->i_max_size) {
+					err = -EFBIG;
+					goto out_caps;
+				}
+				iov_iter_truncate(from, ci->i_max_size - pos);
+				count = iov_iter_count(from);
+			}
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

