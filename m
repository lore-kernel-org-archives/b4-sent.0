From: Daejun Park <daejun7.park@samsung.com>
Date: Fri, 30 Oct 2026 16:40:35 +0900
Subject: [PATCH] pnfs/blocklayout: don't let a READ layout hide written
 extents
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-nfs-bl-ro-v1-1-2a0957b016c3@samsung.com>
X-B4-Tracking: v=1; b=H4sIAPJJ5GoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA2MD3by0Yt2kHN2ifN3klKQ0MwOLNJM0gxQloPqCotS0zAqwWdGxtbU
 A07nqblsAAAA=
To: Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <ben.coddington@hammerspace.com>, 
 linux-nfs@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793346034; l=2743;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=Vg6etV6xipx1KtXlbZppd+PVJsnrjMUfS5rmlQPPAX8=;
 b=EsAhAGkMBbHjOtISsOnoWbk0zcXYFxK7Vsmd/tiA5mZ+N7kq4EtAjMqlyA9Dm34X3e+fUHM97
 m5lpCG3qc27C4QS1mrcx99fb6EcvrICvzbYFbrPr+/yEaO2MFK1JaVh
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Once a client writes to an INVALID_DATA extent, reads must use it
(RFC 5663, section 2.3.4). A READ layout fetched before LAYOUTCOMMIT
can map the range as NONE_DATA. Lookups check read-only extents first.
The client then reads zeroes until the layout is returned.

Do not add read-only extents over written or READ_WRITE_DATA extents.

Fixes: 8067253c8cc5 ("pnfs/blocklayout: rewrite extent tracking")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Against next-20261006. extent_tree.c is the same in next-20261029
and in mainline 65ba8f34ec88.

Tested against Linux nfsd on XFS: an O_DIRECT write into a range with
no data, then a read across it, returned zeroes in 12 of 12 runs before
and the written data after. generic/013, 091 and 263 pass.
---
 fs/nfs/blocklayout/extent_tree.c | 27 ++++++++++++++++++++++++++-
 1 file changed, 26 insertions(+), 1 deletion(-)

diff --git a/fs/nfs/blocklayout/extent_tree.c b/fs/nfs/blocklayout/extent_tree.c
index 7393118c42..40a6ab6329 100644
--- a/fs/nfs/blocklayout/extent_tree.c
+++ b/fs/nfs/blocklayout/extent_tree.c
@@ -252,6 +252,28 @@ __ext_tree_remove(struct rb_root *root,
 	return 0;
 }
 
+/*
+ * Return the first extent at or after @start that a new read-only
+ * extent must not cover: an ro extent, or an rw extent before @end
+ * that reads use. An INVALID_DATA extent not yet written to does
+ * not count: reads of it use the ro extent below it (copy-on-write).
+ */
+static struct pnfs_block_extent *
+ext_tree_search_ro(struct pnfs_block_layout *bl, sector_t start, sector_t end)
+{
+	struct pnfs_block_extent *be = __ext_tree_search(&bl->bl_ext_ro, start);
+	struct pnfs_block_extent *rw;
+
+	if (be && be->be_f_offset < end)
+		end = be->be_f_offset;
+	for (rw = __ext_tree_search(&bl->bl_ext_rw, start);
+	     rw && rw->be_f_offset < end; rw = ext_tree_next(rw)) {
+		if (rw->be_state != PNFS_BLOCK_INVALID_DATA || rw->be_tag)
+			return rw;
+	}
+	return be;
+}
+
 int
 ext_tree_insert(struct pnfs_block_layout *bl, struct pnfs_block_extent *new)
 {
@@ -275,7 +297,10 @@ ext_tree_insert(struct pnfs_block_layout *bl, struct pnfs_block_extent *new)
 
 	spin_lock(&bl->bl_ext_lock);
 retry:
-	be = __ext_tree_search(root, new->be_f_offset);
+	if (root == &bl->bl_ext_ro)
+		be = ext_tree_search_ro(bl, new->be_f_offset, ext_f_end(new));
+	else
+		be = __ext_tree_search(root, new->be_f_offset);
 	if (!be || be->be_f_offset >= ext_f_end(new)) {
 		__ext_tree_insert(root, new, true);
 	} else if (new->be_f_offset >= be->be_f_offset) {

---
base-commit: eea3fef32a9cf36abcb5975a5a594e4135a6b026
change-id: 20261030-nfs-bl-ro-cdbf608f4f0d

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

