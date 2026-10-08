From: Sadman Fahmid <sadmanf@meta.com>
Date: Thu, 08 Oct 2026 11:43:24 -0400
Subject: [PATCH] erofs-utils: lib: fix null memcpy source in xattr listing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-chunking-xattr-infix-v1-v1-1-4a7736c35081@meta.com>
X-B4-Tracking: v=1; b=H4sIABu6x2oC/x2NywrCQAxFf6VkbbBT8Pkr4iIzjdOgpiVTy0Dpv
 xtdHg733BUKm3CBa7OC8SJFRnUIuwbSQJoZpXeGru2OoW3PmIaPPkUzVppnQ9GHVFwCBnJ76ft
 4OBH4ejJ28y/f7s6RCmM00jT8eqNJFt1znfz/zTrTC7btCywIiu6PAAAA
To: linux-erofs@lists.ozlabs.org
Cc: xiang@kernel.org, jefflexu@linux.alibaba.com, 
 Sadman Fahmid <sadmanf@meta.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791474204; l=1493;
 i=sadmanf@meta.com; s=20261006; h=from:subject:message-id;
 bh=Pxsl8oq1y4OPZ92O817gqL4x+XdL3uXSkj2LWJNTIfI=;
 b=vtF/So3GsAVXGSW4c3VQ//9c993L8s+do1m3U+o2ElsmWUBTar6fSQXhYlojQrlH8Z2heBqqv
 FhTUs9KUL80AzKMlN0IULYWgnrI0X/2NIh43g3SAc54o6RUJH3RU7r8
X-Developer-Key: i=sadmanf@meta.com; a=ed25519;
 pk=Pc/arXJpm1RPef8qImFuHROn1p3XNX5MWSUxjZWNTa4=
X-Endpoint-Received: by B4 Relay for sadmanf@meta.com/20261006 with auth_id=1125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Xattr listing passes a `NULL` infix to `memcpy()` when no extended
prefix is present. Skip the copy when `infix_len` is zero.

Fixes: ac3b2b1f5d03 ("erofs-utils: support long xattr name prefixes for erofsfuse")
Signed-off-by: Sadman Fahmid <sadmanf@meta.com>
---
Tested with Clang 21 ASan/UBSan. Build an image from a directory
containing a file with user.test=value, then extract it with
fsck.erofs --xattrs --extract=output image.erofs. UBSan reports a
null memcpy source on the baseline; the patched extraction succeeds
and preserves both the file content and its xattr. Leak detection
was disabled for this test because fsck has a separate existing
xattr ID allocation leak in erofs_init_inode_xattrs().
---
 lib/xattr.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/lib/xattr.c b/lib/xattr.c
index 3cf8c79..d86d94a 100644
--- a/lib/xattr.c
+++ b/lib/xattr.c
@@ -1291,7 +1291,8 @@ static int erofs_listxattr_foreach(struct erofs_xattr_iter *it)
 		return -ERANGE;
 
 	memcpy(it->buffer + it->buffer_ofs, prefix, prefix_len);
-	memcpy(it->buffer + it->buffer_ofs + prefix_len, infix, infix_len);
+	if (infix_len)
+		memcpy(it->buffer + it->buffer_ofs + prefix_len, infix, infix_len);
 	it->buffer_ofs += prefix_len + infix_len;
 
 	/* 2. handle xattr name */

---
base-commit: 50c29ee8d0f88fcec28d492d01eb7ca8715f5961
change-id: 20261008-chunking-xattr-infix-v1-1a0089ddb57a

Best regards,
-- 
Sadman Fahmid <sadmanf@meta.com>

