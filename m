From: Sadman Fahmid <sadmanf@meta.com>
Date: Thu, 08 Oct 2026 11:37:32 -0400
Subject: [PATCH] erofs-utils: tar: fix source path leak
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-chunking-tar-srcpath-v1-v1-1-0d79d76a1593@meta.com>
X-B4-Tracking: v=1; b=H4sIALu4x2oC/x3NQQ6CMBCF4auQWTuxECXGqxgX0zK0E3VopkBIC
 He3uvwW7387FDbhAvdmB+NVikxa0Z4aCIk0MspQDZ3r+ta5G4a06Es04kyGxUKmOeHaohsH7j1
 drm70UNfZeJTtX348qz0VRm+kIf16k0kUPfOW6/+HdaY3HMcX7g2PwY8AAAA=
To: linux-erofs@lists.ozlabs.org
Cc: xiang@kernel.org, jefflexu@linux.alibaba.com, 
 Sadman Fahmid <sadmanf@meta.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791473853; l=1125;
 i=sadmanf@meta.com; s=20261006; h=from:subject:message-id;
 bh=WbKflU4BUacdGyvko5EelvmAxg0hh/Mo+mElmyPInfw=;
 b=cYrFBGBHj7wbAKZvupATfm1OoFa0PO2VSydBO6mOp/yK5oC44JNNJeueq2Kz0qlZaML28AzdK
 Acuu7apVXBSCFNZycMuEW2dMO16sECZApgYQyBsxIkj0M3syPXdfezX
X-Developer-Key: i=sadmanf@meta.com; a=ed25519;
 pk=Pc/arXJpm1RPef8qImFuHROn1p3XNX5MWSUxjZWNTa4=
X-Endpoint-Received: by B4 Relay for sadmanf@meta.com/20261006 with auth_id=1125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Tar import leaks the previous `i_srcpath` allocation when updating
an existing directory or root inode. Free the old string before
assigning the new path.

Fixes: 95d315fd7958 ("erofs-utils: introduce tarerofs")
Signed-off-by: Sadman Fahmid <sadmanf@meta.com>
---
Tested with Clang 21 ASan/UBSan and LeakSanitizer enabled. A tar
containing explicit root and directory headers, a child file, and
repeated root/directory headers leaks 14 bytes on the baseline.
With this patch the import exits successfully without a leak report
and produces an identical EROFS image.
---
 lib/tar.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/lib/tar.c b/lib/tar.c
index f24ad95..c99ce3c 100644
--- a/lib/tar.c
+++ b/lib/tar.c
@@ -1165,6 +1165,7 @@ new_inode:
 			inode->u.i_rdev = erofs_new_encode_dev(st.st_rdev);
 	}
 
+	free(inode->i_srcpath);
 	inode->i_srcpath = strdup(eh.path);
 	if (!inode->i_srcpath) {
 		ret = -ENOMEM;

---
base-commit: 50c29ee8d0f88fcec28d492d01eb7ca8715f5961
change-id: 20261008-chunking-tar-srcpath-v1-0fde6ba450fb

Best regards,
-- 
Sadman Fahmid <sadmanf@meta.com>

