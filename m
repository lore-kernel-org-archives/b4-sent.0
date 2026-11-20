From: Xiubo Li <xiubo.li@clyso.com>
Date: Fri, 20 Nov 2026 07:40:16 +0200
Subject: [PATCH] ceph: reject MDS dentry names longer than NAME_MAX
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-ceph-readdir-name-max-v1-1-ba7c434d4733@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBG4auUWTvQRAjWq4iLMfljR2gsEyuF0
 rsbdfkt3tuowhSVzt1GhrdWfZYGd+gojlLuYE3N5HsfnPM9R8wjGyQlNS4ygSdZ+RiGlN1pkBx
 ArZ0NWdff93L9uy63B+LrO6N9/wAqBeooeQAAAA==
X-Change-ID: 20261120-ceph-readdir-name-max-369df189af6e
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, 
 Milind Changire <mchangir@redhat.com>
Cc: security@kernel.org, Quinn Grant <leograntquinn@gmail.com>, 
 stable@vger.kernel.org, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795153216; l=4641;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=Mzi7+uGkMFdydRBmnsttKFo2kIPdjv5fz54lFeRyGSY=;
 b=bMnklu8ERyzSFdk0K+mTz8VYp5u9j1okB4ToSLdy0lys0y7jkYOXYYUiNgwxb+CkYRqaE2Puq
 aOaYIHhDYc0AnDTT4/aJc8nSVQRVhWOAzNZI7e8ui28ROEhZLHNDjIO
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MDS reply parsers bound a dentry name only by the remaining
payload, never by NAME_MAX.  With CONFIG_FS_ENCRYPTION=y that is
caught later, because ceph_fname_to_usr() refuses any name longer
than NAME_MAX, encrypted directory or not.  With
CONFIG_FS_ENCRYPTION=n, ceph_fname_to_usr() is a stub that passes the
name through, so a buggy or malicious MDS can hand the client an
overlong name, and two fixed size buffers then overflow:

 - ceph_readdir() keeps the last entry of a chunk in
   dfi->last_name, and the next READDIR request copies it into a
   NAME_MAX + 1 byte r_path2 buffer without a length check.

 - a dentry created from such a name (readdir prepopulate, or the
   LOOKUPNAME trace) is later sent back in a lease message whose
   front is sized for NAME_MAX bytes of name.

Reject a dentry name longer than NAME_MAX in both
parse_reply_info_readdir() and parse_reply_info_trace(), so an =n
build fails the reply with -EIO the same way an =y build already
does.  Also check the length at the two copy sites, so a long name
that gets there by any other way is refused instead of written past
the buffer.

Fixes: 8f2a98ef3c1a ("ceph: ensure d_name/d_parent stability in ceph_mdsc_lease_send_msg()")
Fixes: af9ffa6df7e3 ("ceph: add support to readdir for encrypted names")
Cc: stable@vger.kernel.org
Reported-by: Quinn Grant <leograntquinn@gmail.com>
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
This is sent privately first, as a follow-up to Quinn's report to
security@kernel.org.  Please let me know if you see a need for
coordinated disclosure.  Otherwise I plan to post it to ceph-devel and
linux-kernel (with Cc: stable) in a few days.

On CONFIG_FS_ENCRYPTION=n builds a buggy or malicious MDS can send a
dentry name longer than NAME_MAX.  It then overflows the NAME_MAX + 1
byte readdir continuation buffer and the lease message front.  This
patch rejects such names when the MDS reply is parsed, and also checks
the length at both copy sites.

Tested on a KASAN kernel with CONFIG_FS_ENCRYPTION=n:
 - without the patch: FORTIFY reports a 512-byte memcpy into a 256-byte
   buffer in ceph_readdir(); KASAN reports a 512-byte write in
   ceph_mdsc_lease_send_msg(); a 256-byte name already makes
   ceph_encode_filepath() read out of bounds
 - with the patch: readdir returns -EIO and no dentry is created; a
   255-byte name works as before (listing, readdir continuation,
   lookup, lease renewal); readdir of a 3000-entry directory with
   several chunk sizes and fsstress show no regression
---
 fs/ceph/dir.c        |  5 +++++
 fs/ceph/mds_client.c | 12 ++++++++++++
 2 files changed, 17 insertions(+)

diff --git a/fs/ceph/dir.c b/fs/ceph/dir.c
index c7e91f53e4b6..eae177dd5bcf 100644
--- a/fs/ceph/dir.c
+++ b/fs/ceph/dir.c
@@ -460,6 +460,11 @@ static int ceph_readdir(struct file *file, struct dir_context *ctx)
 		if (dfi->last_name) {
 			int len = strlen(dfi->last_name);
 
+			if (WARN_ON_ONCE(len > NAME_MAX)) {
+				ceph_mdsc_put_request(req);
+				ceph_blog_exit(&__ji);
+				return -EIO;
+			}
 			req->r_path2 = kzalloc(NAME_MAX + 1, GFP_KERNEL);
 			if (!req->r_path2) {
 				ceph_mdsc_put_request(req);
diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index 15df9d22008d..3c1ba94fc621 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -450,6 +450,8 @@ static int parse_reply_info_trace(void **p, void *end,
 			goto out_bad;
 
 		ceph_decode_32_safe(p, end, info->dname_len, bad);
+		if (info->dname_len > NAME_MAX)
+			goto bad;
 		ceph_decode_need(p, end, info->dname_len, bad);
 		info->dname = *p;
 		*p += info->dname_len;
@@ -526,6 +528,11 @@ static int parse_reply_info_readdir(void **p, void *end,
 
 		/* dentry */
 		ceph_decode_32_safe(p, end, _name_len, bad);
+		if (_name_len > NAME_MAX) {
+			pr_err_client(cl, "dir entry name too long (%u)\n",
+				      _name_len);
+			goto bad;
+		}
 		ceph_decode_need(p, end, _name_len, bad);
 		_name = *p;
 		*p += _name_len;
@@ -6332,6 +6339,11 @@ void ceph_mdsc_lease_send_msg(struct ceph_mds_session *session,
 	lease->seq = cpu_to_le32(seq);
 
 	spin_lock(&dentry->d_lock);
+	if (WARN_ON_ONCE(dentry->d_name.len > NAME_MAX)) {
+		spin_unlock(&dentry->d_lock);
+		ceph_msg_put(msg);
+		return;
+	}
 	dir = d_inode(dentry->d_parent);
 	lease->ino = cpu_to_le64(ceph_ino(dir));
 	lease->first = lease->last = cpu_to_le64(ceph_snap(dir));

---
base-commit: 6a9830a8f414d3830c584782568d0233be969d09
change-id: 20261120-ceph-readdir-name-max-369df189af6e

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

