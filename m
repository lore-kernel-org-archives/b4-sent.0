From: Alon Shakevsky <shakevsky@berkeley.edu>
Date: Tue, 01 Sep 2026 00:05:31 +0000
Subject: [PATCH] ksmbd: validate COPYCHUNK source and target ranges
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260901-review-ksmbd-copychunk-offsets-v2-v1-1-4a7f598eb9c9@berkeley.edu>
X-B4-Tracking: v=1; b=H4sIAMoWlmoC/yXNywqDMBCF4VeRWXcgCSVoX6V0UZNJnUoTyXipi
 O9ubJcfHP6zgVBmErhVG2SaWTjFAn2pwHXP+CJkXwxGGasapfEc0YK9fFqPLg2r66bYYwpBaBS
 cDSprbK29b641QekMmQJ/fx/3x98ytW9y4xmGfT8Ad8NK+4UAAAA=
X-Change-ID: 20260901-review-ksmbd-copychunk-offsets-v2-062681dd948e
To: Namjae Jeon <linkinjeon@kernel.org>
Cc: Sergey Senozhatsky <senozhatsky@chromium.org>, 
 ChenXiaoSong <chenxiaosong@chenxiaosong.com>, linux-kernel@vger.kernel.org, 
 linux-cifs@vger.kernel.org, Tom Talpey <tom@talpey.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788221130; l=2533;
 i=shakevsky@berkeley.edu; s=20260829; h=from:subject:message-id;
 bh=zk9ntSxK6KH2GBnQw9ciD278sqGKtMWF34uLWFj0peY=;
 b=yQA1yMpddtk2egLqVHUYN9brG83RmkSNGDeABt7kbCc/rFdF0Pl7zbbN/CwWszVWRlgfpuyxQ
 8MYJPOjQWenDntrG3a+c5HxEROmx4fRFLOTRfeJRyEh5MpcRpDeqM8w
X-Developer-Key: i=shakevsky@berkeley.edu; a=ed25519;
 pk=yWZAM5+fHWudgjDI2F4zjbrSoHRSkvQ4pqpdyFWJUis=
X-Endpoint-Received: by B4 Relay for shakevsky@berkeley.edu/20260829 with auth_id=987
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ksmbd_vfs_copy_file_ranges() rejects negative source offsets in the
copy loop, but it does not validate target offsets. It also calculates
lock and overlap endpoints before ensuring that either range fits within
MAX_LFS_FILESIZE.

When the target is an alternate data stream, the buffered path passes a
negative target offset to ksmbd_vfs_stream_write(). Let n be Length and
let -d be TargetOffset, where 0 < d < n <= XATTR_SIZE_MAX. For an empty
stream, the writer allocates n - d bytes, then copies n bytes starting d
bytes before the allocation. An authenticated SMB client can control d
and the source data, overwrite kernel heap memory, and crash the host.

Validate both ranges before lock, overlap, or I/O calculations.

Fixes: 8482150a0743 ("ksmbd: support copychunk for alternate data streams")
Assisted-by: Antiproof:GPT-5.6-Sol
Signed-off-by: Alon Shakevsky <shakevsky@berkeley.edu>
---
 fs/smb/server/vfs.c | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/fs/smb/server/vfs.c b/fs/smb/server/vfs.c
index 35123550a5535..3a6f3139c6f52 100644
--- a/fs/smb/server/vfs.c
+++ b/fs/smb/server/vfs.c
@@ -2009,6 +2009,11 @@ static ssize_t ksmbd_vfs_copy_file_range_buffered(struct ksmbd_work *work,
 	return ret;
 }
 
+static bool ksmbd_vfs_copy_range_valid(loff_t offset, size_t len)
+{
+	return offset >= 0 && (loff_t)len <= MAX_LFS_FILESIZE - offset;
+}
+
 int ksmbd_vfs_copy_file_ranges(struct ksmbd_work *work,
 			       struct ksmbd_file *src_fp,
 			       struct ksmbd_file *dst_fp,
@@ -2044,6 +2049,10 @@ int ksmbd_vfs_copy_file_ranges(struct ksmbd_work *work,
 			dst_off = le64_to_cpu(chunks[i].TargetOffset);
 			len = le32_to_cpu(chunks[i].Length);
 
+			if (!ksmbd_vfs_copy_range_valid(src_off, len) ||
+			    !ksmbd_vfs_copy_range_valid(dst_off, len))
+				return -E2BIG;
+
 			if (check_lock_range(src_fp->filp, src_off,
 					     src_off + len - 1, READ))
 				return -EAGAIN;
@@ -2136,7 +2145,8 @@ int ksmbd_vfs_copy_file_ranges(struct ksmbd_work *work,
 		len = le32_to_cpu(chunks[i].Length);
 		copy_len = len;
 
-		if (src_off < 0)
+		if (!ksmbd_vfs_copy_range_valid(src_off, len) ||
+		    !ksmbd_vfs_copy_range_valid(dst_off, len))
 			return -E2BIG;
 
 		if (src_off > src_file_size || len > src_file_size - src_off) {

---
base-commit: e53a23f960a10bf85ed2c9dbe0c1fc7d09c077ae
change-id: 20260901-review-ksmbd-copychunk-offsets-v2-062681dd948e

Best regards,
--  
Alon Shakevsky <shakevsky@berkeley.edu>

